import 'dart:convert';

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
  final String caste;
  final bool isPregnant;
  final int? monthsOfPregnancy;
  final String expectedDeliveryDate;
  final bool declinedHealthInfo;
  final Map<String, bool> diseases;
  final String? photoPath;
  final int? updatedAt;   // timestamp for sorting recent patients (millisecondsSinceEpoch)

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
    this.caste = '',
    this.isPregnant = false,
    this.monthsOfPregnancy,
    this.expectedDeliveryDate = '',
    this.declinedHealthInfo = false,
    this.diseases = const {},
    this.photoPath,
    this.updatedAt,
  });

  static Map<String, bool> _parseDiseases(dynamic value) {
    if (value is Map) {
      return value.map((key, dynamic entry) {
        return MapEntry(key.toString(), entry == true);
      });
    }

    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return decoded.map((key, dynamic entry) {
            return MapEntry(key.toString(), entry == true);
          });
        }
      } catch (_) {}
    }

    return const {};
  }

  List<String> get activeDiseaseLabels {
    return diseases.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  // ================= BACKEND → UI =================
  factory Patient.fromJson(Map<String, dynamic> json) {
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
      caste: (json['caste'] ?? '').toString(),
      isPregnant: json['isPregnant'] == true,
      monthsOfPregnancy: json['monthsOfPregnancy'] is int
          ? json['monthsOfPregnancy'] as int
          : int.tryParse((json['monthsOfPregnancy'] ?? '').toString()),
      expectedDeliveryDate: (json['expectedDeliveryDate'] ?? '').toString(),
      declinedHealthInfo: json['declinedHealthInfo'] == true,
      diseases: _parseDiseases(json['diseases']),
      photoPath: json['photoPath'],
      updatedAt: json['updatedAt'] is int 
          ? json['updatedAt'] 
          : int.tryParse((json['updatedAt'] ?? '').toString()),
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
      description: (map['description'] ?? '').toString(),
      caste: (map['caste'] ?? '').toString(),
      isPregnant: map['isPregnant'] == true,
      monthsOfPregnancy: map['monthsOfPregnancy'] is int
          ? map['monthsOfPregnancy'] as int
          : int.tryParse((map['monthsOfPregnancy'] ?? '').toString()),
      expectedDeliveryDate: (map['expectedDeliveryDate'] ?? '').toString(),
      declinedHealthInfo: map['declinedHealthInfo'] == true,
      diseases: _parseDiseases(map['diseases']),
      photoPath: map['photoPath'],
      updatedAt: map['updatedAt'] is int ? map['updatedAt'] : null,
    );
  }
}
