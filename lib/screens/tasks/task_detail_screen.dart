import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/constants/app_colors.dart';
import 'package:sunu_task/core/constants/app_strings.dart';
import 'package:sunu_task/models/task.dart';
import 'package:sunu_task/providers/task_provider.dart';
import 'package:sunu_task/screens/tasks/task_form_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;
  final String? projectIdForEdit;

  const TaskDetailScreen({
    super.key,
    required this.task,
    this.projectIdForEdit,
  });

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return AppColors.statusTodo;
      case TaskStatus.inProgress:
        return AppColors.statusInProgress;
      case TaskStatus.done:
        return AppColors.statusDone;
    }
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return AppStrings.statusTodo;
      case TaskStatus.inProgress:
        return AppStrings.statusInProgress;
      case TaskStatus.done:
        return AppStrings.statusDone;
    }
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppStrings.priorityHigh;
      case TaskPriority.medium:
        return AppStrings.priorityMedium;
      case TaskPriority.low:
        return AppStrings.priorityLow;
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer la tache'),
          content: const Text('Voulez-vous vraiment supprimer cette tache ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(AppStrings.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    await context.read<TaskProvider>().deleteTask(task.id);
    if (!context.mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Tache supprimee.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final latest = taskProvider.allTasks.where((t) => t.id == task.id);
        final t = latest.isNotEmpty ? latest.first : task;

        final statusColor = _statusColor(t.status);
        final priorityColor = _priorityColor(t.priority);

        Widget statusChip(TaskStatus s) {
          final selected = t.status == s;
          return ChoiceChip(
            label: Text(_statusLabel(s)),
            selected: selected,
            selectedColor: _statusColor(s).withAlpha(40),
            onSelected: taskProvider.isLoading
                ? null
                : (_) => taskProvider.updateTaskStatus(t.id, s),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tache'),
            actions: [
              IconButton(
                tooltip: AppStrings.edit,
                onPressed: taskProvider.isLoading
                    ? null
                    : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskFormScreen(
                              task: t,
                              projectId: projectIdForEdit ?? t.projectId,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: AppStrings.delete,
                onPressed: taskProvider.isLoading ? null : () => _confirmAndDelete(context, t),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                t.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              if ((t.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(t.description!.trim()),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      _statusLabel(t.status),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: priorityColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: priorityColor),
                    ),
                    child: Text(
                      _priorityLabel(t.priority),
                      style: TextStyle(
                        color: priorityColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Changer le statut',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  statusChip(TaskStatus.todo),
                  statusChip(TaskStatus.inProgress),
                  statusChip(TaskStatus.done),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.dueDate == null
                          ? '${AppStrings.taskDueDate}: -'
                          : '${AppStrings.taskDueDate}: ${_formatDate(t.dueDate!)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Cree le ${_formatDate(t.createdAt)}'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

