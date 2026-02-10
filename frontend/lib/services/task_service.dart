import 'dart:convert';
import 'package:http/http.dart' as http;

import '../task/task_model.dart';
import '../offline/connectivity_service.dart';
import '../offline/task_offline_dao.dart';
import '../offline/task_offline_entity.dart';

class TaskService {
  final String baseUrl = "http://10.0.2.2:8080/api/tasks";

  final ConnectivityService _connectivity = ConnectivityService();
  final TaskOfflineDao _offlineDao = TaskOfflineDao();

  // ================= FETCH TASKS =================
 Future<List<TaskModel>> fetchTodayTasks(String token) async {
  final isOnline = await _connectivity.isOnline();

  // 🔴 Load OFFLINE tasks first
  final offlineTasks = await _offlineDao.getPending();

  final offlineModels = offlineTasks.map((t) {
    return TaskModel(
      id: t.serverId ?? -1, // temp ID
      title: t.title,
      description: t.description ?? "",
      status: TaskStatus.values.firstWhere(
        (e) => e.name == t.status,
      ),
    );
  }).toList();

  // 🔴 If offline → return only offline
  if (!isOnline) {
    return offlineModels;
  }

  // 🟢 ONLINE → fetch backend tasks
  final response = await http.get(
    Uri.parse("$baseUrl/today"),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  if (response.statusCode != 200) {
    return offlineModels; // fallback
  }

  final List list = jsonDecode(response.body);
  final onlineTasks =
      list.map((e) => TaskModel.fromJson(e)).toList();

  // ✅ MERGE offline + online
  return [...offlineModels, ...onlineTasks];
}


  // ================= ADD TASK =================
  Future<void> addTask(TaskModel task, String token) async {
    final isOnline = await _connectivity.isOnline();

    // 🔴 OFFLINE
    if (!isOnline) {
      await _offlineDao.insert(
        TaskOfflineEntity(
          title: task.title,
          description: task.description,
          status: task.status.name.toUpperCase(), // ✅ FIX
          createdDate: DateTime.now().toIso8601String(),
        ),
      );
      return;
    }

    // 🟢 ONLINE
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(task.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to add task");
    }
  }

  // ================= DELETE TASK =================
  Future<void> deleteTask(int id, String token) async {
    final isOnline = await _connectivity.isOnline();

    if (!isOnline) {
      throw Exception("Cannot delete task while offline");
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 204) {
      throw Exception("Failed to delete task");
    }
  }

  // ================= STATUS MAPPER =================
  TaskStatus _offlineStatusToEnum(String value) {
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
}
