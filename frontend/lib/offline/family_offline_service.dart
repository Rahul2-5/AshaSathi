import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_database_offline.dart';

class FamilyOfflineService {
  Future<void> saveFamilyOffline({
    required Map<String, dynamic> familyInfo,
    required List<Map<String, dynamic>> patients,
  }) async {
    final db = await AppDatabaseOffline().database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = {
      'familyInfo': familyInfo,
      'patients': patients,
      'createdAt': now,
      'syncAttempts': 0,
      'lastError': null,
    };

    await db.insert(AppDatabaseOffline.pendingFamilyTable, {
      'payload': jsonEncode(payload),
      'createdAt': now,
      'syncAttempts': 0,
      'lastError': null,
    });
    debugPrint('[FamilyOfflineService] Saved family offline in SQLite');
  }

  Future<List<Map<String, dynamic>>> getPendingFamilies() async {
    final db = await AppDatabaseOffline().database;
    final rows = await db.query(
      AppDatabaseOffline.pendingFamilyTable,
      orderBy: 'createdAt ASC, localId ASC',
    );

    return rows.map((row) {
      final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      payload['localId'] = row['localId'];
      payload['syncAttempts'] = row['syncAttempts'];
      payload['lastError'] = row['lastError'];
      return payload;
    }).toList();
  }

  Future<void> replacePendingFamilies(List<Map<String, dynamic>> families) async {
    final db = await AppDatabaseOffline().database;
    await db.transaction((txn) async {
      await txn.delete(AppDatabaseOffline.pendingFamilyTable);
      for (final family in families) {
        final createdAt = (family['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch;
        await txn.insert(AppDatabaseOffline.pendingFamilyTable, {
          'payload': jsonEncode({
            'familyInfo': family['familyInfo'],
            'patients': family['patients'],
            'createdAt': createdAt,
            'syncAttempts': family['syncAttempts'] ?? 0,
            'lastError': family['lastError'],
          }),
          'createdAt': createdAt,
          'syncAttempts': (family['syncAttempts'] as num?)?.toInt() ?? 0,
          'lastError': family['lastError']?.toString(),
        });
      }
    });
  }

  Future<void> markFamilySynced(int index) async {
    final rows = await _orderedRows();
    if (index < 0 || index >= rows.length) return;

    final db = await AppDatabaseOffline().database;
    await db.delete(
      AppDatabaseOffline.pendingFamilyTable,
      where: 'localId = ?',
      whereArgs: [rows[index]['localId']],
    );
  }

  Future<void> updateSyncError({
    required int index,
    required String error,
  }) async {
    final rows = await _orderedRows();
    if (index < 0 || index >= rows.length) return;

    final row = rows[index];
    final attempts = ((row['syncAttempts'] as num?)?.toInt() ?? 0) + 1;
    final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    payload['lastError'] = error;
    payload['syncAttempts'] = attempts;

    final db = await AppDatabaseOffline().database;
    await db.update(
      AppDatabaseOffline.pendingFamilyTable,
      {
        'payload': jsonEncode(payload),
        'syncAttempts': attempts,
        'lastError': error,
      },
      where: 'localId = ?',
      whereArgs: [row['localId']],
    );
  }

  Future<void> clearPending() async {
    final db = await AppDatabaseOffline().database;
    await db.delete(AppDatabaseOffline.pendingFamilyTable);
  }

  Future<List<Map<String, Object?>>> _orderedRows() async {
    final db = await AppDatabaseOffline().database;
    return db.query(
      AppDatabaseOffline.pendingFamilyTable,
      orderBy: 'createdAt ASC, localId ASC',
    );
  }
}
