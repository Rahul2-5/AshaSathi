import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:frontend/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'connectivity_service.dart';
import 'patient_offline_dao.dart';


class PatientSyncService {
  final PatientOfflineDao _dao = PatientOfflineDao();
  final ConnectivityService _connectivity = ConnectivityService();
  static const String _lastSyncMillisKey = 'patient_last_sync_millis';
  static final ValueNotifier<int> syncRevision = ValueNotifier<int>(0);

  static String get baseUrl => AppConfig.apiBaseUrl;
  bool _syncing = false;

  Future<bool> sync(String token) async {
    if (_syncing) return false;
    _syncing = true;

    try {
      debugPrint("[PatientSync] checking connectivity...");
      if (!await _connectivity.isOnline()) {
        debugPrint("[PatientSync] offline - skipping");
        return false;
      }

      debugPrint("[PatientSync] starting sync");

      final serverIndex = await _fetchServerPatientsIndex(token);

      // 🔹 CREATE / UPDATE
      final pending = await _dao.getPending();
      debugPrint("[PatientSync] pending patients: ${pending.length}");
      var allPendingSynced = true;

      for (final patient in pending) {
        if (patient.localId == null) {
          allPendingSynced = false;
          continue;
        }

        final matchedServerId =
            serverIndex.byUuid[patient.uuid] ??
            serverIndex.byFingerprint[_fingerprintFromValues(
              name: patient.name,
              phoneNumber: patient.phoneNumber,
              dateOfBirth: patient.dateOfBirth,
              gender: patient.gender,
              age: patient.age,
            )] ??
            serverIndex.byPhoneDob[_phoneDobKey(
              phoneNumber: patient.phoneNumber,
              dateOfBirth: patient.dateOfBirth,
            )] ??
            serverIndex.byPhone[_normalizePhone(patient.phoneNumber)];
        if (matchedServerId != null) {
          await _dao.markSynced(
            localId: patient.localId!,
            serverId: matchedServerId,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
          debugPrint(
            '[PatientSync] reconciled local ${patient.localId} by UUID -> serverId=$matchedServerId',
          );
          continue;
        }

        // 1) Create patient on server (without photo)
        final createRes = await http.post(
          Uri.parse("$baseUrl/api/patients"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "patientName": patient.name,
            "gender": patient.gender,
            "age": patient.age,
            "dateOfBirth": patient.dateOfBirth,
            "address": patient.address,
            "description": patient.description,
            "phoneNumber": patient.phoneNumber,
            "clientTempId": patient.uuid,
          }),
        );

        debugPrint('[PatientSync] create patient POST ${createRes.statusCode}');
        if (createRes.statusCode != 200 && createRes.statusCode != 201) {
          final recoveredServerId = await _findServerIdForLocalPatient(token, patient);
          if (recoveredServerId != null) {
            await _dao.markSynced(
              localId: patient.localId!,
              serverId: recoveredServerId,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            );
            debugPrint(
              '[PatientSync] recovered local ${patient.localId} after create failure -> serverId=$recoveredServerId',
            );
            continue;
          }
          debugPrint('[PatientSync] failed to create patient ${patient.localId}: ${createRes.statusCode} ${createRes.body}');
          allPendingSynced = false;
          continue;
        }

        final body = jsonDecode(createRes.body);
        final serverId = _parseServerId(body['id']);
        if (serverId == null) {
          final recoveredServerId = await _findServerIdForLocalPatient(token, patient);
          if (recoveredServerId != null) {
            await _dao.markSynced(
              localId: patient.localId!,
              serverId: recoveredServerId,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            );
            debugPrint(
              '[PatientSync] recovered local ${patient.localId} after missing id -> serverId=$recoveredServerId',
            );
            continue;
          }
          debugPrint('[PatientSync] missing server id in create response for local ${patient.localId}');
          allPendingSynced = false;
          continue;
        }
        debugPrint('[PatientSync] created patient serverId=$serverId');

        // 2) If there's a local photo file, upload it to the server endpoint that accepts patientId
        final localPhotoPath = patient.photoPath;
        if (localPhotoPath != null &&
            localPhotoPath.trim().isNotEmpty &&
            File(localPhotoPath).existsSync()) {
          try {
            final req = http.MultipartRequest(
              "POST",
              Uri.parse("$baseUrl/api/patients/$serverId/photo"),
            );
            req.headers["Authorization"] = "Bearer $token";
            req.files.add(await http.MultipartFile.fromPath("photo", localPhotoPath));

            final streamed = await req.send();
            final respBody = await streamed.stream.bytesToString();
            debugPrint('[PatientSync] upload photo status=${streamed.statusCode} body=$respBody');
            // backend updates patient.photoPath in DB
          } catch (e) {
            debugPrint('[PatientSync] photo upload failed for local ${patient.localId}: $e');
          }
        }

        // 3) Mark local record as synced with serverId
        await _dao.markSynced(
          localId: patient.localId!,
          serverId: serverId,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        debugPrint('[PatientSync] marked local ${patient.localId} as synced -> serverId=$serverId');
      }

      // 🔹 DELETE SYNC
      await _syncDeleted(token);

      if (allPendingSynced) {
        await _saveLastSyncMillis(DateTime.now().millisecondsSinceEpoch);
        syncRevision.value = syncRevision.value + 1;
      }

      return allPendingSynced;
    } finally {
      _syncing = false;
      debugPrint("[PatientSync] finished sync");
    }
  }

  int? _parseServerId(dynamic idRaw) {
    if (idRaw is int) return idRaw;
    if (idRaw == null) return null;
    return int.tryParse('$idRaw');
  }

  Future<int?> _findServerIdForLocalPatient(
    String token,
    dynamic patient,
  ) async {
    final index = await _fetchServerPatientsIndex(token);
    final byUuid = index.byUuid[patient.uuid];
    if (byUuid != null) return byUuid;

    final byFingerprint = index.byFingerprint[_fingerprintFromValues(
      name: patient.name,
      phoneNumber: patient.phoneNumber,
      dateOfBirth: patient.dateOfBirth,
      gender: patient.gender,
      age: patient.age,
    )];
    return byFingerprint;
  }

  Future<_ServerPatientIndex> _fetchServerPatientsIndex(String token) async {
    final byUuid = <String, int>{};
    final byFingerprint = <String, int>{};
    final byPhone = <String, int>{};
    final byPhoneDob = <String, int>{};

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/patients'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        return _ServerPatientIndex(
          byUuid: byUuid,
          byFingerprint: byFingerprint,
          byPhone: byPhone,
          byPhoneDob: byPhoneDob,
        );
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! List) {
        return _ServerPatientIndex(
          byUuid: byUuid,
          byFingerprint: byFingerprint,
          byPhone: byPhone,
          byPhoneDob: byPhoneDob,
        );
      }

      for (final row in decoded) {
        if (row is! Map<String, dynamic>) continue;

        final dynamic idRaw = row['id'];
        final dynamic uuidRaw = row['uuid'] ?? row['clientTempId'];
        if (idRaw == null) continue;

        final parsedId = idRaw is int ? idRaw : int.tryParse('$idRaw');
        if (parsedId == null) continue;

        final parsedUuid = uuidRaw == null ? '' : '$uuidRaw'.trim();
        if (parsedUuid.isNotEmpty) {
          byUuid[parsedUuid] = parsedId;
        }

        final fingerprint = _fingerprintFromValues(
          name: '${row['patientName'] ?? row['name'] ?? ''}',
          phoneNumber: '${row['phoneNumber'] ?? ''}',
          dateOfBirth: '${row['dateOfBirth'] ?? ''}',
          gender: '${row['gender'] ?? ''}',
          age: (row['age'] is int)
              ? row['age'] as int
              : int.tryParse('${row['age'] ?? ''}'),
        );
        if (fingerprint.isNotEmpty) {
          byFingerprint[fingerprint] = parsedId;
        }

        final normalizedPhone = _normalizePhone('${row['phoneNumber'] ?? ''}');
        if (normalizedPhone.isNotEmpty) {
          byPhone[normalizedPhone] = parsedId;

          final phoneDobKey = _phoneDobKey(
            phoneNumber: normalizedPhone,
            dateOfBirth: '${row['dateOfBirth'] ?? ''}',
            alreadyNormalizedPhone: true,
          );
          if (phoneDobKey.isNotEmpty) {
            byPhoneDob[phoneDobKey] = parsedId;
          }
        }
      }
    } catch (_) {
      // Best effort reconciliation only.
    }

    return _ServerPatientIndex(
      byUuid: byUuid,
      byFingerprint: byFingerprint,
      byPhone: byPhone,
      byPhoneDob: byPhoneDob,
    );
  }

  String _fingerprintFromValues({
    required String name,
    required String phoneNumber,
    required String dateOfBirth,
    required String gender,
    required int? age,
  }) {
    final normalizedName = name.trim().toLowerCase();
    final normalizedPhone = _normalizePhone(phoneNumber);
    final normalizedDob = _normalizeDob(dateOfBirth);
    final normalizedGender = gender.trim().toLowerCase();
    final agePart = age?.toString() ?? '';

    if (normalizedName.isEmpty ||
        normalizedPhone.isEmpty ||
        normalizedDob.isEmpty ||
        normalizedGender.isEmpty ||
        agePart.isEmpty) {
      return '';
    }

    return '$normalizedName|$normalizedPhone|$normalizedDob|$normalizedGender|$agePart';
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  String _normalizeDob(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length >= 10) {
      return trimmed.substring(0, 10);
    }
    return trimmed;
  }

  String _phoneDobKey({
    required String phoneNumber,
    required String dateOfBirth,
    bool alreadyNormalizedPhone = false,
  }) {
    final normalizedPhone =
        alreadyNormalizedPhone ? phoneNumber : _normalizePhone(phoneNumber);
    final normalizedDob = _normalizeDob(dateOfBirth);
    if (normalizedPhone.isEmpty || normalizedDob.isEmpty) return '';
    return '$normalizedPhone|$normalizedDob';
  }

  static Future<int?> getLastSyncMillis() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastSyncMillisKey);
  }

  Future<void> _saveLastSyncMillis(int millis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncMillisKey, millis);
  }

  Future<void> _syncDeleted(String token) async {
    final deleted = await _dao.getDeleted();

    for (final patient in deleted) {
      if (patient.serverId == null) continue;

      try {
        final res = await http.delete(
          Uri.parse("$baseUrl/api/patients/${patient.serverId}"),
          headers: {"Authorization": "Bearer $token"},
        );

        if (res.statusCode == 200 || res.statusCode == 204) {
          // keep local deleted state (or hard delete later)
        }
      } catch (_) {
        // retry next sync
      }
    }
  }
}

class _ServerPatientIndex {
  const _ServerPatientIndex({
    required this.byUuid,
    required this.byFingerprint,
    required this.byPhone,
    required this.byPhoneDob,
  });

  final Map<String, int> byUuid;
  final Map<String, int> byFingerprint;
  final Map<String, int> byPhone;
  final Map<String, int> byPhoneDob;
}
