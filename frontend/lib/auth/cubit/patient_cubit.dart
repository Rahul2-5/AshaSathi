import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/config/app_config.dart';
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

  void upsertPatient(Patient updated) {
    final current = List<Patient>.from(state.patients);
    final index = current.indexWhere((p) => p.uuid == updated.uuid);
    if (index >= 0) {
      current[index] = updated;
    } else {
      current.insert(0, updated);
    }
    emit(PatientState(loading: false, patients: current));
  }

  void removePatientByUuid(String uuid) {
    final current = state.patients.where((p) => p.uuid != uuid).toList();
    emit(PatientState(loading: false, patients: current));
  }

  Future<void> deletePatient({
  required int patientId,
  required String token,
}) async {
  final url = Uri.parse("${AppConfig.patientsBaseUrl}/$patientId");

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
