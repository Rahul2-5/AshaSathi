import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FamilyOfflineService {
  static const String _pendingFamiliesKey = 'pending_family_registrations_v1';

  /// Save a family and its members offline for later sync
  Future<void> saveFamilyOffline({
    required Map<String, dynamic> familyInfo,
    required List<Map<String, dynamic>> patients,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load existing pending families
    final existingJson = prefs.getString(_pendingFamiliesKey);
    final List<dynamic> pendingFamilies = existingJson != null 
        ? jsonDecode(existingJson) as List<dynamic>
        : [];

    // Create new pending family entry
    final newEntry = {
      'familyInfo': familyInfo,
      'patients': patients,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'syncAttempts': 0,
      'lastError': null,
    };

    pendingFamilies.add(newEntry);

    // Save back to SharedPreferences
    await prefs.setString(_pendingFamiliesKey, jsonEncode(pendingFamilies));
    debugPrint('[FamilyOfflineService] Saved family offline for pending sync');
  }

  /// Get all pending families that need to be synced
  Future<List<Map<String, dynamic>>> getPendingFamilies() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_pendingFamiliesKey);
    if (json == null) return [];

    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return List<Map<String, dynamic>>.from(decoded);
    } catch (e) {
      debugPrint('[FamilyOfflineService] Error parsing pending families: $e');
      return [];
    }
  }

  /// Mark a pending family as synced and remove from pending list
  Future<void> markFamilySynced(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_pendingFamiliesKey);
    if (json == null) return;

    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      decoded.removeAt(index);
      await prefs.setString(_pendingFamiliesKey, jsonEncode(decoded));
      debugPrint('[FamilyOfflineService] Marked family at index $index as synced');
    } catch (e) {
      debugPrint('[FamilyOfflineService] Error marking family as synced: $e');
    }
  }

  /// Update sync error for a pending family
  Future<void> updateSyncError({
    required int index,
    required String error,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_pendingFamiliesKey);
    if (json == null) return;

    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      if (index < decoded.length) {
        final family = decoded[index] as Map<String, dynamic>;
        family['lastError'] = error;
        family['syncAttempts'] = (family['syncAttempts'] ?? 0) + 1;
        await prefs.setString(_pendingFamiliesKey, jsonEncode(decoded));
        debugPrint('[FamilyOfflineService] Updated sync error for family at index $index');
      }
    } catch (e) {
      debugPrint('[FamilyOfflineService] Error updating sync error: $e');
    }
  }

  /// Clear all pending families (usually after successful team sync)
  Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingFamiliesKey);
    debugPrint('[FamilyOfflineService] Cleared all pending families');
  }
}
