import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/login_provider.dart';
import 'package:frontend/providers/task_provider.dart';
import 'package:frontend/widgets/common/common_widgets.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:uuid/uuid.dart';
import 'task_model.dart';

class AddTaskPage extends ConsumerStatefulWidget {
  final TaskModel? initialTask;

  const AddTaskPage({super.key, this.initialTask});

  @override
  ConsumerState<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends ConsumerState<AddTaskPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  TaskStatus status = TaskStatus.pending;
  bool _isSaving = false;

  bool get _isEditMode => widget.initialTask != null;

  static const Color _primaryTeal = Color(0xFF14A7A0);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTask;
    if (initial != null) {
      titleController.text = initial.title;
      descController.text = initial.description;
      status = initial.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final textColor = isDark
        ? const Color(0xFFE6EDF3)
        : const Color(0xFF1F252B);

    return GradientScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? l10n.tr('task.editTask') : l10n.tr('task.addNewTask'),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditMode
                          ? l10n.tr('task.updateTask')
                          : l10n.tr('task.createNewTask'),
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
                      decoration: _fieldDecoration(
                        context,
                        l10n.tr('task.taskTitleHint'),
                        isDark,
                      ),
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
                      decoration: _fieldDecoration(
                        context,
                        l10n.tr('task.taskDescriptionHint'),
                        isDark,
                      ),
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
                        return GlassChip(
                          label: _statusText(context, s),
                          selected: isSelected,
                          selectedColor: _chipSelectedColor(s),
                          onTap: () => setState(() => status = s),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    GlassButton(
                      label: _isEditMode
                          ? l10n.tr('task.updateTask')
                          : l10n.tr('task.saveTask'),
                      isLoading: _isSaving,
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (titleController.text.trim().isEmpty) {
                                showGlassSnackBar(
                                  context,
                                  l10n.tr('task.pleaseEnterTitle'),
                                  isError: true,
                                );
                                return;
                              }

                              final token = await ref
                                  .read(loginProvider.notifier)
                                  .getValidToken();
                              if (token == null || token.isEmpty) return;
                              final task = TaskModel(
                                id: widget.initialTask?.id,
                                uuid:
                                    widget.initialTask?.uuid ??
                                    const Uuid().v4(),
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                status: status,
                              );

                              setState(() => _isSaving = true);
                              try {
                                if (_isEditMode) {
                                  await ref
                                      .read(taskListProvider.notifier)
                                      .updateTask(task, token);
                                } else {
                                  await ref
                                      .read(taskListProvider.notifier)
                                      .addTask(task, token);
                                }

                                if (!context.mounted) return;
                                showGlassSnackBar(
                                  context,
                                  _isEditMode
                                      ? l10n.tr('task.updatedSuccessfully')
                                      : l10n.tr('task.addedSuccessfully'),
                                );
                                Navigator.pop(context, true);
                              } catch (e) {
                                if (!context.mounted) return;
                                showGlassSnackBar(
                                  context,
                                  'Error: $e',
                                  isError: true,
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isSaving = false);
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context,
    String hint,
    bool isDark,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF98A6B3) : const Color(0xFF8D959E),
        fontSize: 14,
      ),
      filled: true,
      fillColor: AppColors.surface(context),
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
