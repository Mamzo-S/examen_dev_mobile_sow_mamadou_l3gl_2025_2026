import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/constants/app_colors.dart';
import 'package:sunu_task/core/constants/app_strings.dart';
import 'package:sunu_task/models/project.dart';
import 'package:sunu_task/models/task.dart';
import 'package:sunu_task/providers/auth_provider.dart';
import 'package:sunu_task/providers/project_provider.dart';
import 'package:sunu_task/providers/task_provider.dart';
import 'package:sunu_task/screens/projects/project_form_screen.dart';
import 'package:sunu_task/widgets/cards/task_card.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
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

  Future<void> _confirmAndDelete(
    BuildContext context, {
    required Project project,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le projet'),
          content: const Text(
            'Voulez-vous vraiment supprimer ce projet ? '
            'Toutes les taches associees seront aussi supprimees.',
          ),
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

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final projectProvider = context.read<ProjectProvider>();
    final taskProvider = context.read<TaskProvider>();

    await projectProvider.deleteProject(project.id);
    await taskProvider.loadUserTasks(user.id);

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Projet supprime.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projet'),
        actions: [
          IconButton(
            tooltip: AppStrings.edit,
            onPressed: () async {
              final projectProvider = context.read<ProjectProvider>();
              final current =
                  projectProvider.projects.where((p) => p.id == project.id);
              final p = current.isNotEmpty ? current.first : project;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectFormScreen(project: p),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: AppStrings.delete,
            onPressed: () => _confirmAndDelete(context, project: project),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ajout de tache: on le fera avec TaskFormScreen.'),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: Consumer3<AuthProvider, ProjectProvider, TaskProvider>(
          builder: (context, auth, projectProvider, taskProvider, _) {
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

            final projects = projectProvider.projects;
            final found = projects.where((p) => p.id == project.id);
            final p = found.isNotEmpty ? found.first : project;

            final isLoading =
                auth.isLoading || projectProvider.isLoading || taskProvider.isLoading;

            final tasks =
                taskProvider.allTasks.where((t) => t.projectId == p.id).toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final counts = <TaskStatus, int>{
              TaskStatus.todo: 0,
              TaskStatus.inProgress: 0,
              TaskStatus.done: 0,
            };
            for (final t in tasks) {
              counts[t.status] = (counts[t.status] ?? 0) + 1;
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: BoxDecoration(
                    color: Color(p.colorValue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if ((p.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          p.description!.trim(),
                          style: TextStyle(
                            color: Colors.white.withAlpha(230),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              '${AppStrings.statusTodo}: ${counts[TaskStatus.todo] ?? 0}',
                            ),
                          ),
                          Chip(
                            label: Text(
                              '${AppStrings.statusInProgress}: ${counts[TaskStatus.inProgress] ?? 0}',
                            ),
                          ),
                          Chip(
                            label: Text(
                              '${AppStrings.statusDone}: ${counts[TaskStatus.done] ?? 0}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Cree le ${_formatDate(p.createdAt)}',
                        style: TextStyle(color: Colors.white.withAlpha(230)),
                      ),
                    ],
                  ),
                ),
                if (isLoading) const LinearProgressIndicator(),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          AppStrings.tasks,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        tasks.length.toString(),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 30, 16, 60),
                    child: Column(
                      children: [
                        Icon(Icons.task_outlined,
                            size: 56, color: AppColors.textDisable),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucune tache pour ce projet.',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Utilise le bouton + pour en ajouter une.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  for (final t in tasks)
                    TaskCard(
                      task: t,
                      onTap: () {},
                    ),
                const SizedBox(height: 90),
              ],
            );
          },
        ),
      ),
    );
  }
}
