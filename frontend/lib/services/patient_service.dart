import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../patient/family_model.dart';
import '../patient/patient_model.dart';
import '../offline/connectivity_service.dart';
import '../offline/family_cache_service.dart';
import '../offline/family_offline_service.dart';
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
    //  1. LOAD ONLY UNSYNCED OFFLINE PATIENTS (pending, not synced)
    // ===============================
    final pendingPatients = await _offlineDao.getPending();
    debugPrint("Loaded ${pendingPatients.length} pending offline patients");
    final pendingModels = pendingPatients.map((p) {
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
        updatedAt: p.updatedAt, // ✅ Include timestamp for sorting recent patients
      );
    }).toList();

    // ===============================
    // 🔴 2. OFFLINE → RETURN PENDING LOCAL
    // ===============================
    if (!isOnline) {
      debugPrint("Offline mode: returning ${pendingModels.length} pending unsynced patients");
      return pendingModels;
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
        debugPrint("Backend fetch failed (${res.statusCode}), returning pending patients");
        return pendingModels;
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
            updatedAt: patient.updatedAt,
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

      // ===============================
      // ✅ 4. MERGE: Backend patients + any remaining unsynced local
      // ===============================
      final merged = <Patient>[...onlineModels];
      final onlineUuids = onlineModels.map((p) => p.uuid).toSet();

      // Add pending local patients that aren't already in the backend list
      for (final localPatient in pendingModels) {
        if (!onlineUuids.contains(localPatient.uuid)) {
          merged.insert(0, localPatient);
        }
      }

      debugPrint(
        "Merged: ${onlineModels.length} backend + ${pendingModels.where((p) => !onlineUuids.contains(p.uuid)).length} pending unsynced local patients",
      );

      return merged;
    } catch (e) {
      debugPrint("Error fetching from backend: $e");
      return pendingModels;
    }
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
      
      // 🔴 OFFLINE-FIRST: Save to local storage using FamilyOfflineService
      try {
        final familyInfo = payload['familyInfo'] as Map<String, dynamic>?;
        final patients = payload['patients'] as List<dynamic>?;
        
        if (familyInfo != null && patients != null) {
          // Convert to proper format for FamilyOfflineService
          final patientsMap = List<Map<String, dynamic>>.from(
            patients.whereType<Map<String, dynamic>>()
          );
          
          await FamilyOfflineService().saveFamilyOffline(
            familyInfo: familyInfo,
            patients: patientsMap,
          );
          debugPrint('✅ Family saved to offline storage via FamilyOfflineService');
        }
      } catch (e) {
        debugPrint('⚠️ Warning: Could not save family offline: $e');
        // Continue anyway - will try online submission
      }

      // 🟢 ONLINE: Try to submit to backend
      final isOnline = await _connectivity.isOnline();
      if (!isOnline) {
        debugPrint('🔴 Offline: Family saved locally, will sync when online');
        return true; // Offline save succeeded
      }

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
        debugPrint('✅ Family registered successfully online');
        // Clear offline records since it's now synced
        try {
          await FamilyOfflineService().clearPending();
        } catch (_) {
          // Ignore errors in cleanup
        }
        return true;
      } else {
        debugPrint('⚠️ Family registration online failed: ${response.body}');
        // Keep in offline storage for retry
        return true; // Already saved offline
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout during family registration: ${e.message}');
      // Keep in offline storage for retry
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error during family registration: $e\n$stackTrace');
      // Keep in offline storage for retry
      return true;
    }
  }

  Future<List<FamilyRecord>> getFamilies(String token) async {
    final isOnline = await _connectivity.isOnline();

    // 🔴 STEP 1: Load pending offline families (always available)
    List<FamilyRecord> pendingOfflineFamilies = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('pending_family_registrations_v1');
      if (json != null) {
        final decoded = jsonDecode(json) as List<dynamic>;
        pendingOfflineFamilies = decoded.asMap().entries.map((entry) {
          final idx = entry.key;
          final data = entry.value as Map<String, dynamic>;
          final familyInfo = data['familyInfo'] as Map<String, dynamic>;
          final patientsList = (data['patients'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>()
              .map((p) => FamilyMemberRecord(
                id: null,
                patientName: p['patientName'] ?? '',
                age: p['age'] ?? 0,
                dateOfBirth: p['dateOfBirth'] ?? '',
                gender: p['gender'] ?? 'Female',
                caste: p['caste'] ?? '',
                address: p['address'] ?? '',
                phoneNumber: p['phoneNumber'] ?? '',
                isPregnant: p['isPregnant'] ?? false,
                monthsOfPregnancy: p['monthsOfPregnancy'],
                expectedDeliveryDate: p['expectedDeliveryDate'] ?? '',
                photoPath: p['photoPath'],
                diseases: {},
                declinedHealthInfo: p['declinedHealthInfo'] ?? false,
                notes: p['notes'] ?? '',
              ))
              .toList();

          // Use negative ID to indicate pending offline family
          return FamilyRecord(
            id: -(idx + 1), // Negative ID marks as pending
            headOfFamily: familyInfo['headOfFamily'] ?? '',
            numberOfMembers: familyInfo['numberOfMembers'] ?? 0,
            familyAddress: familyInfo['familyAddress'] ?? '',
            patients: patientsList,
          );
        }).toList();
        debugPrint(
          '[FamilyService] Loaded ${pendingOfflineFamilies.length} pending offline families',
        );
      }
    } catch (e) {
      debugPrint('[FamilyService] Error loading pending offline families: $e');
    }

    // 🟡 STEP 2: Offline → RETURN PENDING ONLY
    if (!isOnline) {
      debugPrint(
        'Offline mode: returning ${pendingOfflineFamilies.length} pending unsynced families',
      );
      return pendingOfflineFamilies;
    }

    // 🟢 STEP 3: ONLINE → Try to load from backend
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
        final combined = [...pendingOfflineFamilies, ...cachedFamilies];
        if (combined.isNotEmpty) {
          debugPrint(
            'Backend fetch failed (${response.statusCode}), returning ${combined.length} families',
          );
          return combined;
        }
        throw Exception('Failed to load families: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return pendingOfflineFamilies; // At least return pending offline
      }

      final backendFamilies = decoded
          .whereType<Map<String, dynamic>>()
          .map(FamilyRecord.fromJson)
          .toList();

      await _familyCache.saveFamilies(backendFamilies);
      
      // 🔗 MERGE: Backend families + any remaining pending that haven't synced
      final merged = <FamilyRecord>[...backendFamilies];
      
      // Create set of backend family identifiers (head name + address)
      final backendFamilyKeys = backendFamilies
          .map((f) => '${f.headOfFamily}::${f.familyAddress}')
          .toSet();

      // Add pending families that aren't already in backend
      for (final pendingFamily in pendingOfflineFamilies) {
        final key = '${pendingFamily.headOfFamily}::${pendingFamily.familyAddress}';
        if (!backendFamilyKeys.contains(key)) {
          merged.insert(0, pendingFamily);
        }
      }

      debugPrint(
        '[FamilyService] Returning ${merged.length} merged families (${backendFamilies.length} backend + ${pendingOfflineFamilies.where((p) => !backendFamilyKeys.contains('${p.headOfFamily}::${p.familyAddress}')).length} pending)',
      );
      
      // Clear pending since they've been synced
      if (pendingOfflineFamilies.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pending_family_registrations_v1');
          debugPrint('[FamilyService] Cleared pending families after sync');
        } catch (_) {}
      }
      
      return merged;
    } catch (e, stackTrace) {
      debugPrint('Error fetching families: $e\n$stackTrace');
      final cachedFamilies = await _familyCache.loadFamilies();
      final combined = [...pendingOfflineFamilies, ...cachedFamilies];
      if (combined.isNotEmpty) {
        debugPrint(
          '[FamilyService] Returning ${combined.length} families after error',
        );
        return combined;
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
