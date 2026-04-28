import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../patient/family_model.dart';

class FamilyCacheService {
  static const String _cachedFamiliesKey = 'cached_family_records_v1';

  Future<void> saveFamilies(List<FamilyRecord> families) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = families.map((family) => family.toJson()).toList();
    await prefs.setString(_cachedFamiliesKey, jsonEncode(payload));
  }

  Future<void> upsertFamily(FamilyRecord family) async {
    final families = await loadFamilies();
    final updatedFamilies = [
      ...families.where((existing) => existing.id != family.id),
      family,
    ];
    await saveFamilies(updatedFamilies);
  }

  Future<void> removeFamilyById(int familyId) async {
    final families = await loadFamilies();
    final updatedFamilies = families.where((family) => family.id != familyId).toList();
    await saveFamilies(updatedFamilies);
  }

  Future<List<FamilyRecord>> loadFamilies() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedFamiliesKey);
    if (raw == null || raw.trim().isEmpty) {
      return <FamilyRecord>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <FamilyRecord>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(FamilyRecord.fromJson)
          .toList();
    } catch (_) {
      return <FamilyRecord>[];
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedFamiliesKey);
  }
}