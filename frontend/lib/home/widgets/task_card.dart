import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/cubit/login_cubit.dart';
import '../../task/task_cubit.dart';
import '../../task/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;

  const TaskCard({super.key, required this.task});

  Color _statusColor() {
    switch (task.status) {
      case TaskStatus.urgent:
        return Colors.red;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.inProgress:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // 📌 ICON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment, color: Colors.teal),
          ),
          const SizedBox(width: 12),

          // 📄 TITLE + DESCRIPTION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // 🏷️ STATUS CHIP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              task.status.name.toUpperCase(),
              style: TextStyle(
                color: _statusColor(),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 🗑️ DELETE BUTTON
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Delete Task"),
                  content: const Text(
                    "Are you sure you want to delete this task?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final token =
                    context.read<LoginCubit>().state.token!;

                try {
                  final deleted = await context
                      .read<TaskCubit>()
                      .deleteTaskWithUuid(task.id ?? -1, task.uuid, token);

                  if (!context.mounted) return;
                  
                  if (deleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Task deleted successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Task marked for deletion (will sync later)"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error deleting task: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
