import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'task_offline_dao.dart';
import 'connectivity_service.dart';

class TaskSyncService {
  final TaskOfflineDao _dao = TaskOfflineDao();
  final ConnectivityService _connectivity = ConnectivityService();

  static const String baseUrl = "http://10.0.2.2:8080/api/tasks";

  /// Returns true ONLY if real sync happened
  Future<bool> sync(String token) async {
    if (!await _connectivity.isOnline()) return false;

    // 🔹 SYNC PENDING TASKS
    final pendingTasks = await _dao.getPending();
    debugPrint("Syncing ${pendingTasks.length} pending tasks");

    for (final task in pendingTasks) {
      try {
        final response = await http.post(
          Uri.parse(baseUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "title": task.title,
            "description": task.description ?? "",
            "status": task.status,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final serverId = jsonDecode(response.body)["id"];

          await _dao.markSynced(
            localId: task.localId!,
            serverId: serverId,
          );
          debugPrint("Task ${task.localId} synced with server ID: $serverId");
        }
      } catch (e) {
        debugPrint("Error syncing task ${task.localId}: $e");
      }
    }

    // 🔹 SYNC DELETED TASKS
    final deletedTasks = await _dao.getDeleted();
    debugPrint("Syncing ${deletedTasks.length} deleted tasks");

    for (final task in deletedTasks) {
      if (task.serverId == null) continue; // Skip if never synced to server

      try {
        final response = await http.delete(
          Uri.parse("$baseUrl/${task.serverId}"),
          headers: {"Authorization": "Bearer $token"},
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          // Hard delete from local storage after successful deletion on backend
          await _dao.hardDeleteByUuid(task.uuid);
          debugPrint("Task ${task.uuid} deleted from server");
        }
      } catch (e) {
        debugPrint("Error deleting task ${task.uuid}: $e");
      }
    }

    return true;
  }
}
