import 'package:flutter/material.dart';

import 'task.dart';

const ink = Color(0xFF172443);
const muted = Color(0xFF71809D);
const blue = Color(0xFF2D58E5);
const paleBlue = Color(0xFFEAF0FF);
const red = Color(0xFFE23E4F);
const paleRed = Color(0xFFFFEFF0);
const background = Color(0xFFF4F7FC);
const border = Color(0xFFE0E7F2);

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ink,
    required this.muted,
    required this.blue,
    required this.paleBlue,
    required this.red,
    required this.paleRed,
    required this.background,
    required this.border,
    required this.surface,
  });

  final Color ink;
  final Color muted;
  final Color blue;
  final Color paleBlue;
  final Color red;
  final Color paleRed;
  final Color background;
  final Color border;
  final Color surface;

  static const light = AppColors(
    ink: Color(0xFF172443),
    muted: Color(0xFF71809D),
    blue: Color(0xFF2D58E5),
    paleBlue: Color(0xFFEAF0FF),
    red: Color(0xFFE23E4F),
    paleRed: Color(0xFFFFEFF0),
    background: Color(0xFFF4F7FC),
    border: Color(0xFFE0E7F2),
    surface: Colors.white,
  );

  static const dark = AppColors(
    ink: Color(0xFFF0F3FA),
    muted: Color(0xFFADB8CC),
    blue: Color(0xFF8BA7FF),
    paleBlue: Color(0xFF26365C),
    red: Color(0xFFFF8992),
    paleRed: Color(0xFF492B38),
    background: Color(0xFF111827),
    border: Color(0xFF344155),
    surface: Color(0xFF1D293B),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? ink,
    Color? muted,
    Color? blue,
    Color? paleBlue,
    Color? red,
    Color? paleRed,
    Color? background,
    Color? border,
    Color? surface,
  }) => AppColors(
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    blue: blue ?? this.blue,
    paleBlue: paleBlue ?? this.paleBlue,
    red: red ?? this.red,
    paleRed: paleRed ?? this.paleRed,
    background: background ?? this.background,
    border: border ?? this.border,
    surface: surface ?? this.surface,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      paleBlue: Color.lerp(paleBlue, other.paleBlue, t)!,
      red: Color.lerp(red, other.red, t)!,
      paleRed: Color.lerp(paleRed, other.paleRed, t)!,
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
    );
  }
}

String monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

String weekdayName(int weekday) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][weekday - 1];

String formattedDate(DateTime date) =>
    '${weekdayName(date.weekday)}, ${date.day} ${monthName(date.month)} ${date.year}';

String shortDate(DateTime date) =>
    '${date.day} ${monthName(date.month).substring(0, 3)}';

String formatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

bool sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String categoryName(TaskCategory category) => category.name;

Color categoryColor(TaskCategory category) => category.color;

Color categoryTint(TaskCategory category) =>
    category.color.withValues(alpha: .14);
