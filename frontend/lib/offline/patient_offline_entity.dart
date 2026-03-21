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

  final int syncStatus;
  final int updatedAt;

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
    this.syncStatus = SyncStatusOffline.pending,
    int? updatedAt,
  })  : uuid = uuid ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  // ===== SQLITE → OBJECT =====

  factory PatientOfflineEntity.fromMap(Map<String, dynamic> map) {
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
      syncStatus: map['syncStatus'],
      updatedAt: map['updatedAt'],
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
      'syncStatus': syncStatus,
      'updatedAt': updatedAt,
    };
  }

  PatientOfflineEntity copyWith({
    int? localId,
    int? serverId,
    int? syncStatus,
    int? updatedAt,
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
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
