import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_patient_models.freezed.dart';
part 'add_patient_models.g.dart';

/// ============================================
/// FAMILY INFORMATION MODEL
/// ============================================
@freezed
class FamilyInfo with _$FamilyInfo {
  const factory FamilyInfo({
    required String headOfFamily,
    required String numberOfMembers,
    required String familyAddress,
    @Default(true) bool sameAddressForAll,
  }) = _FamilyInfo;

  factory FamilyInfo.fromJson(Map<String, dynamic> json) =>
      _$FamilyInfoFromJson(json);
}

/// ============================================
/// PATIENT DATA MODEL (Individual member)
/// ============================================
@freezed
class PatientDataModel with _$PatientDataModel {
  const factory PatientDataModel({
    required String id,
    required String patientName,
    required String age,
    required String dateOfBirth,
    required String gender,
    required String caste,
    required String address,
    @Default(true) bool sameAsFamilyAddress,
    required String phoneNumber,
    
    // Pregnancy fields
    @Default(false) bool isPregnant,
    @Default('1') String monthsOfPregnancy,
    required String expectedDeliveryDate,
    
    // Photo
    String? photoPath,
    
    // Medical info
    required Map<String, bool> diseases,
    @Default(false) bool declinedHealthInfo,
    required String notes,
  }) = _PatientDataModel;

  factory PatientDataModel.fromJson(Map<String, dynamic> json) =>
      _$PatientDataModelFromJson(json);

  factory PatientDataModel.empty() => PatientDataModel(
    id: '1',
    patientName: '',
    age: '',
    dateOfBirth: '',
    gender: 'Female',
    caste: '',
    address: '',
    sameAsFamilyAddress: true,
    phoneNumber: '',
    isPregnant: false,
    monthsOfPregnancy: '1',
    expectedDeliveryDate: '',
    diseases: {
      'bp': false,
      'elephantiasis': false,
      'diabetes': false,
      'heartDisease': false,
      'asthma': false,
      'thyroid': false,
      'arthritis': false,
      'kidney': false,
      'liver': false,
      'cancer': false,
    },
    declinedHealthInfo: false,
    notes: '',
  );
}

/// ============================================
/// ADD PATIENT FORM STATE
/// ============================================
@freezed
class AddPatientFormState with _$AddPatientFormState {
  const factory AddPatientFormState({
    required int step, // 1, 2, or 3
    required FamilyInfo familyInfo,
    required List<PatientDataModel> patients,
    required int currentPatientIndex,
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
    @Default({}) Map<String, String> validationErrors,
  }) = _AddPatientFormState;

  factory AddPatientFormState.initial() => AddPatientFormState(
    step: 1,
    familyInfo: FamilyInfo(
      headOfFamily: '',
      numberOfMembers: '1',
      familyAddress: '',
      sameAddressForAll: true,
    ),
    patients: [PatientDataModel.empty()],
    currentPatientIndex: 0,
  );
}

/// ============================================
/// SUBMISSION PAYLOAD
/// ============================================
@freezed
class PatientRegistrationPayload with _$PatientRegistrationPayload {
  const factory PatientRegistrationPayload({
    required FamilyInfo familyInfo,
    required List<PatientDataModel> patients,
  }) = _PatientRegistrationPayload;

  factory PatientRegistrationPayload.fromJson(Map<String, dynamic> json) =>
      _$PatientRegistrationPayloadFromJson(json);
}
