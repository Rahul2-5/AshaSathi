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

  /// Returns TRUE only if actual sync happened
  Future<bool> sync(String token) async {
    if (_syncing) return false;
    _syncing = true;

    try {
      if (!await _connectivity.isOnline()) return false;

      final pending = await _dao.getPending();
      if (pending.isEmpty) return false;

      for (final patient in pending) {
        if (patient.localId == null) continue;

        String? uploadedPhotoPath;

        // ================= 1️⃣ UPLOAD PHOTO =================
        if (patient.photoPath != null &&
            patient.photoPath!.startsWith("/") &&
            File(patient.photoPath!).existsSync()) {
          try {
            final request = http.MultipartRequest(
              "POST",
              Uri.parse("$baseUrl/api/patients/photo"),
            );

            request.headers["Authorization"] = "Bearer $token";

            request.files.add(
              await http.MultipartFile.fromPath(
                "photo",
                patient.photoPath!,
              ),
            );

            final response = await request.send().timeout(
                  const Duration(seconds: 15),
                );

            final body = await response.stream.bytesToString();

            if (response.statusCode == 200) {
              uploadedPhotoPath = body; // backend-relative path
            } else {
              continue; // retry later
            }
          } catch (_) {
            continue;
          }
        }

        // ================= 2️⃣ CREATE PATIENT =================
        try {
          final res = await http
              .post(
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
                  "photoPath": uploadedPhotoPath, // backend path only
                  "clientTempId": patient.localId, // optional safety
                }),
              )
              .timeout(const Duration(seconds: 10));

          if (res.statusCode == 200 || res.statusCode == 201) {
            final serverId = jsonDecode(res.body)["id"];

            await _dao.markSynced(
              localId: patient.localId!,
              serverId: serverId,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            );
          }
        } catch (_) {
          continue;
        }
      }

      return true;
    } finally {
      _syncing = false;
    }
  }
}
