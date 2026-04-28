import 'package:frontend/patient/medical_model.dart';

class AddPatientFormData {
  final String memberNumber; // "Member 1", "Member 2", etc.
  final String name;
  final int? age;
  final String dateOfBirth; // yyyy-MM-dd
  final String gender; // 'Male', 'Female', 'Other'
  final String caste;
  final String phoneNumber;
  final String? address; // null means use family address
  final bool usesFamilyAddress;
  final String? photoPath;
  
  // Pregnancy fields (only for females)
  final bool isPregnant;
  final int? monthsOfPregnancy;
  final String? expectedDeliveryDate; // yyyy-MM-dd
  
  // Medical info
  final PatientMedicalInfo medicalInfo;

  AddPatientFormData({
    required this.memberNumber,
    required this.name,
    this.age,
    this.dateOfBirth = '',
    this.gender = 'Male',
    this.caste = '',
    this.phoneNumber = '',
    this.address,
    this.usesFamilyAddress = true,
    this.photoPath,
    this.isPregnant = false,
    this.monthsOfPregnancy,
    this.expectedDeliveryDate,
    PatientMedicalInfo? medicalInfo,
  }) : medicalInfo = medicalInfo ?? PatientMedicalInfo();

  AddPatientFormData copyWith({
    String? memberNumber,
    String? name,
    int? age,
    String? dateOfBirth,
    String? gender,
    String? caste,
    String? phoneNumber,
    String? address,
    bool? usesFamilyAddress,
    String? photoPath,
    bool? isPregnant,
    int? monthsOfPregnancy,
    String? expectedDeliveryDate,
    PatientMedicalInfo? medicalInfo,
  }) {
    return AddPatientFormData(
      memberNumber: memberNumber ?? this.memberNumber,
      name: name ?? this.name,
      age: age ?? this.age,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      caste: caste ?? this.caste,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      usesFamilyAddress: usesFamilyAddress ?? this.usesFamilyAddress,
      photoPath: photoPath ?? this.photoPath,
      isPregnant: isPregnant ?? this.isPregnant,
      monthsOfPregnancy: monthsOfPregnancy ?? this.monthsOfPregnancy,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      medicalInfo: medicalInfo ?? this.medicalInfo,
    );
  }

  bool isValidForPatientStep() {
    if (name.trim().isEmpty) return false;
    if (gender.isEmpty) return false;
    
    // Phone can be optional (no strict validation)
    // Age or DOB required
    if ((age == null || age == 0) && dateOfBirth.isEmpty) return false;
    
    // If pregnant, months required
    if (isPregnant && (monthsOfPregnancy == null || monthsOfPregnancy! < 1 || monthsOfPregnancy! > 9)) {
      return false;
    }
    
    return true;
  }

  Map<String, dynamic> toJson(String familyAddress) {
    return {
      'name': name,
      'age': age,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'caste': caste,
      'phoneNumber': phoneNumber,
      'address': usesFamilyAddress ? familyAddress : (address ?? familyAddress),
      'photoPath': photoPath,
      'isPregnant': isPregnant,
      'monthsOfPregnancy': monthsOfPregnancy,
      'expectedDeliveryDate': expectedDeliveryDate,
      'medical': medicalInfo.toJson(),
    };
  }
}
