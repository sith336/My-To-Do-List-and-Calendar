import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import 'task.dart';

class TaskAddResult {
  const TaskAddResult({required this.reminderScheduled, this.reminderError});

  final bool reminderScheduled;
  final String? reminderError;
}

class TaskDeleteResult {
  const TaskDeleteResult({this.reminderError});

  final String? reminderError;
}

class TaskStore extends ChangeNotifier {
  TaskStore(this._notifications);

  final NotificationService _notifications;
  final List<TodoTask> _tasks = [];
  final List<TaskCategory> _categories = [...TaskCategory.defaults];
  bool _isLoading = true;

  List<TodoTask> get tasks => List.unmodifiable(_tasks);
  List<TaskCategory> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('todo_tasks_v2');
    if (saved != null) {
      final decoded = jsonDecode(saved) as List<dynamic>;
      _tasks.addAll(
        decoded.map((item) => TodoTask.fromJson(item as Map<String, Object?>)),
      );
    }
    final savedCategories = preferences.getString('todo_categories_v1');
    if (savedCategories != null) {
      final decoded = jsonDecode(savedCategories) as List<dynamic>;
      for (final item in decoded) {
        final category = TaskCategory.fromJson(item as Map<String, Object?>);
        if (!_categories.any((existing) => existing.id == category.id)) {
          _categories.add(category);
        }
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(String name, int colorValue) async {
    final normalizedName = titleCaseTask(name);
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Category name cannot be empty.');
    }
    if (_categories.any(
      (category) => category.name.toLowerCase() == normalizedName.toLowerCase(),
    )) {
      throw ArgumentError.value(name, 'name', 'That category already exists.');
    }
    final category = TaskCategory(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: normalizedName,
      colorValue: colorValue,
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'todo_categories_v1',
      jsonEncode([
        ..._categories.map((category) => category.toJson()),
        category.toJson(),
      ]),
    );
    _categories.add(category);
    notifyListeners();
  }

  Future<TaskAddResult> add(TodoTask task) async {
    _tasks.add(task);
    notifyListeners();
    await _save();
    try {
      return TaskAddResult(
        reminderScheduled: await _notifications.scheduleTask(task),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Could not schedule a task reminder.',
        error: error,
        stackTrace: stackTrace,
        name: 'mytodolist.notifications',
      );
      return TaskAddResult(
        reminderScheduled: false,
        reminderError: error.toString(),
      );
    }
  }

  Future<void> toggleComplete(TodoTask task) async {
    task.isComplete = !task.isComplete;
    notifyListeners();
    await _save();
    if (task.isComplete) {
      await _notifications.cancelTask(task);
    } else {
      await _notifications.scheduleTask(task);
    }
  }

  Future<TaskDeleteResult> delete(TodoTask task) async {
    if (!_tasks.remove(task)) return const TaskDeleteResult();
    notifyListeners();
    await _save();
    try {
      await _notifications.cancelTask(task);
      return const TaskDeleteResult();
    } catch (error, stackTrace) {
      developer.log(
        'Could not cancel a deleted task reminder.',
        error: error,
        stackTrace: stackTrace,
        name: 'mytodolist.notifications',
      );
      return TaskDeleteResult(reminderError: error.toString());
    }
  }

  Future<bool> requestNotifications() => _notifications.requestPermission();

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'todo_tasks_v2',
      jsonEncode(_tasks.map((task) => task.toJson()).toList()),
    );
  }
}
