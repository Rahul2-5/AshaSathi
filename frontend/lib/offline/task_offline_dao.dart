import 'package:sqflite/sqflite.dart';
import 'app_database_offline.dart';
import 'task_offline_entity.dart';
import 'sync_status_offline.dart';

class TaskOfflineDao {
  final AppDatabaseOffline _db = AppDatabaseOffline();

  Future<int> insert(TaskOfflineEntity task) async {
  final db = await _db.database;
  return await db.insert(
    AppDatabaseOffline.taskTable,
    task.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}


  Future<List<TaskOfflineEntity>> getPending() async {
    final db = await _db.database;
    final result = await db.query(
      AppDatabaseOffline.taskTable,
      where: 'syncStatus = ?',
      whereArgs: [SyncStatusOffline.pending],
    );

    return result.map(TaskOfflineEntity.fromMap).toList();
  }

  Future<List<TaskOfflineEntity>> getAllActive() async {
    final db = await _db.database;
    final result = await db.query(
      AppDatabaseOffline.taskTable,
      where: 'syncStatus != ?',
      whereArgs: [SyncStatusOffline.deleted],
      orderBy: 'updatedAt DESC',
    );

    return result.map(TaskOfflineEntity.fromMap).toList();
  }

  Future<void> markSynced({
    required int localId,
    required int serverId,
  }) async {
    final db = await _db.database;
    await db.update(
      AppDatabaseOffline.taskTable,
      {
        'syncStatus': SyncStatusOffline.synced,
        'serverId': serverId,
      },
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  /// Mark task for deletion (offline deletion)
  Future<void> markDeletedByUuid(String uuid) async {
    final db = await _db.database;
    await db.update(
      AppDatabaseOffline.taskTable,
      {
        'syncStatus': SyncStatusOffline.deleted,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// Hard delete task from offline storage (used when deleted online)
  Future<void> hardDeleteByUuid(String uuid) async {
    final db = await _db.database;
    await db.delete(
      AppDatabaseOffline.taskTable,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// Get deleted tasks for sync
  Future<List<TaskOfflineEntity>> getDeleted() async {
    final db = await _db.database;
    final result = await db.query(
      AppDatabaseOffline.taskTable,
      where: 'syncStatus = ?',
      whereArgs: [SyncStatusOffline.deleted],
    );

    return result.map(TaskOfflineEntity.fromMap).toList();
  }
}
