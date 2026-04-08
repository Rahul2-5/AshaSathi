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
    String? description,
    required String phoneNumber,
    String? photoPath,
    String caste = '',
    bool isPregnant = false,
    int? monthsOfPregnancy,
    String expectedDeliveryDate = '',
    Map<String, bool> diseases = const {},
    bool declinedHealthInfo = false,
  }) async {
    final patient = PatientOfflineEntity(
      name: name,
      gender: gender,
      age: age,
      dateOfBirth: dateOfBirth,
      address: address,
      description: description?.trim() ?? '',
      phoneNumber: phoneNumber,
      photoPath: photoPath,
      caste: caste,
      isPregnant: isPregnant,
      monthsOfPregnancy: monthsOfPregnancy,
      expectedDeliveryDate: expectedDeliveryDate,
      diseases: diseases,
      declinedHealthInfo: declinedHealthInfo,
      syncStatus: SyncStatusOffline.pending,
    );

    await _dao.upsert(patient);
  }

  
}
