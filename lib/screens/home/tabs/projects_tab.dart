import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/constants/app_colors.dart';
import 'package:sunu_task/core/constants/app_strings.dart';
import 'package:sunu_task/providers/auth_provider.dart';
import 'package:sunu_task/providers/project_provider.dart';
import 'package:sunu_task/providers/task_provider.dart';
import 'package:sunu_task/screens/projects/project_detail_screen.dart';
import 'package:sunu_task/screens/projects/project_form_screen.dart';
import 'package:sunu_task/widgets/cards/project_card.dart';

class ProjectsTab extends StatelessWidget {
  const ProjectsTab({super.key});

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

  Future<void> _confirmAndDeleteProject(
    BuildContext context, {
    required String projectId,
    required String projectName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le projet'),
          content: Text(
            'Supprimer "$projectName" ?\n'
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

    await projectProvider.deleteProject(projectId);
    await taskProvider.loadUserTasks(user.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Projet supprime.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final projectProvider = context.read<ProjectProvider>();
    final taskProvider = context.read<TaskProvider>();

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: ListenableBuilder(
        listenable: Listenable.merge([auth, projectProvider, taskProvider]),
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

          final projects = projectProvider.projects;
          final taskCountsByProject = taskProvider.taskCountByProjectId;
          final isLoading =
              auth.isLoading || projectProvider.isLoading || taskProvider.isLoading;

          return ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      AppStrings.projects,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProjectFormScreen(),
                              ),
                            );
                          },
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.newProject),
                  ),
                ],
              ),
              if (isLoading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 12),
              if (projects.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Column(
                    children: [
                      Icon(Icons.folder_open_outlined,
                          size: 56, color: AppColors.textDisable),
                      const SizedBox(height: 12),
                      const Text(
                        AppStrings.noProjects,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.noProjectsDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProjectFormScreen(),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.add),
                        label: const Text(AppStrings.newProject),
                      ),
                    ],
                  ),
                )
              else
                for (final p in projects)
                  ProjectCard(
                    project: p,
                    taskCount: taskCountsByProject[p.id] ?? 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(project: p),
                        ),
                      );
                    },
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectFormScreen(project: p),
                        ),
                      );
                    },
                    onDelete: () => _confirmAndDeleteProject(
                      context,
                      projectId: p.id,
                      projectName: p.name,
                    ),
                  ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
