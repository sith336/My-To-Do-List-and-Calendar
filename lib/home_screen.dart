import 'package:flutter/material.dart';

import 'app_style.dart';
import 'task.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onOpenSettings,
    required this.onToggleComplete,
    required this.onViewTask,
    required this.onDeleteTask,
  });

  final List<TodoTask> tasks;
  final ValueChanged<DateTime?> onAddTask;
  final VoidCallback onOpenSettings;
  final ValueChanged<TodoTask> onToggleComplete;
  final ValueChanged<TodoTask> onViewTask;
  final ValueChanged<TodoTask> onDeleteTask;

  List<TodoTask> _tasksOn(DateTime date) {
    final matching =
        tasks.where((task) => sameDay(task.dateTime, date)).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return matching;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final today = DateTime.now();
    final allTasks = tasks.toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final activeTaskCount = tasks.where((task) => !task.isComplete).length;
    final todayTasks = _tasksOn(today);
    final grouped = <DateTime, List<TodoTask>>{};
    for (final task in allTasks) {
      if (sameDay(task.dateTime, today)) continue;
      final date = DateTime(
        task.dateTime.year,
        task.dateTime.month,
        task.dateTime.day,
      );
      grouped.putIfAbsent(date, () => []).add(task);
    }
    final groupDates = grouped.keys.toList()..sort();
    final content = <Widget>[
      _summaryCard(activeTaskCount, today, colors),
      const SizedBox(height: 26),
      _dayHeading('Today', todayTasks.length, today, colors),
      const SizedBox(height: 12),
      if (todayTasks.isEmpty)
        _emptyDayCard(
          'Nothing on your list today. Enjoy the breathing room.',
          colors,
        )
      else
        ...todayTasks.map((task) => _homeTaskCard(task, colors)),
      for (final date in groupDates) ...[
        const SizedBox(height: 22),
        _dayHeading(
          _relativeDayName(date, today),
          grouped[date]!.length,
          date,
          colors,
        ),
        const SizedBox(height: 12),
        ...grouped[date]!.map((task) => _homeTaskCard(task, colors)),
      ],
      const SizedBox(height: 20),
      OutlinedButton.icon(
        key: const ValueKey('add-task-list-button'),
        onPressed: () => onAddTask(today),
        icon: const Icon(Icons.add),
        label: const Text('Add a task manually'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.blue,
          side: BorderSide(color: colors.border),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: colors.surface,
        ),
      ),
      const SizedBox(height: 20),
    ];

    return CustomScrollView(
      key: const PageStorageKey('home'),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: colors.background,
          surfaceTintColor: colors.background,
          toolbarHeight: 95,
          titleSpacing: 22,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To Do List',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'A little clarity for the days ahead.',
                style: TextStyle(color: colors.muted, fontSize: 15),
              ),
            ],
          ),
          actions: [
            IconButton.filledTonal(
              key: const ValueKey('add-task-button'),
              tooltip: 'Add a task manually',
              onPressed: () => onAddTask(today),
              icon: const Icon(Icons.add),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: IconButton.filledTonal(
                key: const ValueKey('open-settings-button'),
                tooltip: 'Settings',
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          sliver: SliverList(delegate: SliverChildListDelegate(content)),
        ),
      ],
    );
  }

  Widget _summaryCard(int count, DateTime today, AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.blue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedDate(today).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count ${count == 1 ? 'task' : 'tasks'} ahead',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'One thing at a time. You’ve got this.',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _dayHeading(String title, int count, DateTime date, AppColors colors) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '${shortDate(date)} · $count ${count == 1 ? 'task' : 'tasks'}',
          style: TextStyle(color: colors.muted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _emptyDayCard(String message, AppColors colors) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: colors.border),
    ),
    child: Text(message, style: TextStyle(color: colors.muted)),
  );

  Widget _homeTaskCard(TodoTask task, AppColors colors) {
    final accent = task.category.color;
    final tint = categoryTint(task.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          InkWell(
            key: ValueKey('complete-${task.title}'),
            onTap: () => onToggleComplete(task),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: task.isComplete ? accent : colors.surface,
                border: Border.all(
                  color: task.isComplete ? accent : colors.muted,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: task.isComplete
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  key: ValueKey('view-task-${task.id}'),
                  onTap: () => onViewTask(task),
                  child: Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      decoration: task.isComplete
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  formatTime(task.dateTime),
                  style: TextStyle(color: colors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: ValueKey('delete-task-${task.id}'),
            tooltip: 'Delete ${task.title}',
            onPressed: () => onDeleteTask(task),
            icon: const Icon(Icons.delete_outline),
            color: colors.muted,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Container(
            constraints: const BoxConstraints(minWidth: 75),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              task.isComplete ? 'Done' : categoryName(task.category),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _relativeDayName(DateTime date, DateTime today) {
    final difference = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    if (difference == 1) return 'Tomorrow';
    return weekdayName(date.weekday);
  }
}
