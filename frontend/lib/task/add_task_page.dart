import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/auth/cubit/login_cubit.dart';
import 'task_model.dart';
import 'task_cubit.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  TaskStatus status = TaskStatus.pending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Add New Task"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create New Task",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            const Text("Task Title", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: "e.g., Patient Follow-up",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Task Description", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describe the task...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Status", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              children: TaskStatus.values.map((s) {
                final isSelected = status == s;
                return ChoiceChip(
                  label: Text(_statusText(s)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF00A7A7),
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  onSelected: (_) => setState(() => status = s),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A7A7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final token = context.read<LoginCubit>().state.token!;

                  final task = TaskModel(
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    status: status,
                  );

                  await context.read<TaskCubit>().addTask(task, token);
                  Navigator.pop(context, true);
                },
                child: const Text(
                  "Save Task",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.urgent:
        return "Urgent";
      case TaskStatus.pending:
        return "Pending";
      case TaskStatus.inProgress:
        return "In Progress";
      case TaskStatus.completed:
        return "Completed";
    }
  }
}
