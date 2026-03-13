import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/constants/app_colors.dart';
import 'package:sunu_task/core/constants/app_strings.dart';
import 'package:sunu_task/models/task.dart';
import 'package:sunu_task/providers/auth_provider.dart';
import 'package:sunu_task/providers/task_provider.dart';
import 'package:sunu_task/widgets/cards/task_card.dart';

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  Future<void> _refresh(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    await context.read<TaskProvider>().loadUserTasks(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListenableBuilder(
        listenable: Listenable.merge([auth, taskProvider]),
        builder: (context, _) {
          final user = auth.currentUser;
          if (user == null) {
            return ListView(
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 120),
                Center(child: Text('Aucun utilisateur.')),
              ],
            );
          }

          final allCount = taskProvider.taskCount;
          final filtered = taskProvider.tasks;
          final hasFilters =
              taskProvider.statusFilter != null || taskProvider.priorityFilter != null;

          Widget header() {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          AppStrings.tasks,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (hasFilters)
                        TextButton.icon(
                          onPressed: taskProvider.clearFilters,
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Reinitialiser'),
                        ),
                    ],
                  ),
                  if (taskProvider.isLoading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Statut',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tous'),
                        selected: taskProvider.statusFilter == null,
                        onSelected: (_) => taskProvider.setStatusFilter(null),
                      ),
                      ChoiceChip(
                        label: const Text(AppStrings.statusTodo),
                        selected: taskProvider.statusFilter == TaskStatus.todo,
                        onSelected: (_) => taskProvider.setStatusFilter(TaskStatus.todo),
                      ),
                      ChoiceChip(
                        label: const Text(AppStrings.statusInProgress),
                        selected:
                            taskProvider.statusFilter == TaskStatus.inProgress,
                        onSelected: (_) =>
                            taskProvider.setStatusFilter(TaskStatus.inProgress),
                      ),
                      ChoiceChip(
                        label: const Text(AppStrings.statusDone),
                        selected: taskProvider.statusFilter == TaskStatus.done,
                        onSelected: (_) => taskProvider.setStatusFilter(TaskStatus.done),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Priorite',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tous'),
                        selected: taskProvider.priorityFilter == null,
                        onSelected: (_) => taskProvider.setPriorityFilter(null),
                      ),
                      ChoiceChip(
                        label: const Text(AppStrings.priorityHigh),
                        selected: taskProvider.priorityFilter == TaskPriority.high,
                        onSelected: (_) =>
                            taskProvider.setPriorityFilter(TaskPriority.high),
                        selectedColor: AppColors.priorityHigh.withAlpha(40),
                      ),
                      ChoiceChip(
                        label: const Text(AppStrings.priorityMedium),
                        selected: taskProvider.priorityFilter == TaskPriority.medium,
                        onSelected: (_) =>
                            taskProvider.setPriorityFilter(TaskPriority.medium),
                        selectedColor: AppColors.priorityMedium.withAlpha(40),
                      ),
                      ChoiceChip(
                        label: const Text(AppStrings.priorityLow),
                        selected: taskProvider.priorityFilter == TaskPriority.low,
                        onSelected: (_) =>
                            taskProvider.setPriorityFilter(TaskPriority.low),
                        selectedColor: AppColors.priorityLow.withAlpha(40),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasFilters
                        ? '${filtered.length} / $allCount'
                        : '$allCount',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          }

          if (allCount == 0) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 40),
              children: [
                header(),
                const SizedBox(height: 24),
                Icon(Icons.checklist_outlined,
                    size: 56, color: AppColors.textDisable),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    AppStrings.noTasks,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    AppStrings.noTasksDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            );
          }

          if (filtered.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 40),
              children: [
                header(),
                const SizedBox(height: 24),
                Icon(Icons.filter_alt_off_outlined,
                    size: 56, color: AppColors.textDisable),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Aucune tache pour ce filtre.',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 16, bottom: 40),
            itemCount: 1 + filtered.length,
            itemBuilder: (context, index) {
              if (index == 0) return header();
              final task = filtered[index - 1];
              return TaskCard(task: task, onTap: () {});
            },
          );
        },
      ),
    );
  }
}

