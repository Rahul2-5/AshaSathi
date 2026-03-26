import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/localization/app_localizations.dart';

import '../../auth/cubit/login_cubit.dart';
import '../../task/add_task_page.dart';
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

  String _statusLabel(BuildContext context) {
    switch (task.status) {
      case TaskStatus.urgent:
        return context.l10n.tr('task.urgent');
      case TaskStatus.completed:
        return context.l10n.tr('task.done');
      case TaskStatus.inProgress:
        return context.l10n.tr('task.inProgress');
      default:
        return context.l10n.tr('task.pending');
    }
  }

  void _showLoadingDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 50),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A232C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2E3C48) : const Color(0xFFDCE5EC),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
              const SizedBox(width: 12),
              Text(
                'Processing...',
                style: TextStyle(
                  color: isDark ? const Color(0xFFE6EDF3) : const Color(0xFF202329),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _showTaskDetailsDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1A232C) : Colors.white;
    final sectionColor = isDark ? const Color(0xFF22303C) : const Color(0xFFF4F8FB);
    final primaryText = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF202329);
    final secondaryText = isDark ? const Color(0xFFA4B0BA) : const Color(0xFF5C6670);

    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2E3C48) : const Color(0xFFDCE5EC),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFF4EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFF18A39B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.tr('task.taskTitle'),
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(context),
                      style: TextStyle(
                        color: _statusColor(),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sectionColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.tr('task.taskDescription'),
                style: TextStyle(
                  color: secondaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sectionColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    task.description.trim().isEmpty ? '-' : task.description,
                    style: TextStyle(
                      color: primaryText,
                      height: 1.35,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(context.l10n.tr('common.cancel')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1A232C) : Colors.white;
    final sectionColor = isDark ? const Color(0xFF2A1F27) : const Color(0xFFFFF2F4);
    final primaryText = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF202329);
    final secondaryText = isDark ? const Color(0xFFB8A8AE) : const Color(0xFF6E5D63);

    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF3A2B33) : const Color(0xFFF2D8DE),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE3E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFD64242),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.tr('task.deleteTask'),
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sectionColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.tr('task.deleteTaskConfirm'),
                      style: TextStyle(
                        color: secondaryText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(context.l10n.tr('common.cancel')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD64242),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.delete_forever_outlined, size: 18),
                    label: Text(context.l10n.tr('common.delete')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStyledSnackBar(
    BuildContext context, {
    required String message,
    required Color accent,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A232C) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color:
                        isDark ? const Color(0xFFE6EDF3) : const Color(0xFF202329),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showTaskDetailsDialog(context),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A232C) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF2A3642) : const Color(0xFFE9EDF0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF4EC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                Icons.assignment,
                color: Color(0xFF18A39B),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Color(0xFFE6EDF3) : Color(0xFF202329),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 26,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor().withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          task.status == TaskStatus.urgent
                              ? _statusLabel(context).toUpperCase()
                              : _statusLabel(context),
                          style: TextStyle(
                            color: _statusColor(),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.2,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF9EABB7) : const Color(0xFF8B939C),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF18A39B),
            ),
            onPressed: () async {
              final edited = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTaskPage(initialTask: task),
                ),
              );

              if (edited == true && context.mounted) {
                final token = context.read<LoginCubit>().state.token!;
                await context.read<TaskCubit>().loadTasks(token);
              }
            },
            tooltip: context.l10n.tr('task.editTask'),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFFFF5252),
              size: 20,
            ),
            onPressed: () async {
              final confirm = await _showDeleteConfirmDialog(context);

              if (!context.mounted) return;

              if (confirm == true) {
                final token =
                    context.read<LoginCubit>().state.token!;
                _showLoadingDialog(context);

                try {
                  final deleted = await context
                      .read<TaskCubit>()
                      .deleteTaskWithUuid(task.id ?? -1, task.uuid, token);

                  if (!context.mounted) return;
                  _hideLoadingDialog(context);

                  if (deleted) {
                    _showStyledSnackBar(
                      context,
                      message: context.l10n.tr('task.deletedSuccessfully'),
                      accent: const Color(0xFFD64242),
                      icon: Icons.delete_outline,
                    );
                  } else {
                    _showStyledSnackBar(
                      context,
                      message: context.l10n.tr('task.markedDeletion'),
                      accent: const Color(0xFFDD8A2A),
                      icon: Icons.cloud_off_outlined,
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  _hideLoadingDialog(context);
                  _showStyledSnackBar(
                    context,
                    message: context
                        .l10n
                        .tr('task.errorDeleting', args: {'error': e.toString()}),
                    accent: const Color(0xFFD64242),
                    icon: Icons.error_outline,
                  );
                }
              }
            },
            splashRadius: 18,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minHeight: 24, minWidth: 24),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
