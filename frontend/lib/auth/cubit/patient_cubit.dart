import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/patient/patient_model.dart';
import 'package:frontend/services/patient_service.dart';
import 'package:http/http.dart' as http;


class PatientState {
  final bool loading;
  final List<Patient> patients;

  PatientState({
    this.loading = false,
    this.patients = const [],
  });
}

class PatientCubit extends Cubit<PatientState> {
  final PatientService service;

  PatientCubit(this.service) : super(PatientState());

  Future<void> loadPatients(String token) async {
    emit(PatientState(loading: true));
    final patients = await service.getPatients(token);
    emit(PatientState(loading: false, patients: patients));
  }

  Future<void> deletePatient({
  required int patientId,
  required String token,
}) async {
  final url = Uri.parse("http://10.0.2.2:8080/api/patients/$patientId");

  final response = await http.delete(
    url,
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode != 204) {
    throw Exception("Failed to delete patient");
  }
}

}
