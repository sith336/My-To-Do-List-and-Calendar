import 'package:flutter/material.dart';

import 'app_style.dart';
import 'task.dart';

Future<TodoTask?> showTaskForm(
  BuildContext context, {
  DateTime? initialDate,
  String? initialTitle,
  required List<TaskCategory> categories,
}) {
  return showModalBottomSheet<TodoTask>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TaskForm(
      initialDate: initialDate,
      initialTitle: initialTitle,
      categories: categories,
    ),
  );
}

class TaskForm extends StatefulWidget {
  const TaskForm({
    super.key,
    this.initialDate,
    this.initialTitle,
    required this.categories,
  });

  final DateTime? initialDate;
  final String? initialTitle;
  final List<TaskCategory> categories;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late DateTime _date;
  late TimeOfDay _time;
  TaskCategory _category = TaskCategory.work;

  @override
  void initState() {
    super.initState();
    if (!widget.categories.contains(_category) &&
        widget.categories.isNotEmpty) {
      _category = widget.categories.first;
    }
    final initial = widget.initialDate ?? DateTime.now();
    _date = DateTime(initial.year, initial.month, initial.day);
    _time = TimeOfDay.fromDateTime(initial);
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      TodoTask(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: titleCaseTask(_titleController.text),
        dateTime: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time.hour,
          _time.minute,
        ),
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add a task',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    key: const ValueKey('task-title-field'),
                    controller: _titleController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'What do you need to do?',
                      hintText: 'e.g. Review project brief',
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a task name.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 17,
                          ),
                          label: Text(formattedDate(_date)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.blue,
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(
                            formatTime(
                              DateTime(2000, 1, 1, _time.hour, _time.minute),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.blue,
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskCategory>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: widget.categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(categoryName(category)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('save-task-button'),
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Save task'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
