import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'task_model.dart';
import 'task_cubit.dart';

class AddTaskPage extends StatefulWidget {
  final String token;
  const AddTaskPage({super.key, required this.token});

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
      appBar: AppBar(title: const Text("Add Task")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            DropdownButton<TaskStatus>(
              value: status,
              onChanged: (value) => setState(() => status = value!),
              items: TaskStatus.values.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(e.name.toUpperCase()),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final task = TaskModel(
                  title: titleController.text,
                  description: descController.text,
                  status: status,
                );

                await context.read<TaskCubit>().addTask(task, widget.token);
                Navigator.pop(context);
              },
              child: const Text("Save Task"),
            )
          ],
        ),
      ),
    );
  }
}
