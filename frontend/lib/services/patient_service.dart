import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../patient/family_model.dart';
import '../patient/patient_model.dart';
import '../offline/connectivity_service.dart';
import '../offline/family_cache_service.dart';
import '../offline/patient_offline_dao.dart';
import '../offline/patient_offline_entity.dart';

class PatientService {
  static String get baseUrl => AppConfig.patientsBaseUrl;

  final ConnectivityService _connectivity = ConnectivityService();
  final PatientOfflineDao _offlineDao = PatientOfflineDao();
  final FamilyCacheService _familyCache = FamilyCacheService();

  Future<List<Patient>> getPatients(String token) async {
    final isOnline = await _connectivity.isOnline();

    // ===============================
    //  1. LOAD OFFLINE PATIENTS (non-deleted only)
    // ===============================
    final offlinePatients = await _offlineDao.getAll();
    debugPrint("Loaded ${offlinePatients.length} offline patients");
    final offlineModels = offlinePatients.map((p) {
      return Patient(
        id: p.serverId,
        uuid: p.uuid, // ✅ CRITICAL FIX: must use actual UUID
        name: p.name,
        gender: p.gender,
        age: p.age,
        dateOfBirth: p.dateOfBirth,
        address: p.address,
        description: p.description,
        phoneNumber: p.phoneNumber,
        photoPath: p.photoPath,
        caste: p.caste,
        isPregnant: p.isPregnant,
        monthsOfPregnancy: p.monthsOfPregnancy,
        expectedDeliveryDate: p.expectedDeliveryDate,
        declinedHealthInfo: p.declinedHealthInfo,
        diseases: p.diseases,
      );
    }).toList();

    // ===============================
    // 🔴 2. OFFLINE → RETURN LOCAL
    // ===============================
    if (!isOnline) {
      debugPrint("Offline mode: returning ${offlineModels.length} locally synced patients");
      return offlineModels;
    }

    // ===============================
    // 🟢 3. ONLINE → FETCH BACKEND
    // ===============================
    try {
      final res = await http.get(
        Uri.parse(baseUrl),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode != 200) {
        debugPrint("Backend fetch failed (${res.statusCode}), returning offline patients");
        return offlineModels;
      }

      final List data = jsonDecode(res.body);
      final parsedOnline = data.map((e) => Patient.fromJson(e)).toList();
      final onlineModels = <Patient>[];

      for (final patient in parsedOnline) {
        final cachedPhotoPath = await _cachePatientPhotoIfNeeded(
          patient: patient,
          token: token,
        );

        onlineModels.add(
          Patient(
            id: patient.id,
            uuid: patient.uuid,
            name: patient.name,
            gender: patient.gender,
            age: patient.age,
            dateOfBirth: patient.dateOfBirth,
            address: patient.address,
            description: patient.description,
            phoneNumber: patient.phoneNumber,
            photoPath: cachedPhotoPath,
            caste: patient.caste,
            isPregnant: patient.isPregnant,
            monthsOfPregnancy: patient.monthsOfPregnancy,
            expectedDeliveryDate: patient.expectedDeliveryDate,
            declinedHealthInfo: patient.declinedHealthInfo,
            diseases: patient.diseases,
          ),
        );
      }
      debugPrint("Loaded ${onlineModels.length} patients from backend");

      for (final patient in onlineModels) {
        await _offlineDao.upsertSynced(
          PatientOfflineEntity(
            serverId: patient.id,
            uuid: patient.uuid,
            name: patient.name,
            gender: patient.gender,
            age: patient.age,
            dateOfBirth: patient.dateOfBirth,
            address: patient.address,
            description: patient.description,
            phoneNumber: patient.phoneNumber,
            photoPath: patient.photoPath,
            caste: patient.caste,
            isPregnant: patient.isPregnant,
            monthsOfPregnancy: patient.monthsOfPregnancy,
            expectedDeliveryDate: patient.expectedDeliveryDate,
            declinedHealthInfo: patient.declinedHealthInfo,
            diseases: patient.diseases,
          ),
        );
      }

      final unsyncedLocal =
          offlineModels.where((patient) => patient.id == null).toList();
      if (unsyncedLocal.isEmpty) {
        return onlineModels;
      }

      final onlineKeys = onlineModels.map(_patientKey).toSet();
      final merged = <Patient>[...onlineModels];

      for (final localPatient in unsyncedLocal) {
        final key = _patientKey(localPatient);
        if (!onlineKeys.contains(key)) {
          merged.insert(0, localPatient);
        }
      }

      debugPrint(
        "Merged ${unsyncedLocal.length} unsynced local patients with backend list",
      );

      // ===============================
      // ✅ 4. RETURN BACKEND + UNSYNCED LOCAL
      // ===============================
      return merged;
    } catch (e) {
      debugPrint("Error fetching from backend: $e");
      return offlineModels;
    }
  }

  String _patientKey(Patient patient) {
    final uuid = patient.uuid.trim();
    if (uuid.isNotEmpty) {
      return "uuid:$uuid";
    }
    return "id:${patient.id ?? -1}";
  }

  Future<String?> _cachePatientPhotoIfNeeded({
    required Patient patient,
    required String token,
  }) async {
    final rawPath = patient.photoPath?.trim();
    if (rawPath == null || rawPath.isEmpty) {
      return rawPath;
    }

    final normalized = rawPath.replaceAll('\\', '/');
    final isWindowsAbsolutePath = RegExp(r'^[A-Za-z]:[/\\]').hasMatch(rawPath);

    if ((rawPath.startsWith('/') || isWindowsAbsolutePath) &&
        !normalized.startsWith('/uploads/')) {
      return rawPath;
    }

    final remoteUrl = _resolveRemotePhotoUrl(rawPath);
    if (remoteUrl == null) {
      return rawPath;
    }

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(p.join(docsDir.path, 'patient_photo_cache'));
      if (!cacheDir.existsSync()) {
        cacheDir.createSync(recursive: true);
      }

      final uri = Uri.parse(remoteUrl);
      String extension = p.extension(uri.path);
      if (extension.isEmpty) {
        extension = '.jpg';
      }

      final safeId = (patient.uuid.trim().isNotEmpty
              ? patient.uuid.trim()
              : (patient.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString()))
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      final localPath = p.join(cacheDir.path, 'patient_$safeId$extension');
      final localFile = File(localPath);

      if (!localFile.existsSync()) {
        final photoRes = await http.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (photoRes.statusCode == 200) {
          await localFile.writeAsBytes(photoRes.bodyBytes, flush: true);
        } else {
          debugPrint(
            'Patient photo cache skipped for ${patient.uuid}: HTTP ${photoRes.statusCode}',
          );
          return rawPath;
        }
      }

      return localPath;
    } catch (e) {
      debugPrint('Patient photo cache failed for ${patient.uuid}: $e');
      return rawPath;
    }
  }

  String? _resolveRemotePhotoUrl(String rawPath) {
    final normalized = rawPath.replaceAll('\\', '/');

    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }

    if (normalized.startsWith('/uploads/') || normalized.contains('/uploads/')) {
      return '${AppConfig.apiBaseUrl}$normalized';
    }

    if (normalized.startsWith('/')) {
      return '${AppConfig.apiBaseUrl}$normalized';
    }

    return '${AppConfig.apiBaseUrl}/$normalized';
  }

  /// ============================================
  /// FAMILY REGISTRATION
  /// ============================================
  Future<bool> submitFamilyRegistration(
    Map<String, dynamic> payload,
    String token,
  ) async {
    try {
      debugPrint('Submitting family registration: ${payload.toString()}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/families'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Family registration request timed out');
        },
      );

      debugPrint('Family registration response: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('Family registered successfully');
        
        // Response cached, ready to use
        return true;
      } else {
        debugPrint('Family registration failed: ${response.body}');
        return false;
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout during family registration: ${e.message}');
      return false;
    } catch (e, stackTrace) {
      debugPrint('Error during family registration: $e\n$stackTrace');
      return false;
    }
  }

  Future<List<FamilyRecord>> getFamilies(String token) async {
    final isOnline = await _connectivity.isOnline();

    if (!isOnline) {
      final cachedFamilies = await _familyCache.loadFamilies();
      if (cachedFamilies.isNotEmpty) {
        debugPrint('Offline mode: returning ${cachedFamilies.length} cached families');
        return cachedFamilies;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/families'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final cachedFamilies = await _familyCache.loadFamilies();
        if (cachedFamilies.isNotEmpty) {
          debugPrint(
            'Backend fetch failed (${response.statusCode}), returning cached families',
          );
          return cachedFamilies;
        }
        throw Exception('Failed to load families: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return <FamilyRecord>[];
      }

      final families = decoded
          .whereType<Map<String, dynamic>>()
          .map(FamilyRecord.fromJson)
          .toList();

      await _familyCache.saveFamilies(families);
      return families;
    } catch (e, stackTrace) {
      debugPrint('Error fetching families: $e\n$stackTrace');
      final cachedFamilies = await _familyCache.loadFamilies();
      if (cachedFamilies.isNotEmpty) {
        debugPrint('Returning cached families after fetch error');
        return cachedFamilies;
      }
      rethrow;
    }
  }

  Future<bool> deleteFamily({
    required int familyId,
    required String token,
  }) async {
    try {
      final isOnline = await _connectivity.isOnline();
      if (!isOnline) {
        await _familyCache.removeFamilyById(familyId);
        debugPrint('Offline family delete applied to cache for familyId=$familyId');
        return true;
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}/api/families/$familyId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final success = response.statusCode == 200 || response.statusCode == 204;
      if (success) {
        await _familyCache.removeFamilyById(familyId);
      }
      return success;
    } catch (e, stackTrace) {
      debugPrint('Error deleting family: $e\n$stackTrace');
      return false;
    }
  }

  // Delete patient by ID from backend
  Future<Map<String, dynamic>> deletePatient({
    required int patientId,
    required String token,
  }) async {
    try {
      final url = '${baseUrl.replaceAll('/patients', '').withoutTrailingSlash()}/patients/$patientId';
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204 || response.statusCode == 201) {
        return {'success': true, 'message': 'Patient deleted successfully'};
      } else {
        return {'success': false, 'message': 'Failed to delete patient: ${response.statusCode}'};
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting patient: $e\n$stackTrace');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}

// Extension to handle trailing slashes
extension on String {
  String withoutTrailingSlash() {
    if (endsWith('/')) {
      return substring(0, length - 1);
    }
    return this;
  }
}
