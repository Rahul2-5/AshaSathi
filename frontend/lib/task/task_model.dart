enum TaskStatus { urgent, pending, inProgress, completed }

class TaskModel {
  final int? id;
  final String title;
  final String description;
  final TaskStatus status;

  TaskModel({
    this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  // ---------- FROM BACKEND ----------
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: _fromBackendStatus(json['status']),
    );
  }

  // ---------- TO BACKEND ----------
  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "description": description,
      "status": _toBackendStatus(status),
    };
  }

  // 🔥 ENUM → BACKEND STRING (FIXED)
  static String _toBackendStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.urgent:
        return "URGENT";
      case TaskStatus.pending:
        return "PENDING";
      case TaskStatus.inProgress:
        return "IN_PROGRESS"; // ✅ IMPORTANT FIX
      case TaskStatus.completed:
        return "COMPLETED";
    }
  }

  // 🔥 BACKEND STRING → ENUM (ALREADY CORRECT)
  static TaskStatus _fromBackendStatus(String value) {
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
