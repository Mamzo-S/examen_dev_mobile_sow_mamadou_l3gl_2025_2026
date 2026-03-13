import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/constants/app_colors.dart';
import 'package:sunu_task/core/constants/app_strings.dart';
import 'package:sunu_task/models/project.dart';
import 'package:sunu_task/providers/auth_provider.dart';
import 'package:sunu_task/providers/project_provider.dart';
import 'package:sunu_task/widgets/cards/project_card.dart';
import 'package:sunu_task/widgets/common/custom_button.dart';
import 'package:sunu_task/widgets/common/custom_text_field.dart';

class ProjectFormScreen extends StatefulWidget {
  final Project? project; // null = creation, non-null = modification

  const ProjectFormScreen({super.key, this.project});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  late Color _selectedColor;

  bool get _isEdit => widget.project != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.project?.description ?? '');
    _selectedColor = Color(
      widget.project?.colorValue ?? AppColors.projectPalette.first.value,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return AppStrings.requiredField;
    if (name.length < 3) return 'Minimum 3 caracteres';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final projectProvider = context.read<ProjectProvider>();
    final name = _nameController.text.trim();
    final desc = _descriptionController.text.trim();
    final description = desc.isEmpty ? null : desc;

    try {
      if (_isEdit) {
        final p = widget.project!;
        final updated = Project(
          id: p.id,
          userId: p.userId,
          name: name,
          description: description,
          colorValue: _selectedColor.value,
          createdAt: p.createdAt,
        );
        await projectProvider.updateProject(updated);
      } else {
        await projectProvider.createProject(
          userId: user.id,
          name: name,
          description: description,
          colorValue: _selectedColor.value,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Projet modifie.' : 'Projet cree.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Une erreur est survenue.')),
      );
    }
  }

  Project _previewProject({required String userId}) {
    final name = _nameController.text.trim().isEmpty
        ? 'Mon projet'
        : _nameController.text.trim();
    final desc = _descriptionController.text.trim();

    return Project(
      id: widget.project?.id ?? 'preview',
      userId: userId,
      name: name,
      description: desc.isEmpty ? null : desc,
      colorValue: _selectedColor.value,
      createdAt: widget.project?.createdAt ?? DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? AppStrings.editProject : AppStrings.newProject),
      ),
      body: SafeArea(
        child: Consumer2<AuthProvider, ProjectProvider>(
          builder: (context, authProvider, projectProvider, _) {
            final user = authProvider.currentUser;
            if (user == null) {
              return const Center(child: Text('Aucun utilisateur.'));
            }

            final isLoading = authProvider.isLoading || projectProvider.isLoading;
            final preview = _previewProject(userId: user.id);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isLoading) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                    ],
                    CustomTextField(
                      label: AppStrings.projectName,
                      controller: _nameController,
                      validator: _validateName,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.folder_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: AppStrings.projectDescription,
                      controller: _descriptionController,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      prefixIcon: Icons.description_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.palette_outlined, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          AppStrings.projectColor,
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in AppColors.projectPalette)
                          InkWell(
                            onTap: isLoading
                                ? null
                                : () => setState(() => _selectedColor = c),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColor == c
                                      ? AppColors.textPrimary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Apercu',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    ProjectCard(
                      project: preview,
                      taskCount: 0,
                      onTap: null,
                      onEdit: null,
                      onDelete: null,
                    ),
                    const SizedBox(height: 18),
                    CustomButton(
                      text: _isEdit ? AppStrings.edit : AppStrings.add,
                      width: double.infinity,
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      text: AppStrings.cancel,
                      width: double.infinity,
                      isOutlined: true,
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

