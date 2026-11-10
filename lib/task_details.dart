import 'package:flutter/material.dart';

import 'app_style.dart';
import 'task.dart';

Future<void> showTaskDetails(
  BuildContext context,
  TodoTask task, {
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final colors = AppColors.of(context);
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      key: const ValueKey('task-details-title'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close task details',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _detailRow(
                context,
                Icons.calendar_today_outlined,
                formattedDate(task.dateTime),
              ),
              const SizedBox(height: 10),
              _detailRow(context, Icons.access_time, formatTime(task.dateTime)),
              const SizedBox(height: 10),
              _detailRow(
                context,
                Icons.label_outline,
                categoryName(task.category),
                color: task.category.color,
              ),
              const SizedBox(height: 10),
              _detailRow(
                context,
                task.isComplete
                    ? Icons.check_circle_outline
                    : Icons.circle_outlined,
                task.isComplete ? 'Done' : 'Not completed',
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                key: ValueKey('delete-task-details-${task.id}'),
                onPressed: () {
                  Navigator.pop(context);
                  onDelete();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete task'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.red,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _detailRow(
  BuildContext context,
  IconData icon,
  String text, {
  Color? color,
}) {
  final colors = AppColors.of(context);
  return Row(
    children: [
      Icon(icon, size: 19, color: color ?? colors.muted),
      const SizedBox(width: 11),
      Expanded(
        child: Text(text, style: TextStyle(color: colors.ink, fontSize: 15)),
      ),
    ],
  );
}
