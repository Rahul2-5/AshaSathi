import 'dart:convert';
import 'package:frontend/patient/patient_model.dart';
import 'package:http/http.dart' as http;


class PatientService {
  static const String baseUrl =
      "http://10.0.2.2:8080/api/patients";

  Future<List<Patient>> getPatients(String token) async {
    final res = await http.get(
      Uri.parse(baseUrl),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load patients");
    }

    final List data = jsonDecode(res.body);
    return data.map((e) => Patient.fromJson(e)).toList();
  }
}
