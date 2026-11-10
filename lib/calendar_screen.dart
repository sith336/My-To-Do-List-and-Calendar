import 'package:flutter/material.dart';

import 'app_style.dart';
import 'task.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.tasks,
    required this.onAddTask,
    required this.onOpenSettings,
    required this.onToggleComplete,
    required this.categories,
    required this.onViewTask,
    required this.onDeleteTask,
  });

  final List<TodoTask> tasks;
  final ValueChanged<DateTime?> onAddTask;
  final VoidCallback onOpenSettings;
  final ValueChanged<TodoTask> onToggleComplete;
  final List<TaskCategory> categories;
  final ValueChanged<TodoTask> onViewTask;
  final ValueChanged<TodoTask> onDeleteTask;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<TodoTask> _tasksOn(DateTime date) {
    final matching =
        widget.tasks.where((task) => sameDay(task.dateTime, date)).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return matching;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final selectedTasks = _tasksOn(_selectedDate);
    final monthDays = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final firstOffset =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday % 7;
    final cellCount = ((firstOffset + monthDays + 6) ~/ 7) * 7;
    final rows = <Widget>[];
    for (var start = 0; start < cellCount; start += 7) {
      rows.add(
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.border.withValues(alpha: .8)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: _calendarCell(start + column, monthDays, firstOffset),
                ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      key: const PageStorageKey('calendar'),
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
                'Calendar',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Make room for what matters.',
                style: TextStyle(color: colors.muted, fontSize: 15),
              ),
            ],
          ),
          actions: [
            IconButton.filledTonal(
              key: const ValueKey('calendar-add-task-button'),
              tooltip: 'Add a task',
              onPressed: () => widget.onAddTask(_selectedDate),
              icon: const Icon(Icons.add),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: IconButton.filledTonal(
                key: const ValueKey('calendar-settings-button'),
                tooltip: 'Settings',
                onPressed: widget.onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _monthSelector(),
              const SizedBox(height: 20),
              _monthTitle(),
              const SizedBox(height: 12),
              _weekdayLabels(),
              const SizedBox(height: 12),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: rows),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 2,
                runSpacing: 8,
                children: widget.categories
                    .map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _legendDot(category.color, category.name),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              _selectedDayHeading(selectedTasks.length, colors),
              const SizedBox(height: 10),
              if (selectedTasks.isEmpty)
                _emptyDayCard('No tasks planned for this day.', colors)
              else
                ...selectedTasks.map(_calendarTaskRow),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: () => widget.onAddTask(_selectedDate),
                icon: const Icon(Icons.add),
                label: const Text('Add task on this day'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.blue,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: colors.surface,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _monthSelector() {
    final colors = AppColors.of(context);
    final previous = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? colors.surface
            : const Color(0xFFE8EDF6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: () => setState(() => _visibleMonth = previous),
            icon: Icon(Icons.chevron_left, color: colors.muted),
          ),
          Expanded(
            child: Center(
              child: Text(
                monthName(_visibleMonth.month),
                style: TextStyle(
                  color: colors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: () => setState(() => _visibleMonth = next),
            icon: Icon(Icons.chevron_right, color: colors.muted),
          ),
        ],
      ),
    );
  }

  Widget _monthTitle() {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '${monthName(_visibleMonth.month)} ${_visibleMonth.year}',
            style: TextStyle(
              color: colors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('calendar-today-button'),
          onPressed: () {
            final today = DateTime.now();
            setState(() {
              _visibleMonth = DateTime(today.year, today.month);
              _selectedDate = today;
            });
          },
          child: const Text('Today'),
        ),
      ],
    );
  }

  Widget _weekdayLabels() {
    final colors = AppColors.of(context);
    return Row(
      children: const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _calendarCell(int index, int monthDays, int firstOffset) {
    final colors = AppColors.of(context);
    final day = index - firstOffset + 1;
    final inMonth = day >= 1 && day <= monthDays;
    final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    final tasks = inMonth ? _tasksOn(date) : <TodoTask>[];
    final isSelected = inMonth && sameDay(date, _selectedDate);
    final isToday = inMonth && sameDay(date, DateTime.now());
    final adjacentDay = day < 1
        ? DateTime(_visibleMonth.year, _visibleMonth.month, 0).day + day
        : day - monthDays;
    return InkWell(
      onTap: inMonth ? () => setState(() => _selectedDate = date) : null,
      child: Container(
        height: 74,
        padding: const EdgeInsets.only(top: 8, left: 3, right: 3),
        child: Column(
          children: [
            Container(
              width: 25,
              height: 25,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: isToday && !isSelected
                    ? Border.all(color: colors.blue, width: 1)
                    : null,
              ),
              child: Text(
                inMonth ? '$day' : '$adjacentDay',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : inMonth
                      ? colors.ink
                      : colors.muted,
                  fontSize: 12,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
            if (tasks.isNotEmpty) _calendarTaskPill(tasks.first),
            if (tasks.length > 1) _calendarTaskPill(tasks[1]),
          ],
        ),
      ),
    );
  }

  Widget _calendarTaskPill(TodoTask task) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2, left: 1, right: 1),
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
      decoration: BoxDecoration(
        color: categoryTint(task.category),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(color: task.category.color, fontSize: 8),
      ),
    );
  }

  Widget _selectedDayHeading(int count, AppColors colors) => Row(
    children: [
      Expanded(
        child: Text(
          '${weekdayName(_selectedDate.weekday)}, ${_selectedDate.day} ${monthName(_selectedDate.month)}',
          style: TextStyle(
            color: colors.ink,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Text(
        '$count ${count == 1 ? 'task' : 'tasks'}',
        style: TextStyle(color: colors.muted),
      ),
    ],
  );

  Widget _legendDot(Color color, String label) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 7),
      Text(label, style: TextStyle(color: AppColors.of(context).muted)),
    ],
  );

  Widget _calendarTaskRow(TodoTask task) {
    final colors = AppColors.of(context);
    final accent = task.category.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 11),
          SizedBox(
            width: 74,
            child: Text(
              formatTime(task.dateTime),
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: InkWell(
              key: ValueKey('view-task-${task.id}'),
              onTap: () => widget.onViewTask(task),
              child: Text(
                task.title,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  decoration: task.isComplete
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ),
          IconButton(
            key: ValueKey('delete-task-${task.id}'),
            tooltip: 'Delete ${task.title}',
            onPressed: () => widget.onDeleteTask(task),
            icon: const Icon(Icons.delete_outline),
            color: colors.muted,
            visualDensity: VisualDensity.compact,
          ),
          InkWell(
            key: ValueKey('complete-${task.title}'),
            onTap: () => widget.onToggleComplete(task),
            child: Icon(
              task.isComplete ? Icons.check_circle : Icons.circle_outlined,
              color: task.isComplete ? accent : colors.muted,
              size: 21,
            ),
          ),
          if (task.isComplete) ...[
            const SizedBox(width: 6),
            Text(
              'Done',
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
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
}
