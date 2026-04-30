import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'connectivity_service.dart';
import 'family_offline_service.dart';

class FamilySyncService {
  final ConnectivityService _connectivity = ConnectivityService();
  final FamilyOfflineService _offlineService = FamilyOfflineService();

  Future<int> getPendingFamilyCount() async {
    final pending = await _offlineService.getPendingFamilies();
    return pending.length;
  }

  Future<int> syncPendingFamilies(String token) async {
    final isOnline = await _connectivity.isOnline();
    if (!isOnline) {
      debugPrint('[FamilySync] Offline: skipping family sync');
      return 0;
    }

    final pending = await _offlineService.getPendingFamilies();
    if (pending.isEmpty) return 0;

    var successCount = 0;
    final remaining = <Map<String, dynamic>>[];

    for (final family in pending) {
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
          successCount++;
          continue;
        }

        remaining.add({
          ...family,
          'lastError': 'HTTP ${response.statusCode}',
          'syncAttempts': ((family['syncAttempts'] as num?)?.toInt() ?? 0) + 1,
        });
      } catch (e) {
        remaining.add({
          ...family,
          'lastError': e.toString(),
          'syncAttempts': ((family['syncAttempts'] as num?)?.toInt() ?? 0) + 1,
        });
      }
    }

    if (successCount > 0) {
      await _offlineService.replacePendingFamilies(remaining);
    }

    return successCount;
  }

  Future<void> clearPending() async {
    await _offlineService.clearPending();
  }
}
