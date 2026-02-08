class Patient {
  final int id;
  final String name;
  final String gender;
  final int age;
  final String dateOfBirth;
  final String address;
  final String phoneNumber;
  final String? photoPath;

  Patient({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.dateOfBirth,
    required this.address,
    required this.phoneNumber,
    this.photoPath,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['patientName'],
      gender: json['gender'],
      age: json['age'],
      dateOfBirth: json['dateOfBirth'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      photoPath: json['photoPath'],
    );
  }
}
