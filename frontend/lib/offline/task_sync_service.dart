import 'dart:convert';
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

    final pendingTasks = await _dao.getPending();
    if (pendingTasks.isEmpty) return false;

    for (final task in pendingTasks) {
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
      }
    }

    return true;
  }
}
