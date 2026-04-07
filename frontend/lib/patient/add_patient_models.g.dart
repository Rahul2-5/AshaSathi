// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_patient_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FamilyInfoImpl _$$FamilyInfoImplFromJson(Map<String, dynamic> json) =>
    _$FamilyInfoImpl(
      headOfFamily: json['headOfFamily'] as String,
      numberOfMembers: json['numberOfMembers'] as String,
      familyAddress: json['familyAddress'] as String,
      sameAddressForAll: json['sameAddressForAll'] as bool? ?? true,
    );

Map<String, dynamic> _$$FamilyInfoImplToJson(_$FamilyInfoImpl instance) =>
    <String, dynamic>{
      'headOfFamily': instance.headOfFamily,
      'numberOfMembers': instance.numberOfMembers,
      'familyAddress': instance.familyAddress,
      'sameAddressForAll': instance.sameAddressForAll,
    };

_$PatientDataModelImpl _$$PatientDataModelImplFromJson(
  Map<String, dynamic> json,
) => _$PatientDataModelImpl(
  id: json['id'] as String,
  patientName: json['patientName'] as String,
  age: json['age'] as String,
  dateOfBirth: json['dateOfBirth'] as String,
  gender: json['gender'] as String,
  caste: json['caste'] as String,
  address: json['address'] as String,
  sameAsFamilyAddress: json['sameAsFamilyAddress'] as bool? ?? true,
  phoneNumber: json['phoneNumber'] as String,
  isPregnant: json['isPregnant'] as bool? ?? false,
  monthsOfPregnancy: json['monthsOfPregnancy'] as String? ?? '1',
  expectedDeliveryDate: json['expectedDeliveryDate'] as String,
  photoPath: json['photoPath'] as String?,
  diseases: Map<String, bool>.from(json['diseases'] as Map),
  declinedHealthInfo: json['declinedHealthInfo'] as bool? ?? false,
  notes: json['notes'] as String,
);

Map<String, dynamic> _$$PatientDataModelImplToJson(
  _$PatientDataModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'patientName': instance.patientName,
  'age': instance.age,
  'dateOfBirth': instance.dateOfBirth,
  'gender': instance.gender,
  'caste': instance.caste,
  'address': instance.address,
  'sameAsFamilyAddress': instance.sameAsFamilyAddress,
  'phoneNumber': instance.phoneNumber,
  'isPregnant': instance.isPregnant,
  'monthsOfPregnancy': instance.monthsOfPregnancy,
  'expectedDeliveryDate': instance.expectedDeliveryDate,
  'photoPath': instance.photoPath,
  'diseases': instance.diseases,
  'declinedHealthInfo': instance.declinedHealthInfo,
  'notes': instance.notes,
};

_$PatientRegistrationPayloadImpl _$$PatientRegistrationPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$PatientRegistrationPayloadImpl(
  familyInfo: FamilyInfo.fromJson(json['familyInfo'] as Map<String, dynamic>),
  patients: (json['patients'] as List<dynamic>)
      .map((e) => PatientDataModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$PatientRegistrationPayloadImplToJson(
  _$PatientRegistrationPayloadImpl instance,
) => <String, dynamic>{
  'familyInfo': instance.familyInfo,
  'patients': instance.patients,
};
