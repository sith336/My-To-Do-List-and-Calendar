import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_style.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'notification_service.dart';
import 'record_screen.dart';
import 'settings_screen.dart';
import 'task.dart';
import 'task_details.dart';
import 'task_form.dart';
import 'task_store.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoadingTheme = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    final isDark = preferences.getBool('dark_mode') ?? false;
    if (!mounted) return;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _isLoadingTheme = false;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('dark_mode', mode == ThemeMode.dark);
  }

  ThemeData _theme(AppColors colors, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.blue,
      brightness: brightness,
      surface: colors.background,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: scheme.copyWith(
        primary: colors.blue,
        onPrimary: brightness == Brightness.dark ? ink : Colors.white,
        surface: colors.background,
        onSurface: colors.ink,
      ),
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        surfaceTintColor: colors.background,
        foregroundColor: colors.ink,
      ),
      cardColor: colors.surface,
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: colors.ink,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        titleLarge: TextStyle(
          color: colors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: colors.ink, fontSize: 16),
        bodyMedium: TextStyle(color: colors.muted, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(color: colors.muted),
        labelStyle: TextStyle(color: colors.muted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To Do List',
      debugShowCheckedModeBanner: false,
      theme: _theme(AppColors.light, Brightness.light),
      darkTheme: _theme(AppColors.dark, Brightness.dark),
      themeMode: _themeMode,
      home: _isLoadingTheme
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : TaskAppShell(
              onThemeModeChanged: _setThemeMode,
              themeMode: _themeMode,
            ),
    );
  }
}

class TaskAppShell extends StatefulWidget {
  const TaskAppShell({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<TaskAppShell> createState() => _TaskAppShellState();
}

class _TaskAppShellState extends State<TaskAppShell> {
  final NotificationService _notifications = NotificationService();
  late final TaskStore _store = TaskStore(_notifications);
  final GlobalKey<RecordScreenState> _recordScreenKey =
      GlobalKey<RecordScreenState>();
  int _tabIndex = 0;
  RecordCaptureState _captureState = RecordCaptureState.idle;
  bool _recordPointerDown = false;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  Future<void> _addManualTask({
    DateTime? initialDate,
    String? initialTitle,
  }) async {
    final task = await showTaskForm(
      context,
      initialDate: initialDate,
      initialTitle: initialTitle,
      categories: _store.categories,
    );
    if (task == null || !mounted) return;
    final result = await _store.add(task);
    if (!mounted) return;
    setState(() {
      _captureState = RecordCaptureState.idle;
      _tabIndex = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.reminderScheduled
              ? 'Task added. A due-time reminder is scheduled.'
              : result.reminderError == null
              ? 'Task added. No reminder was scheduled; check its due time and notification permission.'
              : 'Task added, but its reminder could not be scheduled: ${result.reminderError}',
        ),
      ),
    );
  }

  Future<void> _saveRecordedTask(TodoTask task) async {
    final result = await _store.add(task);
    if (!mounted) return;
    setState(() {
      _captureState = RecordCaptureState.idle;
      _tabIndex = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.reminderScheduled
              ? 'Task saved. A due-time reminder is scheduled.'
              : result.reminderError == null
              ? 'Task saved. No reminder was scheduled; check its due time and notification permission.'
              : 'Task saved, but its reminder could not be scheduled: ${result.reminderError}',
        ),
      ),
    );
  }

  Future<void> _viewTask(TodoTask task) =>
      showTaskDetails(context, task, onDelete: () => _confirmDeleteTask(task));

  Future<void> _confirmDeleteTask(TodoTask task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('“${task.title}” will be permanently removed.'),
        actions: [
          TextButton(
            key: const ValueKey('cancel-delete-task'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-task'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(context).red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    final result = await _store.delete(task);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.reminderError == null
              ? 'Task deleted.'
              : 'Task deleted, but its reminder could not be canceled: ${result.reminderError}',
        ),
      ),
    );
  }

  void _startRecording() {
    if (_recordPointerDown) return;
    if (_captureState == RecordCaptureState.review) {
      _recordScreenKey.currentState?.saveReviewTask();
      return;
    }
    _recordPointerDown = true;
    setState(() {
      _tabIndex = 1;
      _captureState = RecordCaptureState.recording;
    });
    _recordScreenKey.currentState?.startRecording();
  }

  void _finishRecording() {
    if (!_recordPointerDown) return;
    _recordPointerDown = false;
    _recordScreenKey.currentState?.stopRecording();
  }

  void _onCaptureStateChanged(RecordCaptureState state) {
    if (_captureState == state || !mounted) return;
    setState(() => _captureState = state);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        if (_store.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final screens = [
          HomeScreen(
            tasks: _store.tasks,
            onAddTask: (date) => _addManualTask(initialDate: date),
            onOpenSettings: () => setState(() => _tabIndex = 3),
            onToggleComplete: _store.toggleComplete,
            onViewTask: _viewTask,
            onDeleteTask: _confirmDeleteTask,
          ),
          RecordScreen(
            key: _recordScreenKey,
            onSaveTask: _saveRecordedTask,
            onCaptureStateChanged: _onCaptureStateChanged,
            categories: _store.categories,
            onAddManually: (title) => _addManualTask(
              initialDate: DateTime.now(),
              initialTitle: title.isEmpty ? null : title,
            ),
          ),
          CalendarScreen(
            tasks: _store.tasks,
            onAddTask: (date) => _addManualTask(initialDate: date),
            onOpenSettings: () => setState(() => _tabIndex = 3),
            onToggleComplete: _store.toggleComplete,
            categories: _store.categories,
            onViewTask: _viewTask,
            onDeleteTask: _confirmDeleteTask,
          ),
          SettingsScreen(
            themeMode: widget.themeMode,
            onThemeModeChanged: widget.onThemeModeChanged,
            onRequestNotifications: _store.requestNotifications,
            categories: _store.categories,
            onAddCategory: _store.addCategory,
          ),
        ];
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (var index = 0; index < screens.length; index++)
                  Positioned.fill(
                    child: Offstage(
                      offstage: _tabIndex != index,
                      child: AnimatedSlide(
                        offset: _tabIndex == index
                            ? Offset.zero
                            : const Offset(.035, 0),
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          opacity: _tabIndex == index ? 1 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          child: screens[index],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: _buildNavigationBar(),
        );
      },
    );
  }

  Widget _buildNavigationBar() {
    final isRecording = _captureState == RecordCaptureState.recording;
    final reviewing = _captureState == RecordCaptureState.review;
    final saved = _captureState == RecordCaptureState.saved;
    final colors = AppColors.of(context);
    final recordColor = saved || reviewing ? colors.blue : colors.red;
    final recordIcon = saved
        ? Icons.check_rounded
        : isRecording
        ? Icons.graphic_eq_rounded
        : reviewing
        ? Icons.check_rounded
        : Icons.mic_none_rounded;
    final recordLabel = saved
        ? 'Saved'
        : isRecording
        ? 'Recording'
        : reviewing
        ? 'Save task'
        : 'Record';

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 91,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 72,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _navItem(0, Icons.home_outlined, 'Home')),
                    const Expanded(child: SizedBox()),
                    Expanded(
                      child: _navItem(
                        2,
                        Icons.calendar_month_outlined,
                        'Calendar',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Column(
                children: [
                  Listener(
                    key: const ValueKey('record-button'),
                    onPointerDown: (_) => _startRecording(),
                    onPointerUp: (_) => _finishRecording(),
                    onPointerCancel: (_) => _finishRecording(),
                    child: Material(
                      color: recordColor,
                      elevation: 7,
                      shadowColor: recordColor.withValues(alpha: .25),
                      shape: const CircleBorder(),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Icon(recordIcon, color: Colors.white, size: 31),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    recordLabel,
                    style: TextStyle(
                      color: recordColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _tabIndex == index;
    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 25,
            color: selected
                ? AppColors.of(context).blue
                : AppColors.of(context).muted,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? AppColors.of(context).blue
                  : AppColors.of(context).muted,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
