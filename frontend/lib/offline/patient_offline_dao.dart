
import 'package:sqflite/sqflite.dart';

import 'app_database_offline.dart';
import 'patient_offline_entity.dart';
import 'sync_status_offline.dart';

class PatientOfflineDao {
  final AppDatabaseOffline _db = AppDatabaseOffline();

  /// INSERT OR UPDATE
  Future<void> upsert(PatientOfflineEntity patient) async {
    final db = await _db.database;

    if (patient.localId == null) {
      await db.insert('patients', patient.toMap());
    } else {
      await db.update(
        'patients',
        patient.toMap(),
        where: 'localId = ?',
        whereArgs: [patient.localId],
      );
    }
  }

  Future<void> upsertSynced(PatientOfflineEntity patient) async {
    final db = await _db.database;

    Map<String, dynamic>? existing;

    if (patient.serverId != null) {
      final byServerId = await db.query(
        'patients',
        where: 'serverId = ?',
        whereArgs: [patient.serverId],
        limit: 1,
      );
      if (byServerId.isNotEmpty) {
        existing = byServerId.first;
      }
    }

    if (existing == null) {
      final byUuid = await db.query(
        'patients',
        where: 'uuid = ?',
        whereArgs: [patient.uuid],
        limit: 1,
      );
      if (byUuid.isNotEmpty) {
        existing = byUuid.first;
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = {
      ...patient.toMap(),
      'syncStatus': SyncStatusOffline.synced,
      'updatedAt': now,
    };

    if (existing == null) {
      await db.insert(
        'patients',
        payload,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return;
    }

    await db.update(
      'patients',
      payload,
      where: 'localId = ?',
      whereArgs: [existing['localId']],
    );
  }

  ///  REQUIRED FOR UI (offline-first)
  Future<List<PatientOfflineEntity>> getAll() async {
    final db = await _db.database;

    final result = await db.query(
      'patients',
      where: 'syncStatus != ?',
      whereArgs: [SyncStatusOffline.deleted],
      orderBy: 'updatedAt DESC',
    );

    return result.map(PatientOfflineEntity.fromMap).toList();
  }

  Future<List<PatientOfflineEntity>> getPending() async {
    final db = await _db.database;
    final result = await db.query(
      'patients',
      where: 'syncStatus = ?',
      whereArgs: [SyncStatusOffline.pending],
      orderBy: 'updatedAt ASC',
    );

    return result.map(PatientOfflineEntity.fromMap).toList();
  }

  /// Counts only truly unsynced records.
  /// If a row already has serverId, it is considered synced/recoverable.
  Future<int> getUnsyncedCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM patients WHERE syncStatus = ? AND serverId IS NULL',
      [SyncStatusOffline.pending],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  /// Repairs stale rows where serverId exists but syncStatus remained pending.
  Future<void> reconcilePendingWithServerId() async {
    final db = await _db.database;
    await db.update(
      'patients',
      {
        'syncStatus': SyncStatusOffline.synced,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'syncStatus = ? AND serverId IS NOT NULL',
      whereArgs: [SyncStatusOffline.pending],
    );
  }

  Future<List<PatientOfflineEntity>> getDeleted() async {
    final db = await _db.database;
    final result = await db.query(
      'patients',
      where: 'syncStatus = ?',
      whereArgs: [SyncStatusOffline.deleted],
    );

    return result.map(PatientOfflineEntity.fromMap).toList();
  }

  Future<void> markSynced({
    required int localId,
    required int serverId,
    required int updatedAt,
  }) async {
    final db = await _db.database;
    await db.update(
      'patients',
      {
        'syncStatus': SyncStatusOffline.synced,
        'serverId': serverId,
        'updatedAt': updatedAt,
      },
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  Future<void> markDeleted(int localId) async {
    final db = await _db.database;
    await db.update(
      'patients',
      {'syncStatus': SyncStatusOffline.deleted},
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  Future<void> markDeletedByUuid(String uuid) async {
    final db = await _db.database;
    await db.update(
      'patients',
      {
        'syncStatus': SyncStatusOffline.deleted,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  /// Hard delete patient from offline storage (used when deleted online)
  Future<void> hardDeleteByUuid(String uuid) async {
    final db = await _db.database;
    await db.delete(
      'patients',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }
}

