import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/auth/cubit/login_cubit.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:uuid/uuid.dart';
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

  static const Color _primaryTeal = Color(0xFF14A7A0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final textColor = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F252B);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: textColor,
        centerTitle: true,
        title: Text(
          l10n.tr('task.addNewTask'),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr('task.createNewTask'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              l10n.tr('task.taskTitle'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              style: TextStyle(fontSize: 16, color: textColor),
              decoration: _fieldDecoration(l10n.tr('task.taskTitleHint'), isDark),
            ),

            const SizedBox(height: 18),

            Text(
              l10n.tr('task.taskDescription'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              maxLines: 4,
              style: TextStyle(fontSize: 16, color: textColor),
              decoration: _fieldDecoration(l10n.tr('task.taskDescriptionHint'), isDark),
            ),

            const SizedBox(height: 18),

            Text(
              l10n.tr('task.status'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: TaskStatus.values.map((s) {
                final isSelected = status == s;
                return ChoiceChip(
                  showCheckmark: isSelected,
                  label: Text(_statusText(context, s)),
                  selected: isSelected,
                  selectedColor: _chipSelectedColor(s),
                  backgroundColor:
                      isDark ? const Color(0xFF1A232C) : Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? _chipSelectedColor(s)
                        : (isDark
                            ? const Color(0xFF32414E)
                            : const Color(0xFFD4DAE0)),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFFC8D4DE)
                            : const Color(0xFF3A434C)),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
                  elevation: 0,
                  backgroundColor: _primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.tr('task.pleaseEnterTitle')),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final token = context.read<LoginCubit>().state.token!;
                  final uuid = const Uuid().v4();

                  final task = TaskModel(
                    uuid: uuid,
                    title: titleController.text.trim(),
                    description: descController.text.trim(),
                    status: status,
                  );

                  try {
                    await context.read<TaskCubit>().addTask(task, token);
                    
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.tr('task.addedSuccessfully')),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context, true);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(
                  l10n.tr('task.saveTask'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF98A6B3) : const Color(0xFF8D959E),
        fontSize: 14,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1A232C) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF32414E) : const Color(0xFFD9DEE3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryTeal, width: 1.4),
      ),
    );
  }

  Color _chipSelectedColor(TaskStatus value) {
    switch (value) {
      case TaskStatus.urgent:
        return const Color(0xFFE95A5A);
      case TaskStatus.pending:
        return _primaryTeal;
      case TaskStatus.inProgress:
        return const Color(0xFFE39A20);
      case TaskStatus.completed:
        return const Color(0xFF56B978);
    }
  }

  String _statusText(BuildContext context, TaskStatus status) {
    switch (status) {
      case TaskStatus.urgent:
        return context.l10n.tr('task.urgent');
      case TaskStatus.pending:
        return context.l10n.tr('task.pending');
      case TaskStatus.inProgress:
        return context.l10n.tr('task.inProgress');
      case TaskStatus.completed:
        return context.l10n.tr('task.completed');
    }
  }
}
