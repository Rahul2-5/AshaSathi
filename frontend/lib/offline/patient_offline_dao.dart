
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

import 'app_database_offline.dart';
import 'patient_offline_entity.dart';
import 'sync_status_offline.dart';

class PatientOfflineDao {
  final AppDatabaseOffline _db = AppDatabaseOffline();

  /// INSERT OR UPDATE
  Future<void> upsert(PatientOfflineEntity patient) async {
    final db = await _db.database;

    final payload = {
      ...patient.toMap(),
      'syncStatus': SyncStatusOffline.pending,
      'lastError': null,
      'conflictServerPayload': null,
    };

    if (patient.localId == null) {
      await db.insert('patients', payload);
    } else {
      await db.update(
        'patients',
        payload,
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
      'retryCount': 0,
      'lastError': null,
      'conflictServerPayload': null,
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

  Future<List<PatientOfflineEntity>> getConflicts() async {
    final db = await _db.database;
    final result = await db.query(
      'patients',
      where: 'syncStatus = ?',
      whereArgs: [SyncStatusOffline.conflict],
      orderBy: 'updatedAt DESC',
    );

    return result.map(PatientOfflineEntity.fromMap).toList();
  }

  Future<PatientOfflineEntity?> getByLocalId(int localId) async {
    final db = await _db.database;
    final result = await db.query(
      'patients',
      where: 'localId = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return PatientOfflineEntity.fromMap(result.first);
  }

  Future<int> getPendingCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM patients WHERE syncStatus = ?',
      [SyncStatusOffline.pending],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<int> getDeletedCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM patients WHERE syncStatus = ?',
      [SyncStatusOffline.deleted],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<int> getConflictCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM patients WHERE syncStatus = ?',
      [SyncStatusOffline.conflict],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<int> getRetryQueueCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM patients WHERE retryCount > 0 AND syncStatus != ?',
      [SyncStatusOffline.synced],
    );
    return (result.first['c'] as int?) ?? 0;
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
    String? baseHash,
  }) async {
    final db = await _db.database;
    await db.update(
      'patients',
      {
        'syncStatus': SyncStatusOffline.synced,
        'serverId': serverId,
        'updatedAt': updatedAt,
        'retryCount': 0,
        'lastError': null,
        'baseHash': baseHash,
        'conflictServerPayload': null,
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
        'lastError': null,
        'conflictServerPayload': null,
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

  Future<void> updateDescriptionByUuid({
    required String uuid,
    required String description,
  }) async {
    final db = await _db.database;
    await db.update(
      'patients',
      {
        'description': description,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'syncStatus': SyncStatusOffline.pending,
        'lastError': null,
        'conflictServerPayload': null,
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<void> updatePatientByUuid({
    required String uuid,
    required String name,
    required String gender,
    required int age,
    required String dateOfBirth,
    required String address,
    required String phoneNumber,
    required String description,
    bool markPending = true,
    int? serverId,
  }) async {
    final db = await _db.database;
    final nextSyncStatus = markPending ? SyncStatusOffline.pending : SyncStatusOffline.synced;

    final baseHash = [
      name.trim().toLowerCase(),
      gender.trim().toLowerCase(),
      age.toString(),
      dateOfBirth.trim(),
      address.trim().toLowerCase(),
      phoneNumber.replaceAll(RegExp(r'\D'), ''),
      description.trim().toLowerCase(),
    ].join('|');

    await db.update(
      'patients',
      {
        if (serverId != null) 'serverId': serverId,
        'name': name,
        'gender': gender,
        'age': age,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'phoneNumber': phoneNumber,
        'description': description,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'syncStatus': nextSyncStatus,
        'lastError': null,
        'conflictServerPayload': null,
        if (!markPending) 'retryCount': 0,
        if (!markPending) 'baseHash': baseHash,
      },
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
  }

  Future<void> markRetryFailure({
    required int localId,
    required String error,
  }) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE patients SET retryCount = retryCount + 1, lastError = ?, updatedAt = ? WHERE localId = ?',
      [error, DateTime.now().millisecondsSinceEpoch, localId],
    );
  }

  Future<void> markConflict({
    required int localId,
    required Map<String, dynamic> serverPayload,
    required String reason,
  }) async {
    final db = await _db.database;
    await db.update(
      'patients',
      {
        'syncStatus': SyncStatusOffline.conflict,
        'conflictServerPayload': jsonEncode(serverPayload),
        'lastError': reason,
        'retryCount': 0,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  Future<void> resolveConflictKeepServer({
    required int localId,
    required int serverId,
    required String name,
    required String gender,
    required int age,
    required String dateOfBirth,
    required String address,
    required String phoneNumber,
    required String description,
    required String? photoPath,
    required String baseHash,
  }) async {
    final db = await _db.database;
    await db.update(
      'patients',
      {
        'serverId': serverId,
        'name': name,
        'gender': gender,
        'age': age,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'phoneNumber': phoneNumber,
        'description': description,
        'photoPath': photoPath,
        'syncStatus': SyncStatusOffline.synced,
        'retryCount': 0,
        'lastError': null,
        'baseHash': baseHash,
        'conflictServerPayload': null,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  Future<void> clearConflictAndSetPending(int localId) async {
    final db = await _db.database;
    await db.update(
      'patients',
      {
        'syncStatus': SyncStatusOffline.pending,
        'lastError': null,
        'conflictServerPayload': null,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }
}

