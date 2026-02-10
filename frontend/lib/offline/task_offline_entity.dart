import 'package:frontend/offline/sync_status_offline.dart';
import 'package:uuid/uuid.dart';

class TaskOfflineEntity {
  final int? localId;
  final String uuid; // ✅ ADD
  final int? serverId;
  final String title;
  final String? description;
  final String status;
  final String createdDate;
  final int syncStatus;
  final int updatedAt; // ✅ CHANGE TYPE

  TaskOfflineEntity({
    this.localId,
    String? uuid,
    this.serverId,
    required this.title,
    this.description,
    required this.status,
    required this.createdDate,
    this.syncStatus = SyncStatusOffline.pending,
    int? updatedAt,
  })  : uuid = uuid ?? const Uuid().v4(),
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  factory TaskOfflineEntity.fromMap(Map<String, dynamic> map) {
    return TaskOfflineEntity(
      localId: map['localId'],
      uuid: map['uuid'],
      serverId: map['serverId'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      createdDate: map['createdDate'],
      syncStatus: map['syncStatus'],
      updatedAt: map['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid, // ✅ REQUIRED
      'serverId': serverId,
      'title': title,
      'description': description,
      'status': status,
      'createdDate': createdDate,
      'syncStatus': syncStatus,
      'updatedAt': updatedAt,
    };
  }
}
