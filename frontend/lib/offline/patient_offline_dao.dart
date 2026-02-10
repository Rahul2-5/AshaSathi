
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

  /// ✅ REQUIRED FOR UI (offline-first)
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

