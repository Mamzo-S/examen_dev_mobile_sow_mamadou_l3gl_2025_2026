import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/constants/app_colors.dart';
import 'package:sunu_task/models/task.dart';
import 'package:sunu_task/providers/auth_provider.dart';
import 'package:sunu_task/providers/project_provider.dart';
import 'package:sunu_task/providers/task_provider.dart';
import 'package:sunu_task/widgets/cards/project_card.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon apres-midi';
    return 'Bonsoir';
  }

  Future<void> _refresh(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final projectProvider = context.read<ProjectProvider>();
    final taskProvider = context.read<TaskProvider>();

    await Future.wait([
      projectProvider.loadProjects(user.id),
      taskProvider.loadUserTasks(user.id),
    ]);
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(70)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: Consumer2<ProjectProvider, TaskProvider>(
        builder: (context, projectProvider, taskProvider, _) {
          final counts = taskProvider.taskCountByStatus;
          final taskCountsByProject = taskProvider.taskCountByProjectId;
          final projects = projectProvider.projects;

          final recent = projects.take(3).toList();
          final isLoading = projectProvider.isLoading || taskProvider.isLoading;

          return ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(
                _greeting(),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              if (isLoading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _statCard(
                    'Projets',
                    projectProvider.projectCount.toString(),
                    AppColors.primary,
                    Icons.folder_open_outlined,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    'A faire',
                    (counts[TaskStatus.todo] ?? 0).toString(),
                    AppColors.statusTodo,
                    Icons.checklist_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statCard(
                    'En cours',
                    (counts[TaskStatus.inProgress] ?? 0).toString(),
                    AppColors.statusInProgress,
                    Icons.timelapse,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    'Terminees',
                    (counts[TaskStatus.done] ?? 0).toString(),
                    AppColors.statusDone,
                    Icons.done_all,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Projets recents',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(
                    child: Text('Aucun projet pour le moment.'),
                  ),
                )
              else
                for (final p in recent)
                  ProjectCard(
                    project: p,
                    taskCount: taskCountsByProject[p.id] ?? 0,
                    onTap: () {},
                  ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
