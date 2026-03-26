import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../task/task_model.dart';
import '../offline/connectivity_service.dart';
import '../offline/task_offline_dao.dart';
import '../offline/task_offline_entity.dart';

class TaskService {
  final String baseUrl = AppConfig.tasksBaseUrl;

  final ConnectivityService _connectivity = ConnectivityService();
  final TaskOfflineDao _offlineDao = TaskOfflineDao();

  // ================= FETCH TASKS =================
  Future<List<TaskModel>> fetchTodayTasks(String token) async {
    final isOnline = await _connectivity.isOnline();

    // Load local non-deleted tasks first so we can merge unsynced local data.
    final offlineTasks = await _offlineDao.getAllActive();
    debugPrint("Loaded ${offlineTasks.length} local active tasks");

    final offlineModels = offlineTasks.map((t) {
      return TaskModel(
        id: t.serverId,
        uuid: t.uuid,
        title: t.title,
        description: t.description ?? "",
        status: _stringToStatus(t.status),
      );
    }).toList();

    // 🔴 If offline → return only offline
    if (!isOnline) {
      debugPrint("Offline mode: returning ${offlineModels.length} local tasks");
      return offlineModels;
    }

    // 🟢 ONLINE → fetch backend tasks
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/today"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode != 200) {
        debugPrint("Backend fetch failed (${response.statusCode}), returning offline tasks");
        return offlineModels;
      }

      final List list = jsonDecode(response.body);
      final onlineTasks = list.map((e) => TaskModel.fromJson(e)).toList();
      debugPrint("Loaded ${onlineTasks.length} tasks from backend");

      for (final onlineTask in onlineTasks) {
        await _offlineDao.upsertSynced(
          TaskOfflineEntity(
            uuid: onlineTask.uuid,
            serverId: onlineTask.id,
            title: onlineTask.title,
            description: onlineTask.description,
            status: _statusToString(onlineTask.status),
            createdDate: DateTime.now().toIso8601String(),
          ),
        );
      }

      // Keep unsynced local tasks visible while still showing backend source of truth.
      final unsyncedLocal =
          offlineModels.where((task) => task.id == null).toList();
      if (unsyncedLocal.isEmpty) {
        return onlineTasks;
      }

      final onlineKeys = onlineTasks.map(_taskKey).toSet();
      final merged = <TaskModel>[...onlineTasks];

      for (final localTask in unsyncedLocal) {
        final key = _taskKey(localTask);
        if (!onlineKeys.contains(key)) {
          merged.insert(0, localTask);
        }
      }

      debugPrint(
        "Merged ${unsyncedLocal.length} unsynced local tasks with backend list",
      );
      return merged;
    } catch (e) {
      debugPrint("Error fetching from backend: $e");
      return offlineModels;
    }
  }

  // ================= ADD TASK =================
  Future<void> addTask(TaskModel task, String token) async {
    final isOnline = await _connectivity.isOnline();
    final uuid = task.uuid.isNotEmpty ? task.uuid : const Uuid().v4();

    debugPrint("Adding task: online=$isOnline");

    // 🔴 OFFLINE → save to local storage
    if (!isOnline) {
      debugPrint("Saving task offline with UUID: $uuid");
      try {
        await _offlineDao.insert(
          TaskOfflineEntity(
            uuid: uuid,
            title: task.title,
            description: task.description,
            status: _statusToString(task.status),
            createdDate: DateTime.now().toIso8601String(),
          ),
        );
        debugPrint("Task saved offline successfully");
      } catch (e) {
        debugPrint("Error saving offline: $e");
        rethrow;
      }
      return;
    }

    // 🟢 ONLINE → send to backend
    try {
      debugPrint("Sending task to backend...");
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(task.toJson()),
      );

      debugPrint("Task creation response: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Task created successfully on backend");

        int? serverId;
        try {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic>) {
            serverId = (body['id'] as num?)?.toInt();
          }
        } catch (_) {
          serverId = null;
        }

        await _offlineDao.upsertSynced(
          TaskOfflineEntity(
            uuid: task.uuid,
            serverId: serverId,
            title: task.title,
            description: task.description,
            status: _statusToString(task.status),
            createdDate: DateTime.now().toIso8601String(),
          ),
        );
      } else {
        debugPrint("Backend returned ${response.statusCode}, falling back to offline");
        // Fallback: save offline if backend fails
        await _offlineDao.insert(
          TaskOfflineEntity(
            uuid: uuid,
            title: task.title,
            description: task.description,
            status: _statusToString(task.status),
            createdDate: DateTime.now().toIso8601String(),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error creating task online: $e, falling back to offline");
      // Fallback: save offline if network error
      await _offlineDao.insert(
        TaskOfflineEntity(
          uuid: uuid,
          title: task.title,
          description: task.description,
          status: _statusToString(task.status),
          createdDate: DateTime.now().toIso8601String(),
        ),
      );
    }
  }

  // ================= UPDATE TASK =================
  Future<void> updateTask(TaskModel task, String token) async {
    final isOnline = await _connectivity.isOnline();

    if (!isOnline) {
      await _offlineDao.markUpdatedByUuid(
        uuid: task.uuid,
        title: task.title,
        description: task.description,
        status: _statusToString(task.status),
      );
      return;
    }

    if (task.id == null) {
      await _offlineDao.markUpdatedByUuid(
        uuid: task.uuid,
        title: task.title,
        description: task.description,
        status: _statusToString(task.status),
      );
      return;
    }

    try {
      final response = await http.put(
        Uri.parse("$baseUrl/${task.id}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _offlineDao.upsertSynced(
          TaskOfflineEntity(
            uuid: task.uuid,
            serverId: task.id,
            title: task.title,
            description: task.description,
            status: _statusToString(task.status),
            createdDate: DateTime.now().toIso8601String(),
          ),
        );
      } else {
        await _offlineDao.markUpdatedByUuid(
          uuid: task.uuid,
          title: task.title,
          description: task.description,
          status: _statusToString(task.status),
        );
      }
    } catch (_) {
      await _offlineDao.markUpdatedByUuid(
        uuid: task.uuid,
        title: task.title,
        description: task.description,
        status: _statusToString(task.status),
      );
    }
  }

  // ================= DELETE TASK =================
  Future<bool> deleteTask(int taskId, String uuid, String token) async {
    final isOnline = await _connectivity.isOnline();

    debugPrint("Deleting task: id=$taskId, uuid=$uuid, online=$isOnline");

    // 📴 OFFLINE OR NO ID → mark for deletion locally
    if (!isOnline || taskId == -1) {
      debugPrint("Marking task for offline deletion");
      try {
        await _offlineDao.markDeletedByUuid(uuid);
        debugPrint("Task marked for deletion locally");
        return true;
      } catch (e) {
        debugPrint("Error marking task for deletion: $e");
        rethrow;
      }
    }

    // 🟢 ONLINE → try to delete from backend first
    try {
      debugPrint("Sending DELETE request to backend...");
      final response = await http.delete(
        Uri.parse("$baseUrl/$taskId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      debugPrint("Delete response status: ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Hard delete from offline storage
        debugPrint("Task deleted from backend, removing from offline storage");
        await _offlineDao.hardDeleteByUuid(uuid);
        return true;
      } else {
        debugPrint("Delete failed with status: ${response.statusCode}, marking for offline deletion");
        // Fallback: mark for deletion locally
        await _offlineDao.markDeletedByUuid(uuid);
        return false;
      }
    } catch (e) {
      debugPrint("Error deleting from backend: $e, falling back to offline");
      // Fallback: mark for deletion locally if network error
      await _offlineDao.markDeletedByUuid(uuid);
      return false;
    }
  }

  // ================= STATUS MAPPERS =================
  String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.urgent:
        return "URGENT";
      case TaskStatus.pending:
        return "PENDING";
      case TaskStatus.inProgress:
        return "IN_PROGRESS";
      case TaskStatus.completed:
        return "COMPLETED";
    }
  }

  TaskStatus _stringToStatus(String value) {
    switch (value) {
      case "URGENT":
        return TaskStatus.urgent;
      case "IN_PROGRESS":
        return TaskStatus.inProgress;
      case "COMPLETED":
        return TaskStatus.completed;
      case "PENDING":
      default:
        return TaskStatus.pending;
    }
  }

  String _taskKey(TaskModel task) {
    final uuid = task.uuid.trim();
    if (uuid.isNotEmpty && !RegExp(r'^\d+$').hasMatch(uuid)) {
      return "uuid:$uuid";
    }
    return "id:${task.id ?? -1}";
  }
}
