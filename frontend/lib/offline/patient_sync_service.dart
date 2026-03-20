import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:frontend/config/app_config.dart';
import 'package:http/http.dart' as http;

import 'connectivity_service.dart';
import 'patient_offline_dao.dart';


class PatientSyncService {
  final PatientOfflineDao _dao = PatientOfflineDao();
  final ConnectivityService _connectivity = ConnectivityService();

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

      // 🔹 CREATE / UPDATE
      final pending = await _dao.getPending();
      debugPrint("[PatientSync] pending patients: ${pending.length}");

      for (final patient in pending) {
        if (patient.localId == null) continue;

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
            "phoneNumber": patient.phoneNumber,
            "clientTempId": patient.uuid,
          }),
        );

        debugPrint('[PatientSync] create patient POST ${createRes.statusCode}');
        if (createRes.statusCode != 200 && createRes.statusCode != 201) {
          debugPrint('[PatientSync] failed to create patient ${patient.localId}: ${createRes.statusCode} ${createRes.body}');
          continue;
        }

        final body = jsonDecode(createRes.body);
        final serverId = body['id'];
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

      return true;
    } finally {
      _syncing = false;
      debugPrint("[PatientSync] finished sync");
    }
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
