import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'connectivity_service.dart';
import 'patient_offline_dao.dart';


class PatientSyncService {
  final PatientOfflineDao _dao = PatientOfflineDao();
  final ConnectivityService _connectivity = ConnectivityService();

  static const String baseUrl = "http://10.0.2.2:8080";
  bool _syncing = false;

  Future<bool> sync(String token) async {
    if (_syncing) return false;
    _syncing = true;

    try {
      if (!await _connectivity.isOnline()) return false;

      // 🔹 CREATE / UPDATE
      final pending = await _dao.getPending();

      for (final patient in pending) {
        if (patient.localId == null) continue;

        String? uploadedPhotoPath;

        if (patient.photoPath != null &&
            patient.photoPath!.startsWith("/") &&
            File(patient.photoPath!).existsSync()) {
          final req = http.MultipartRequest(
            "POST",
            Uri.parse("$baseUrl/api/patients/photo"),
          );

          req.headers["Authorization"] = "Bearer $token";
          req.files.add(await http.MultipartFile.fromPath(
            "photo",
            patient.photoPath!,
          ));

          final res = await req.send();
          if (res.statusCode == 200) {
            uploadedPhotoPath = await res.stream.bytesToString();
          }
        }

        final response = await http.post(
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
            "photoPath": uploadedPhotoPath,
            "clientTempId": patient.uuid,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final serverId = jsonDecode(response.body)["id"];
          await _dao.markSynced(
            localId: patient.localId!,
            serverId: serverId,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }

      // 🔹 DELETE SYNC
      await _syncDeleted(token);

      return true;
    } finally {
      _syncing = false;
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
