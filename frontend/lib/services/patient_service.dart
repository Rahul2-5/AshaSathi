import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../patient/patient_model.dart';
import '../offline/connectivity_service.dart';
import '../offline/patient_offline_dao.dart';

class PatientService {
  static const String baseUrl =
      "http://10.0.2.2:8080/api/patients";

  final ConnectivityService _connectivity = ConnectivityService();
  final PatientOfflineDao _offlineDao = PatientOfflineDao();

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
        phoneNumber: p.phoneNumber,
        photoPath: p.photoPath,
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
      final onlineModels = data.map((e) => Patient.fromJson(e)).toList();
      debugPrint("Loaded ${onlineModels.length} patients from backend");

      // ===============================
      // ✅ 4. RETURN BACKEND PATIENTS (server is source of truth)
      // ===============================
      return onlineModels;
    } catch (e) {
      debugPrint("Error fetching from backend: $e");
      return offlineModels;
    }
  }
}
