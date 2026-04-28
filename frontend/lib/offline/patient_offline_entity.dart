import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'sync_status_offline.dart';

class PatientOfflineEntity {
  final int? localId;
  final int? serverId;

  /// GLOBAL ID (critical for sync)
  final String uuid;

  final String name;
  final String gender;
  final int age;
  final String dateOfBirth;
  final String address;
  final String description;
  final String phoneNumber;
  final String? photoPath;
  final String caste;
  final bool isPregnant;
  final int? monthsOfPregnancy;
  final String expectedDeliveryDate;
  final bool declinedHealthInfo;
  final Map<String, bool> diseases;

  final int syncStatus;
  final int updatedAt;
  final int retryCount;
  final String? lastError;
  final String? baseHash;
  final String? conflictServerPayload;

  PatientOfflineEntity({
    this.localId,
    this.serverId,
    String? uuid,
    required this.name,
    required this.gender,
    required this.age,
    required this.dateOfBirth,
    required this.address,
    this.description = '',
    required this.phoneNumber,
    this.photoPath,
    this.caste = '',
    this.isPregnant = false,
    this.monthsOfPregnancy,
    this.expectedDeliveryDate = '',
    this.declinedHealthInfo = false,
    this.diseases = const {},
    this.syncStatus = SyncStatusOffline.pending,
    int? updatedAt,
    this.retryCount = 0,
    this.lastError,
    this.baseHash,
    this.conflictServerPayload,
  })  : uuid = uuid ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  // ===== SQLITE → OBJECT =====

  factory PatientOfflineEntity.fromMap(Map<String, dynamic> map) {
    // Parse diseases from JSON string
    Map<String, bool> parsedDiseases = const {};
    final diseaseData = map['diseases'];
    if (diseaseData != null && diseaseData.toString().isNotEmpty) {
      try {
        if (diseaseData is String) {
          final decoded = jsonDecode(diseaseData);
          if (decoded is Map) {
            parsedDiseases = decoded.map((k, v) => MapEntry(k.toString(), v == true));
          }
        } else if (diseaseData is Map) {
          parsedDiseases = diseaseData.map((k, v) => MapEntry(k.toString(), v == true));
        }
      } catch (_) {}
    }

    return PatientOfflineEntity(
      localId: map['localId'],
      serverId: map['serverId'],
      uuid: map['uuid'],
      name: map['name'],
      gender: map['gender'],
      age: map['age'],
      dateOfBirth: map['dateOfBirth'],
      address: map['address'],
      description: (map['description'] ?? '').toString(),
      phoneNumber: map['phoneNumber'],
      photoPath: map['photoPath'],
      caste: (map['caste'] ?? '').toString(),
      isPregnant: (map['isPregnant'] as int?) == 1,
      monthsOfPregnancy: map['monthsOfPregnancy'] is int ? map['monthsOfPregnancy'] as int : null,
      expectedDeliveryDate: (map['expectedDeliveryDate'] ?? '').toString(),
      declinedHealthInfo: (map['declinedHealthInfo'] as int?) == 1,
      diseases: parsedDiseases,
      syncStatus: map['syncStatus'],
      updatedAt: map['updatedAt'],
      retryCount: (map['retryCount'] as int?) ?? 0,
      lastError: map['lastError']?.toString(),
      baseHash: map['baseHash']?.toString(),
      conflictServerPayload: map['conflictServerPayload']?.toString(),
    );
  }

  // ===== OBJECT → SQLITE =====

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'serverId': serverId,
      'name': name,
      'gender': gender,
      'age': age,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'description': description,
      'phoneNumber': phoneNumber,
      'photoPath': photoPath,
      'caste': caste,
      'isPregnant': isPregnant ? 1 : 0,
      'monthsOfPregnancy': monthsOfPregnancy,
      'expectedDeliveryDate': expectedDeliveryDate,
      'declinedHealthInfo': declinedHealthInfo ? 1 : 0,
      'diseases': jsonEncode(diseases),
      'syncStatus': syncStatus,
      'updatedAt': updatedAt,
      'retryCount': retryCount,
      'lastError': lastError,
      'baseHash': baseHash,
      'conflictServerPayload': conflictServerPayload,
    };
  }

  PatientOfflineEntity copyWith({
    int? localId,
    int? serverId,
    String? caste,
    bool? isPregnant,
    int? monthsOfPregnancy,
    String? expectedDeliveryDate,
    bool? declinedHealthInfo,
    Map<String, bool>? diseases,
    int? syncStatus,
    int? updatedAt,
    int? retryCount,
    String? lastError,
    String? baseHash,
    String? conflictServerPayload,
  }) {
    return PatientOfflineEntity(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      uuid: uuid,
      name: name,
      gender: gender,
      age: age,
      dateOfBirth: dateOfBirth,
      address: address,
      description: description,
      phoneNumber: phoneNumber,
      photoPath: photoPath,
      caste: caste ?? this.caste,
      isPregnant: isPregnant ?? this.isPregnant,
      monthsOfPregnancy: monthsOfPregnancy ?? this.monthsOfPregnancy,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      declinedHealthInfo: declinedHealthInfo ?? this.declinedHealthInfo,
      diseases: diseases ?? this.diseases,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      baseHash: baseHash ?? this.baseHash,
      conflictServerPayload: conflictServerPayload ?? this.conflictServerPayload,
    );
  }
}
