import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/constants/app_colors.dart';
import 'package:sunu_task/core/constants/app_strings.dart';
import 'package:sunu_task/models/task.dart';
import 'package:sunu_task/providers/auth_provider.dart';
import 'package:sunu_task/providers/project_provider.dart';
import 'package:sunu_task/providers/task_provider.dart';
import 'package:sunu_task/screens/auth/login_screen.dart';
import 'package:sunu_task/widgets/common/custom_button.dart';
import 'package:sunu_task/widgets/common/custom_text_field.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

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

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
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
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final parentContext = context;
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    String? validateName(String? value) {
      final name = value?.trim() ?? '';
      if (name.isEmpty) return AppStrings.nameRequired;
      return null;
    }

    String? validateEmail(String? value) {
      final email = value?.trim() ?? '';
      if (email.isEmpty) return AppStrings.emailRequired;
      if (!email.contains('@') || !email.contains('.')) return AppStrings.emailInvalid;
      return null;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Consumer<AuthProvider>(
              builder: (_, authProvider, _) {
                return Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Modifier le profil',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: AppStrings.name,
                        controller: nameController,
                        validator: validateName,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: AppStrings.email,
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: validateEmail,
                        textInputAction: TextInputAction.done,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: AppStrings.save,
                        width: double.infinity,
                        isLoading: authProvider.isLoading,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          await authProvider.updateProfile(
                            name: nameController.text.trim(),
                            email: emailController.text.trim(),
                          );

                          if (!sheetContext.mounted) return;

                          final error = authProvider.error;
                          if (error != null) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                            return;
                          }

                          Navigator.pop(sheetContext);
                          if (!parentContext.mounted) return;
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(content: Text('Profil mis a jour.')),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        text: AppStrings.cancel,
                        width: double.infinity,
                        isOutlined: true,
                        onPressed: authProvider.isLoading ? null : () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Deconnexion'),
          content: const Text('Voulez-vous vraiment vous deconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(AppStrings.logout),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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

        final avatarLetter =
            user.name.trim().isNotEmpty ? user.name.trim()[0].toUpperCase() : '?';
        final counts = taskProvider.taskCountByStatus;
        final isLoading =
            auth.isLoading || projectProvider.isLoading || taskProvider.isLoading;

        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withAlpha(30),
                    foregroundColor: AppColors.textPrimary,
                    child: Text(
                      avatarLetter,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(user.email),
                        const SizedBox(height: 6),
                        Text(
                          'Inscrit le ${_formatDate(user.createdAt)}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: AppStrings.edit,
                    onPressed: isLoading ? null : () => _editProfile(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
            if (isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 18),
            const Text(
              'Statistiques',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _statCard(
                  label: AppStrings.projects,
                  value: projectProvider.projectCount.toString(),
                  color: AppColors.primary,
                  icon: Icons.folder_open_outlined,
                ),
                _statCard(
                  label: AppStrings.tasks,
                  value: taskProvider.taskCount.toString(),
                  color: AppColors.info,
                  icon: Icons.task_outlined,
                ),
                _statCard(
                  label: AppStrings.statusTodo,
                  value: (counts[TaskStatus.todo] ?? 0).toString(),
                  color: AppColors.statusTodo,
                  icon: Icons.checklist_outlined,
                ),
                _statCard(
                  label: AppStrings.statusInProgress,
                  value: (counts[TaskStatus.inProgress] ?? 0).toString(),
                  color: AppColors.statusInProgress,
                  icon: Icons.timelapse,
                ),
                _statCard(
                  label: AppStrings.statusDone,
                  value: (counts[TaskStatus.done] ?? 0).toString(),
                  color: AppColors.statusDone,
                  icon: Icons.done_all,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Compte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Modifier le profil'),
                    onTap: isLoading ? null : () => _editProfile(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: AppColors.error),
                    title: Text(
                      AppStrings.logout,
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: isLoading ? null : () => _logout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        );
      },
      ),
    );
  }
}
