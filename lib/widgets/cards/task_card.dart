import 'package:flutter/material.dart';
import 'package:sunu_task/core/constants/app_colors.dart';
import 'package:sunu_task/core/constants/app_strings.dart';
import 'package:sunu_task/models/task.dart';

/// Widget TaskCard
/// Affiche une tache avec :
/// - titre
/// - statut
/// - description
/// - date limite
/// - callback onTap pour la navigation
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  // Retourne la couleur associee au statut de la tache
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

  // Retourne le label du statut
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

  /// Formate la date en format jj/mm/aaaa
  String _formatDueDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(task.status);
    final priorityColor = _priorityColor(task.priority);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),

      child: InkWell(
        // action lorsqu'on clique sur la carte
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Ligne principale (Titre + Statut)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Flexible(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.end,
                      children: [
                        // Badge de statut
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            _statusLabel(task.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        // Badge de priorite
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: priorityColor),
                          ),
                          child: Text(
                            _priorityLabel(task.priority),
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Description de la tache
              Visibility(
                visible: (task.description ?? '').trim().isNotEmpty,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      task.description?.trim() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Date limite
              Visibility(
                visible: task.dueDate != null,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 18),
                        const SizedBox(width: 6),
                        Text(_formatDueDate(task.dueDate!)),
                      ],
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
}
