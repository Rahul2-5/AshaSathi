import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../patient/family_model.dart';
import 'app_database_offline.dart';

class FamilyCacheService {
  Future<void> saveFamilies(List<FamilyRecord> families) async {
    final db = await AppDatabaseOffline().database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      await txn.delete(AppDatabaseOffline.cachedFamilyTable);
      for (final family in families) {
        await txn.insert(AppDatabaseOffline.cachedFamilyTable, {
          'familyId': family.id,
          'payload': jsonEncode(family.toJson()),
          'updatedAt': now,
        });
      }
    });
  }

  Future<void> upsertFamily(FamilyRecord family) async {
    final db = await AppDatabaseOffline().database;
    await db.insert(
      AppDatabaseOffline.cachedFamilyTable,
      {
        'familyId': family.id,
        'payload': jsonEncode(family.toJson()),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFamilyById(int familyId) async {
    final db = await AppDatabaseOffline().database;
    await db.delete(
      AppDatabaseOffline.cachedFamilyTable,
      where: 'familyId = ?',
      whereArgs: [familyId],
    );
  }

  Future<List<FamilyRecord>> loadFamilies() async {
    final db = await AppDatabaseOffline().database;
    final rows = await db.query(
      AppDatabaseOffline.cachedFamilyTable,
      orderBy: 'updatedAt DESC',
    );

    return rows.map((row) {
      final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
      return FamilyRecord.fromJson(payload);
    }).toList();
  }

  Future<void> clear() async {
    final db = await AppDatabaseOffline().database;
    await db.delete(AppDatabaseOffline.cachedFamilyTable);
  }
}
