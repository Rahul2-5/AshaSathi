import 'patient_offline_entity.dart';
import 'patient_offline_dao.dart';
import 'sync_status_offline.dart';

class PatientOfflineService {
  final PatientOfflineDao _dao = PatientOfflineDao();

  Future<void> saveOffline({
    required String name,
    required String gender,
    required int age,
    required String dateOfBirth,
    required String address,
    required String phoneNumber,
    String? photoPath,
  }) async {
    final patient = PatientOfflineEntity(
      name: name,
      gender: gender,
      age: age,
      dateOfBirth: dateOfBirth,
      address: address,
      phoneNumber: phoneNumber,
      photoPath: photoPath,
      syncStatus: SyncStatusOffline.pending,
    );

    await _dao.upsert(patient);
  }

  
}
