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

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: _fromString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "description": description,
      "status": status.name.toUpperCase(),
    };
  }

  static TaskStatus _fromString(String value) {
    switch (value) {
      case "URGENT":
        return TaskStatus.urgent;
      case "IN_PROGRESS":
        return TaskStatus.inProgress;
      case "COMPLETED":
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
    }
  }
}
