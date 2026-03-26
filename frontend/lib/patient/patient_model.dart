class Patient {
  final int? id;          // server ID (nullable for offline-only)
  final String uuid;      // GLOBAL ID (critical)
  final String name;
  final String gender;
  final int age;
  final String dateOfBirth;
  final String address;
  final String phoneNumber;
  final String description;
  final String? photoPath;
  final String caste;
  final bool isPregnant;
  final int? monthsOfPregnancy;
  final String? expectedDeliveryDate;
  final List<String> medicalConditions; // Selected condition IDs

  Patient({
    this.id,
    required this.uuid,
    required this.name,
    required this.gender,
    required this.age,
    required this.dateOfBirth,
    required this.address,
    required this.phoneNumber,
    this.description = '',
    this.photoPath,
    this.caste = '',
    this.isPregnant = false,
    this.monthsOfPregnancy,
    this.expectedDeliveryDate,
    this.medicalConditions = const [],
  });

  // ================= BACKEND → UI =================
  factory Patient.fromJson(Map<String, dynamic> json) {
    final conditions = List<String>.from(json['medicalConditions'] ?? json['conditions'] ?? []);
    return Patient(
      id: json['id'],
      uuid: json['uuid'] ?? (json['id'] != null ? json['id'].toString() : ''), // fallback to id if uuid missing
      name: json['patientName'],
      gender: json['gender'],
      age: json['age'],
      dateOfBirth: json['dateOfBirth'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      description: (json['description'] ?? '').toString(),
      photoPath: json['photoPath'],
      caste: json['caste'] ?? '',
      isPregnant: json['isPregnant'] ?? false,
      monthsOfPregnancy: json['monthsOfPregnancy'],
      expectedDeliveryDate: json['expectedDeliveryDate'],
      medicalConditions: conditions,
    );
  }

  // ================= OFFLINE → UI =================
  factory Patient.fromOffline(Map<String, dynamic> map) {
    final conditionsJson = map['medicalConditions'] ?? '[]';
    List<String> conditions = [];
    try {
      conditions = List<String>.from(
        (conditionsJson is String) 
          ? (conditionsJson.isEmpty ? [] : conditionsJson.split(','))
          : (conditionsJson ?? [])
      );
    } catch (_) {
      conditions = [];
    }
    
    return Patient(
      id: map['serverId'],     // may be null
      uuid: map['uuid'],       // always present
      name: map['name'],
      gender: map['gender'],
      age: map['age'],
      dateOfBirth: map['dateOfBirth'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      description: (map['description'] ?? '').toString(),
      photoPath: map['photoPath'],
      caste: map['caste'] ?? '',
      isPregnant: (map['isPregnant'] ?? 0) == 1,
      monthsOfPregnancy: map['monthsOfPregnancy'],
      expectedDeliveryDate: map['expectedDeliveryDate'],
      medicalConditions: conditions,
    );
  }
}
