import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'connectivity_service.dart';

class FamilySyncService {
  final ConnectivityService _connectivity = ConnectivityService();
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Get count of pending families waiting to sync
  Future<int> getPendingFamilyCount() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('pending_family_registrations_v1');
    if (json == null) return 0;

    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.length;
    } catch (e) {
      debugPrint('[FamilySync] Error counting pending families: $e');
      return 0;
    }
  }

  /// Sync pending families to backend (retry all pending)
  Future<int> syncPendingFamilies(String token) async {
    final isOnline = await _connectivity.isOnline();
    if (!isOnline) {
      debugPrint('[FamilySync] Offline: skipping family sync');
      return 0;
    }

    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('pending_family_registrations_v1');
    if (json == null) return 0;

    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      if (decoded.isEmpty) return 0;

      int successCount = 0;
      final failedIndices = <int>[];

      debugPrint('[FamilySync] Syncing ${decoded.length} pending families...');

      for (int i = 0; i < decoded.length; i++) {
        final family = decoded[i] as Map<String, dynamic>;
        
        try {
          final response = await http.post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/families'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'familyInfo': family['familyInfo'],
              'patients': family['patients'],
            }),
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200 || response.statusCode == 201) {
            debugPrint('[FamilySync] Successfully synced family at index $i');
            successCount++;
          } else {
            debugPrint(
              '[FamilySync] Failed to sync family at index $i: ${response.statusCode}',
            );
            failedIndices.add(i);
          }
        } catch (e) {
          debugPrint('[FamilySync] Error syncing family at index $i: $e');
          failedIndices.add(i);
        }
      }

      // Remove successfully synced families from pending list
      if (successCount > 0) {
        final remaining = <dynamic>[];
        for (int i = 0; i < decoded.length; i++) {
          if (!failedIndices.contains(i)) {
            remaining.add(decoded[i]);
          }
        }
        await prefs.setString(
          'pending_family_registrations_v1',
          jsonEncode(remaining),
        );
        debugPrint('[FamilySync] Synced $successCount families successfully');
      }

      return successCount;
    } catch (e) {
      debugPrint('[FamilySync] Error during family sync: $e');
      return 0;
    }
  }

  /// Clear all pending families (usually after bulk sync)
  Future<void> clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_family_registrations_v1');
    debugPrint('[FamilySync] Cleared all pending families');
  }
}
