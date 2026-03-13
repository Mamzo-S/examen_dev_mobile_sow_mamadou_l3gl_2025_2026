import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/constants/app_colors.dart';
import 'package:sunu_task/core/constants/app_strings.dart';
import 'package:sunu_task/models/task.dart';
import 'package:sunu_task/providers/auth_provider.dart';
import 'package:sunu_task/providers/task_provider.dart';
import 'package:sunu_task/widgets/common/custom_button.dart';
import 'package:sunu_task/widgets/common/custom_text_field.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task; // null = création, non-null = modification
  final String? projectId; // obligatoire en création

  const TaskFormScreen({super.key, this.task, this.projectId})
      : assert(task != null || projectId != null);

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late TaskStatus _status;
  late TaskPriority _priority;
  DateTime? _dueDate;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _status = widget.task?.status ?? TaskStatus.todo;
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return AppStrings.requiredField;
    return null;
  }

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

  Widget _animatedChoice({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final bg = selected ? color.withAlpha(26) : AppColors.surface;
    final border = selected ? color : AppColors.border;
    final fg = selected ? color : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 10),
      initialDate: _dueDate ?? DateTime.now(),
    );
    if (selected == null) return;
    setState(() => _dueDate = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final taskProvider = context.read<TaskProvider>();
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();
    final description = desc.isEmpty ? null : desc;

    try {
      if (_isEdit) {
        final t = widget.task!;
        final updated = Task(
          id: t.id,
          projectId: t.projectId,
          userId: t.userId,
          title: title,
          description: description,
          status: _status,
          priority: _priority,
          dueDate: _dueDate,
          createdAt: t.createdAt,
        );
        await taskProvider.updateTask(updated);
      } else {
        await taskProvider.createTask(
          userId: user.id,
          projectId: widget.projectId!,
          title: title,
          description: description,
          status: _status,
          priority: _priority,
          dueDate: _dueDate,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.errorOccurred)),
      );
    }
  }

  Future<void> _delete() async {
    final t = widget.task;
    if (t == null) return;

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
    await context.read<TaskProvider>().deleteTask(t.id);
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Tache supprimee.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final isLoading = taskProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? AppStrings.editTask : AppStrings.newTask),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  label: AppStrings.taskTitle,
                  controller: _titleController,
                  validator: _validateTitle,
                  textInputAction: TextInputAction.next,
                  prefixIcon: Icons.task_outlined,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: AppStrings.taskDescription,
                  controller: _descriptionController,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.taskStatus,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _animatedChoice(
                      label: _statusLabel(TaskStatus.todo),
                      selected: _status == TaskStatus.todo,
                      color: _statusColor(TaskStatus.todo),
                      onTap: isLoading
                          ? null
                          : () => setState(() => _status = TaskStatus.todo),
                    ),
                    _animatedChoice(
                      label: _statusLabel(TaskStatus.inProgress),
                      selected: _status == TaskStatus.inProgress,
                      color: _statusColor(TaskStatus.inProgress),
                      onTap: isLoading
                          ? null
                          : () =>
                              setState(() => _status = TaskStatus.inProgress),
                    ),
                    _animatedChoice(
                      label: _statusLabel(TaskStatus.done),
                      selected: _status == TaskStatus.done,
                      color: _statusColor(TaskStatus.done),
                      onTap: isLoading
                          ? null
                          : () => setState(() => _status = TaskStatus.done),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.taskPriority,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _animatedChoice(
                      label: _priorityLabel(TaskPriority.high),
                      selected: _priority == TaskPriority.high,
                      color: _priorityColor(TaskPriority.high),
                      onTap: isLoading
                          ? null
                          : () => setState(() => _priority = TaskPriority.high),
                    ),
                    _animatedChoice(
                      label: _priorityLabel(TaskPriority.medium),
                      selected: _priority == TaskPriority.medium,
                      color: _priorityColor(TaskPriority.medium),
                      onTap: isLoading
                          ? null
                          : () =>
                              setState(() => _priority = TaskPriority.medium),
                    ),
                    _animatedChoice(
                      label: _priorityLabel(TaskPriority.low),
                      selected: _priority == TaskPriority.low,
                      color: _priorityColor(TaskPriority.low),
                      onTap: isLoading
                          ? null
                          : () => setState(() => _priority = TaskPriority.low),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? '${AppStrings.taskDueDate} (optionnel)'
                            : '${AppStrings.taskDueDate}: ${_formatDate(_dueDate!)}',
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : _pickDueDate,
                      child: Text(_dueDate == null ? 'Choisir' : 'Changer'),
                    ),
                    if (_dueDate != null)
                      IconButton(
                        tooltip: AppStrings.delete,
                        onPressed: isLoading ? null : () => setState(() => _dueDate = null),
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                CustomButton(
                  text: _isEdit ? AppStrings.edit : AppStrings.add,
                  width: double.infinity,
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),
                if (_isEdit) ...[
                  CustomButton(
                    text: AppStrings.delete,
                    width: double.infinity,
                    isOutlined: true,
                    color: AppColors.error,
                    onPressed: isLoading ? null : _delete,
                  ),
                  const SizedBox(height: 10),
                ],
                CustomButton(
                  text: AppStrings.cancel,
                  width: double.infinity,
                  isOutlined: true,
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

