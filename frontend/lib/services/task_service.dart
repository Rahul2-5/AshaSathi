import 'dart:convert';
import 'package:http/http.dart' as http;
import '../task/task_model.dart';

class TaskService {
  final String baseUrl = "http://10.0.2.2:8080/api/tasks";

  Future<List<TaskModel>> fetchTodayTasks(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/today"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => TaskModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load tasks");
    }
  }

  Future<void> addTask(TaskModel task, String token) async {
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

Future<void> deleteTask(int id, String token) async {
  final response = await http.delete(
    Uri.parse("$baseUrl/$id"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  print("DELETE status: ${response.statusCode}");
  print("DELETE body: ${response.body}");

  if (response.statusCode != 204) {
    throw Exception("Failed to delete task");
  }
}



}
