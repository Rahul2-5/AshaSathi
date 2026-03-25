import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:frontend/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'connectivity_service.dart';
import 'patient_offline_dao.dart';
import 'patient_offline_entity.dart';

class PatientSyncStatusSnapshot {
  const PatientSyncStatusSnapshot({
    required this.isSyncing,
    required this.pendingCount,
    required this.deletedCount,
    required this.conflictCount,
    required this.retryQueueCount,
    this.lastError,
    this.lastAttemptAtMillis,
  });

  final bool isSyncing;
  final int pendingCount;
  final int deletedCount;
  final int conflictCount;
  final int retryQueueCount;
  final String? lastError;
  final int? lastAttemptAtMillis;

  int get totalQueueCount => pendingCount + deletedCount;

  PatientSyncStatusSnapshot copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? deletedCount,
    int? conflictCount,
    int? retryQueueCount,
    String? lastError,
    int? lastAttemptAtMillis,
    bool clearError = false,
  }) {
    return PatientSyncStatusSnapshot(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      deletedCount: deletedCount ?? this.deletedCount,
      conflictCount: conflictCount ?? this.conflictCount,
      retryQueueCount: retryQueueCount ?? this.retryQueueCount,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastAttemptAtMillis: lastAttemptAtMillis ?? this.lastAttemptAtMillis,
    );
  }

  static const empty = PatientSyncStatusSnapshot(
    isSyncing: false,
    pendingCount: 0,
    deletedCount: 0,
    conflictCount: 0,
    retryQueueCount: 0,
  );
}


class PatientSyncService {
  final PatientOfflineDao _dao = PatientOfflineDao();
  final ConnectivityService _connectivity = ConnectivityService();
  static const String _lastSyncMillisKey = 'patient_last_sync_millis';
  static final ValueNotifier<int> syncRevision = ValueNotifier<int>(0);
  static final ValueNotifier<PatientSyncStatusSnapshot> syncStatus =
      ValueNotifier<PatientSyncStatusSnapshot>(PatientSyncStatusSnapshot.empty);

  static String get baseUrl => AppConfig.apiBaseUrl;
  bool _syncing = false;

  Future<void> refreshSyncStatus() async {
    final pending = await _dao.getPendingCount();
    final deleted = await _dao.getDeletedCount();
    final conflicts = await _dao.getConflictCount();
    final retryQueue = await _dao.getRetryQueueCount();

    syncStatus.value = syncStatus.value.copyWith(
      pendingCount: pending,
      deletedCount: deleted,
      conflictCount: conflicts,
      retryQueueCount: retryQueue,
    );
  }

  Future<bool> sync(String token) async {
    if (_syncing) return false;
    _syncing = true;
    await refreshSyncStatus();
    syncStatus.value = syncStatus.value.copyWith(
      isSyncing: true,
      clearError: true,
      lastAttemptAtMillis: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      debugPrint("[PatientSync] checking connectivity...");
      if (!await _connectivity.isOnline()) {
        debugPrint("[PatientSync] offline - skipping");
        await refreshSyncStatus();
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

        if (patient.serverId != null) {
          final updateSynced = await _syncExistingPatientUpdate(
            token: token,
            patient: patient,
            serverIndex: serverIndex,
          );
          if (!updateSynced) {
            allPendingSynced = false;
          }
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
          final serverPayload = serverIndex.byIdPayload[matchedServerId];
          await _dao.markSynced(
            localId: patient.localId!,
            serverId: matchedServerId,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            baseHash: serverPayload == null ? null : _hashFromServer(serverPayload),
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
            final serverPayload = serverIndex.byIdPayload[recoveredServerId];
            await _dao.markSynced(
              localId: patient.localId!,
              serverId: recoveredServerId,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
              baseHash: serverPayload == null ? null : _hashFromServer(serverPayload),
            );
            debugPrint(
              '[PatientSync] recovered local ${patient.localId} after create failure -> serverId=$recoveredServerId',
            );
            continue;
          }
          debugPrint('[PatientSync] failed to create patient ${patient.localId}: ${createRes.statusCode} ${createRes.body}');
          await _dao.markRetryFailure(
            localId: patient.localId!,
            error: 'Create failed (${createRes.statusCode})',
          );
          allPendingSynced = false;
          continue;
        }

        final body = jsonDecode(createRes.body);
        final serverId = _parseServerId(body['id']);
        if (serverId == null) {
          final recoveredServerId = await _findServerIdForLocalPatient(token, patient);
          if (recoveredServerId != null) {
            final serverPayload = serverIndex.byIdPayload[recoveredServerId];
            await _dao.markSynced(
              localId: patient.localId!,
              serverId: recoveredServerId,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
              baseHash: serverPayload == null ? null : _hashFromServer(serverPayload),
            );
            debugPrint(
              '[PatientSync] recovered local ${patient.localId} after missing id -> serverId=$recoveredServerId',
            );
            continue;
          }
          debugPrint('[PatientSync] missing server id in create response for local ${patient.localId}');
          await _dao.markRetryFailure(
            localId: patient.localId!,
            error: 'Create response missing server id',
          );
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
          baseHash: _hashFromLocal(patient),
        );
        debugPrint('[PatientSync] marked local ${patient.localId} as synced -> serverId=$serverId');
      }

      // 🔹 DELETE SYNC
      await _syncDeleted(token);

      if (allPendingSynced) {
        await _saveLastSyncMillis(DateTime.now().millisecondsSinceEpoch);
        syncRevision.value = syncRevision.value + 1;
      }

      await refreshSyncStatus();
      return allPendingSynced;
    } catch (e) {
      syncStatus.value = syncStatus.value.copyWith(
        lastError: e.toString(),
      );
      rethrow;
    } finally {
      _syncing = false;
      syncStatus.value = syncStatus.value.copyWith(isSyncing: false);
      debugPrint("[PatientSync] finished sync");
    }
  }

  Future<bool> _syncExistingPatientUpdate({
    required String token,
    required PatientOfflineEntity patient,
    required _ServerPatientIndex serverIndex,
  }) async {
    final localId = patient.localId;
    final serverId = patient.serverId;
    if (localId == null || serverId == null) return false;

    final serverPayload = serverIndex.byIdPayload[serverId];
    if (serverPayload == null) {
      await _dao.markRetryFailure(
        localId: localId,
        error: 'Server patient not found for update',
      );
      return false;
    }

    final serverHash = _hashFromServer(serverPayload);
    final baseHash = (patient.baseHash ?? '').trim();

    if (baseHash.isNotEmpty && baseHash != serverHash) {
      await _dao.markConflict(
        localId: localId,
        serverPayload: serverPayload,
        reason: 'Server record changed since your last sync',
      );
      return false;
    }

    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/patients/$serverId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'patientName': patient.name,
          'gender': patient.gender,
          'age': patient.age,
          'dateOfBirth': patient.dateOfBirth,
          'address': patient.address,
          'description': patient.description,
          'phoneNumber': patient.phoneNumber,
          'clientTempId': patient.uuid,
          'photoPath': patient.photoPath,
        }),
      );

      if (res.statusCode != 200) {
        await _dao.markRetryFailure(
          localId: localId,
          error: 'Update failed (${res.statusCode})',
        );
        return false;
      }

      await _dao.markSynced(
        localId: localId,
        serverId: serverId,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        baseHash: _hashFromLocal(patient),
      );
      return true;
    } catch (e) {
      await _dao.markRetryFailure(
        localId: localId,
        error: 'Update error: $e',
      );
      return false;
    }
  }

  Future<void> resolveConflictKeepLocal({
    required int localId,
    required String token,
  }) async {
    final patient = await _dao.getByLocalId(localId);
    if (patient == null || patient.serverId == null) {
      throw Exception('Conflict item not found');
    }

    final res = await http.put(
      Uri.parse('$baseUrl/api/patients/${patient.serverId}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'patientName': patient.name,
        'gender': patient.gender,
        'age': patient.age,
        'dateOfBirth': patient.dateOfBirth,
        'address': patient.address,
        'description': patient.description,
        'phoneNumber': patient.phoneNumber,
        'clientTempId': patient.uuid,
        'photoPath': patient.photoPath,
      }),
    );

    if (res.statusCode != 200) {
      await _dao.markRetryFailure(
        localId: localId,
        error: 'Conflict resolve failed (${res.statusCode})',
      );
      throw Exception('Unable to keep local changes (${res.statusCode})');
    }

    await _dao.markSynced(
      localId: localId,
      serverId: patient.serverId!,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      baseHash: _hashFromLocal(patient),
    );
    syncRevision.value = syncRevision.value + 1;
    await refreshSyncStatus();
  }

  Future<void> resolveConflictKeepServer({
    required int localId,
  }) async {
    final patient = await _dao.getByLocalId(localId);
    if (patient == null) {
      throw Exception('Conflict item not found');
    }

    final payloadRaw = (patient.conflictServerPayload ?? '').trim();
    if (payloadRaw.isEmpty) {
      throw Exception('No server snapshot available for conflict');
    }

    final decoded = jsonDecode(payloadRaw);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid server conflict payload');
    }

    final normalized = _normalizedServerPayload(decoded);
    if (normalized == null) {
      throw Exception('Invalid server record');
    }

    await _dao.resolveConflictKeepServer(
      localId: localId,
      serverId: normalized.serverId,
      name: normalized.name,
      gender: normalized.gender,
      age: normalized.age,
      dateOfBirth: normalized.dateOfBirth,
      address: normalized.address,
      phoneNumber: normalized.phoneNumber,
      description: normalized.description,
      photoPath: normalized.photoPath,
      baseHash: _hashFromServer(decoded),
    );
    syncRevision.value = syncRevision.value + 1;
    await refreshSyncStatus();
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
    final byIdPayload = <int, Map<String, dynamic>>{};

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
          byIdPayload: byIdPayload,
        );
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! List) {
        return _ServerPatientIndex(
          byUuid: byUuid,
          byFingerprint: byFingerprint,
          byPhone: byPhone,
          byPhoneDob: byPhoneDob,
          byIdPayload: byIdPayload,
        );
      }

      for (final row in decoded) {
        if (row is! Map<String, dynamic>) continue;

        final dynamic idRaw = row['id'];
        final dynamic uuidRaw = row['uuid'] ?? row['clientTempId'];
        if (idRaw == null) continue;

        final parsedId = idRaw is int ? idRaw : int.tryParse('$idRaw');
        if (parsedId == null) continue;
        byIdPayload[parsedId] = row;

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
      byIdPayload: byIdPayload,
    );
  }

  String _hashFromLocal(PatientOfflineEntity patient) {
    return _hashFromNormalized(
      name: patient.name,
      gender: patient.gender,
      age: patient.age,
      dateOfBirth: patient.dateOfBirth,
      address: patient.address,
      phoneNumber: patient.phoneNumber,
      description: patient.description,
    );
  }

  String _hashFromServer(Map<String, dynamic> payload) {
    final normalized = _normalizedServerPayload(payload);
    if (normalized == null) return '';
    return _hashFromNormalized(
      name: normalized.name,
      gender: normalized.gender,
      age: normalized.age,
      dateOfBirth: normalized.dateOfBirth,
      address: normalized.address,
      phoneNumber: normalized.phoneNumber,
      description: normalized.description,
    );
  }

  String _hashFromNormalized({
    required String name,
    required String gender,
    required int age,
    required String dateOfBirth,
    required String address,
    required String phoneNumber,
    required String description,
  }) {
    final normalized = [
      name.trim().toLowerCase(),
      gender.trim().toLowerCase(),
      age.toString(),
      _normalizeDob(dateOfBirth),
      address.trim().toLowerCase(),
      _normalizePhone(phoneNumber),
      description.trim().toLowerCase(),
    ].join('|');
    return normalized;
  }

  _NormalizedServerPatient? _normalizedServerPayload(Map<String, dynamic> payload) {
    final idRaw = payload['id'];
    final serverId = idRaw is int ? idRaw : int.tryParse('${payload['id'] ?? ''}');
    final ageRaw = payload['age'];
    final age = ageRaw is int ? ageRaw : int.tryParse('${payload['age'] ?? ''}');
    if (serverId == null || age == null) return null;

    return _NormalizedServerPatient(
      serverId: serverId,
      name: '${payload['patientName'] ?? payload['name'] ?? ''}'.trim(),
      gender: '${payload['gender'] ?? ''}'.trim(),
      age: age,
      dateOfBirth: '${payload['dateOfBirth'] ?? ''}'.trim(),
      address: '${payload['address'] ?? ''}'.trim(),
      phoneNumber: '${payload['phoneNumber'] ?? ''}'.trim(),
      description: '${payload['description'] ?? ''}'.trim(),
      photoPath: payload['photoPath']?.toString(),
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
      if (patient.serverId == null) {
        if (patient.localId != null) {
          await _dao.hardDeleteByUuid(patient.uuid);
        }
        continue;
      }

      try {
        final res = await http.delete(
          Uri.parse("$baseUrl/api/patients/${patient.serverId}"),
          headers: {"Authorization": "Bearer $token"},
        );

        if (res.statusCode == 200 || res.statusCode == 204) {
          await _dao.hardDeleteByUuid(patient.uuid);
        } else {
          if (patient.localId != null) {
            await _dao.markRetryFailure(
              localId: patient.localId!,
              error: 'Delete failed (${res.statusCode})',
            );
          }
        }
      } catch (e) {
        if (patient.localId != null) {
          await _dao.markRetryFailure(
            localId: patient.localId!,
            error: 'Delete error: $e',
          );
        }
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
    required this.byIdPayload,
  });

  final Map<String, int> byUuid;
  final Map<String, int> byFingerprint;
  final Map<String, int> byPhone;
  final Map<String, int> byPhoneDob;
  final Map<int, Map<String, dynamic>> byIdPayload;
}

class _NormalizedServerPatient {
  const _NormalizedServerPatient({
    required this.serverId,
    required this.name,
    required this.gender,
    required this.age,
    required this.dateOfBirth,
    required this.address,
    required this.phoneNumber,
    required this.description,
    this.photoPath,
  });

  final int serverId;
  final String name;
  final String gender;
  final int age;
  final String dateOfBirth;
  final String address;
  final String phoneNumber;
  final String description;
  final String? photoPath;
}
