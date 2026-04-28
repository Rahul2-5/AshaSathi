class FamilyRecord {
  final int id;
  final String headOfFamily;
  final int numberOfMembers;
  final String familyAddress;
  final List<FamilyMemberRecord> patients;

  FamilyRecord({
    required this.id,
    required this.headOfFamily,
    required this.numberOfMembers,
    required this.familyAddress,
    required this.patients,
  });

  factory FamilyRecord.fromJson(Map<String, dynamic> json) {
    final patientsJson = json['patients'];
    final patientList = patientsJson is List
        ? patientsJson
            .whereType<Map<String, dynamic>>()
            .map(FamilyMemberRecord.fromJson)
            .toList()
        : <FamilyMemberRecord>[];

    return FamilyRecord(
      id: (json['id'] as num?)?.toInt() ?? -1,
      headOfFamily: (json['headOfFamily'] ?? '').toString(),
      numberOfMembers: (json['numberOfMembers'] as num?)?.toInt() ?? patientList.length,
      familyAddress: (json['familyAddress'] ?? '').toString(),
      patients: patientList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'headOfFamily': headOfFamily,
      'numberOfMembers': numberOfMembers,
      'familyAddress': familyAddress,
      'patients': patients.map((patient) => patient.toJson()).toList(),
    };
  }
}

class FamilyMemberRecord {
  final int? id;
  final String patientName;
  final int age;
  final String dateOfBirth;
  final String gender;
  final String caste;
  final String address;
  final String phoneNumber;
  final bool isPregnant;
  final int? monthsOfPregnancy;
  final String expectedDeliveryDate;
  final String? photoPath;
  final Map<String, bool> diseases;
  final bool declinedHealthInfo;
  final String notes;

  FamilyMemberRecord({
    required this.id,
    required this.patientName,
    required this.age,
    required this.dateOfBirth,
    required this.gender,
    required this.caste,
    required this.address,
    required this.phoneNumber,
    required this.isPregnant,
    required this.monthsOfPregnancy,
    required this.expectedDeliveryDate,
    required this.photoPath,
    required this.diseases,
    required this.declinedHealthInfo,
    required this.notes,
  });

  factory FamilyMemberRecord.fromJson(Map<String, dynamic> json) {
    final diseasesValue = json['diseases'];
    final parsedDiseases = <String, bool>{};

    if (diseasesValue is Map) {
      for (final entry in diseasesValue.entries) {
        parsedDiseases[entry.key.toString()] = entry.value == true;
      }
    }

    return FamilyMemberRecord(
      id: (json['id'] as num?)?.toInt(),
      patientName: (json['patientName'] ?? '').toString(),
      age: (json['age'] as num?)?.toInt() ?? 0,
      dateOfBirth: (json['dateOfBirth'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      caste: (json['caste'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      isPregnant: json['isPregnant'] == true,
      monthsOfPregnancy: (json['monthsOfPregnancy'] as num?)?.toInt(),
      expectedDeliveryDate: (json['expectedDeliveryDate'] ?? '').toString(),
      photoPath: json['photoPath']?.toString(),
      diseases: parsedDiseases,
      declinedHealthInfo: json['declinedHealthInfo'] == true,
      notes: (json['notes'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientName': patientName,
      'age': age,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'caste': caste,
      'address': address,
      'phoneNumber': phoneNumber,
      'isPregnant': isPregnant,
      'monthsOfPregnancy': monthsOfPregnancy,
      'expectedDeliveryDate': expectedDeliveryDate,
      'photoPath': photoPath,
      'diseases': diseases,
      'declinedHealthInfo': declinedHealthInfo,
      'notes': notes,
    };
  }
}
