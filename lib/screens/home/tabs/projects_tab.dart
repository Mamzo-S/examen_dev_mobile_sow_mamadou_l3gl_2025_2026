import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/constants/app_colors.dart';
import 'package:sunu_task/core/constants/app_strings.dart';
import 'package:sunu_task/providers/auth_provider.dart';
import 'package:sunu_task/providers/project_provider.dart';
import 'package:sunu_task/providers/task_provider.dart';
import 'package:sunu_task/widgets/cards/project_card.dart';
import 'package:sunu_task/widgets/common/custom_button.dart';
import 'package:sunu_task/widgets/common/custom_text_field.dart';

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

  Future<void> _openCreateProjectDialog(BuildContext context) async {
    final parentContext = context;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    const palette = <Color>[
      AppColors.primary,
      Color(0xFF22C55E),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF14B8A6),
      Color(0xFF0EA5E9),
      Color(0xFF64748B),
    ];

    Color selected = palette.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer<ProjectProvider>(
          builder: (context, projectProvider, _) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Nouveau projet'),
                  content: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomTextField(
                            label: AppStrings.projectName,
                            controller: nameController,
                            validator: (value) {
                              final name = value?.trim() ?? '';
                              if (name.isEmpty) return AppStrings.requiredField;
                              if (name.length < 3) {
                                return 'Minimum 3 caracteres';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.folder_outlined,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            label: AppStrings.projectDescription,
                            controller: descriptionController,
                            maxLines: 3,
                            textInputAction: TextInputAction.newline,
                            prefixIcon: Icons.description_outlined,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.palette_outlined, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                AppStrings.projectColor,
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final c in palette)
                                InkWell(
                                  onTap: projectProvider.isLoading
                                      ? null
                                      : () => setState(() => selected = c),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: c,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selected == c
                                            ? AppColors.textPrimary
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: projectProvider.isLoading
                          ? null
                          : () => Navigator.pop(dialogContext),
                      child: const Text(AppStrings.cancel),
                    ),
                    CustomButton(
                      text: AppStrings.add,
                      isLoading: projectProvider.isLoading,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        try {
                          await projectProvider.createProject(
                            userId: user.id,
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            colorValue: selected.value,
                          );

                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (!parentContext.mounted) return;
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(content: Text('Projet cree.')),
                          );
                        } catch (_) {
                          if (!dialogContext.mounted) return;
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Impossible de creer le projet.')),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
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
                    onPressed: isLoading ? null : () => _openCreateProjectDialog(context),
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
                      CustomButton(
                        text: AppStrings.newProject,
                        icon: Icons.add,
                        onPressed:
                            isLoading ? null : () => _openCreateProjectDialog(context),
                      ),
                    ],
                  ),
                )
              else
                for (final p in projects)
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
