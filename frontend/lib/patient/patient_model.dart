class Patient {
  final int? id;          // server ID (nullable for offline-only)
  final String uuid;      // GLOBAL ID (critical)
  final String name;
  final String gender;
  final int age;
  final String dateOfBirth;
  final String address;
  final String phoneNumber;
  final String? photoPath;

  Patient({
    this.id,
    required this.uuid,
    required this.name,
    required this.gender,
    required this.age,
    required this.dateOfBirth,
    required this.address,
    required this.phoneNumber,
    this.photoPath,
  });

  // ================= BACKEND → UI =================
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      uuid: json['uuid'], // 👈 BACKEND MUST RETURN THIS
      name: json['patientName'],
      gender: json['gender'],
      age: json['age'],
      dateOfBirth: json['dateOfBirth'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      photoPath: json['photoPath'],
    );
  }

  // ================= OFFLINE → UI =================
  factory Patient.fromOffline(Map<String, dynamic> map) {
    return Patient(
      id: map['serverId'],     // may be null
      uuid: map['uuid'],       // always present
      name: map['name'],
      gender: map['gender'],
      age: map['age'],
      dateOfBirth: map['dateOfBirth'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      photoPath: map['photoPath'],
    );
  }
}
