import 'dart:convert';
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
    // 🔴 1. LOAD OFFLINE PATIENTS
    // ===============================
    final offlinePatients = await _offlineDao.getAll();

    final offlineModels = offlinePatients.map((p) {
      return Patient(
        id: p.serverId ?? -1, // temp ID if not synced
        name: p.name,
        gender: p.gender,
        age: p.age,
        dateOfBirth: p.dateOfBirth,
        address: p.address,
        phoneNumber: p.phoneNumber,
        photoPath: p.photoPath, // ✅ MATCHES MODEL
      );
    }).toList();

    // ===============================
    // 🔴 2. OFFLINE → RETURN LOCAL
    // ===============================
    if (!isOnline) {
      return offlineModels;
    }

    // ===============================
    // 🟢 3. ONLINE → FETCH BACKEND
    // ===============================
    final res = await http.get(
      Uri.parse(baseUrl),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      // fallback if backend fails
      return offlineModels;
    }

    final List data = jsonDecode(res.body);
    final onlineModels =
        data.map((e) => Patient.fromJson(e)).toList();

    // ===============================
    // ✅ 4. MERGE (OFFLINE FIRST)
    // ===============================
    return [...offlineModels, ...onlineModels];
  }
}
