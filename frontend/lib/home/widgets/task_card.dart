import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/localization/app_localizations.dart';

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
              Icons.delete_outline,
              color: Color(0xFFFF5252),
              size: 20,
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(context.l10n.tr('task.deleteTask')),
                  content: Text(
                    context.l10n.tr('task.deleteTaskConfirm'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.l10n.tr('common.cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        context.l10n.tr('common.delete'),
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.tr('task.deletedSuccessfully')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.tr('task.markedDeletion')),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  _hideLoadingDialog(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.tr('task.errorDeleting', args: {'error': e.toString()}),
                      ),
                      backgroundColor: Colors.red,
                    ),
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
    );
  }
}
