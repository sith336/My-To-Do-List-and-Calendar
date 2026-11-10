import 'package:flutter/material.dart';

class TaskCategory {
  const TaskCategory({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  final String id;
  final String name;
  final int colorValue;

  Color get color => Color(colorValue);

  static const work = TaskCategory(
    id: 'work',
    name: 'Work',
    colorValue: 0xFF2D58E5,
  );
  static const personal = TaskCategory(
    id: 'personal',
    name: 'Personal',
    colorValue: 0xFFE23E4F,
  );
  static const defaults = [work, personal];
  static const colorOptions = [
    0xFF2D58E5,
    0xFFE23E4F,
    0xFF1A9B79,
    0xFF8A4DE8,
    0xFFE78A22,
    0xFFCE4D9A,
    0xFF168AAB,
    0xFF68758A,
  ];

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
  };

  factory TaskCategory.fromJson(Map<String, Object?> json) => TaskCategory(
    id: json['id']! as String,
    name: json['name']! as String,
    colorValue: json['colorValue']! as int,
  );

  factory TaskCategory.fromLegacyName(String name) => switch (name) {
    'work' => work,
    'personal' => personal,
    _ => personal,
  };

  @override
  bool operator ==(Object other) => other is TaskCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

String titleCaseTask(String value) => value.trim().replaceAllMapped(
  RegExp(r'[A-Za-z0-9À-ÖØ-öø-ÿ]+'),
  (match) =>
      '${match[0]![0].toUpperCase()}${match[0]!.substring(1).toLowerCase()}',
);

class TodoTask {
  TodoTask({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.category,
    this.isComplete = false,
  });

  final String id;
  final String title;
  final DateTime dateTime;
  final TaskCategory category;
  bool isComplete;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'dateTime': dateTime.toIso8601String(),
    'category': category.toJson(),
    'isComplete': isComplete,
  };

  factory TodoTask.fromJson(Map<String, Object?> json) => TodoTask(
    id: json['id']! as String,
    title: json['title']! as String,
    dateTime: DateTime.parse(json['dateTime']! as String),
    category: switch (json['category']) {
      final Map<String, Object?> categoryJson => TaskCategory.fromJson(
        categoryJson,
      ),
      final String legacyName => TaskCategory.fromLegacyName(legacyName),
      _ => TaskCategory.personal,
    },
    isComplete: json['isComplete'] as bool? ?? false,
  );
}

class ParsedTask {
  const ParsedTask({
    required this.title,
    required this.dateTime,
    required this.hasDate,
    required this.hasTime,
  });

  final String title;
  final DateTime dateTime;
  final bool hasDate;
  final bool hasTime;
}

ParsedTask parseVoiceTask(String words, DateTime now) {
  var remaining = words.trim();
  var dueDate = DateTime(now.year, now.month, now.day);
  var hasDate = false;
  int? hour;
  int? minute;

  final monthPattern = RegExp(
    r'\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})(?:,?\s+(\d{4}))?\b',
    caseSensitive: false,
  );
  final monthMatch = monthPattern.firstMatch(remaining);
  if (monthMatch != null) {
    final month = _monthNumber(monthMatch.group(1)!);
    final day = int.parse(monthMatch.group(2)!);
    final year = int.tryParse(monthMatch.group(3) ?? '') ?? now.year;
    dueDate = DateTime(year, month, day);
    if (monthMatch.group(3) == null &&
        dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
      dueDate = DateTime(year + 1, month, day);
    }
    hasDate = true;
    remaining = remaining.replaceRange(monthMatch.start, monthMatch.end, ' ');
  }

  final relativeDate = RegExp(
    r'\b(today|tomorrow|next week|in\s+\d+\s+days)\b',
    caseSensitive: false,
  ).firstMatch(remaining);
  if (relativeDate != null) {
    final phrase = relativeDate.group(1)!.toLowerCase();
    final days = phrase == 'tomorrow'
        ? 1
        : phrase == 'next week'
        ? 7
        : phrase.startsWith('in ')
        ? int.parse(RegExp(r'\d+').firstMatch(phrase)!.group(0)!)
        : 0;
    dueDate = DateTime(now.year, now.month, now.day).add(Duration(days: days));
    hasDate = true;
    remaining = remaining.replaceRange(
      relativeDate.start,
      relativeDate.end,
      ' ',
    );
  } else {
    final weekdayMatch = RegExp(
      r'\b(?:next\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
      caseSensitive: false,
    ).firstMatch(remaining);
    if (weekdayMatch != null) {
      final weekday = _weekdayNumber(weekdayMatch.group(1)!);
      var difference = (weekday - now.weekday + 7) % 7;
      if (difference == 0 ||
          weekdayMatch.group(0)!.toLowerCase().startsWith('next ')) {
        difference += 7;
      }
      dueDate = DateTime(now.year, now.month, now.day + difference);
      hasDate = true;
      remaining = remaining.replaceRange(
        weekdayMatch.start,
        weekdayMatch.end,
        ' ',
      );
    }
  }

  for (final timeMatch in _voiceTimePattern.allMatches(remaining)) {
    final cue = timeMatch.namedGroup('cue');
    final suffix =
        (timeMatch.namedGroup('suffix') ?? timeMatch.namedGroup('wordSuffix'))
            ?.toLowerCase()
            .replaceAll('.', '');
    final wordHour = timeMatch.namedGroup('wordHour');
    final hasExplicitTime =
        cue != null ||
        suffix != null ||
        timeMatch.namedGroup('minute') != null ||
        timeMatch.namedGroup('wordMinute') != null;
    if (hasExplicitTime) {
      hour = wordHour == null
          ? int.parse(timeMatch.namedGroup('numericHour')!)
          : _wordNumber(wordHour);
      minute =
          int.tryParse(timeMatch.namedGroup('minute') ?? '') ??
          _wordMinute(timeMatch.namedGroup('wordMinute'));
      if (hour >= 0 &&
          hour <= (suffix == null ? 23 : 12) &&
          minute >= 0 &&
          minute < 60) {
        if (suffix?.startsWith('p') == true && hour < 12) hour += 12;
        if (suffix?.startsWith('a') == true && hour == 12) hour = 0;
        remaining = remaining.replaceRange(timeMatch.start, timeMatch.end, ' ');
        break;
      } else {
        hour = null;
        minute = null;
      }
    }
  }

  remaining = remaining
      .replaceFirst(RegExp(r'\bremind\s+me\s+to\b', caseSensitive: false), '')
      .replaceFirst(RegExp(r'\bplease\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'\b(on|at)\b', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s,.:;]+|[\s,.:;]+$'), '')
      .trim();

  return ParsedTask(
    title: remaining.isEmpty ? words.trim() : remaining,
    dateTime: DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      hour ?? 9,
      minute ?? 0,
    ),
    hasDate: hasDate,
    hasTime: hour != null,
  );
}

final _voiceTimePattern = RegExp(
  r'\b(?:(?<cue>at|by|around|about|for)\s+)?(?:(?<numericHour>\d{1,2})(?:(?::|\.)(?<minute>\d{2}))?\s*(?<suffix>a\.?m\.?|p\.?m\.?)|(?<wordHour>one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)(?:\s+(?<wordMinute>five|ten|fifteen|twenty|twenty-five|thirty|thirty-five|forty|forty-five|fifty|fifty-five))?(?:\s+(?<wordSuffix>am|pm))?)\b',
  caseSensitive: false,
);

int _wordMinute(String? value) => switch (value?.toLowerCase()) {
  'five' => 5,
  'ten' => 10,
  'fifteen' => 15,
  'twenty' => 20,
  'twenty-five' => 25,
  'thirty' => 30,
  'thirty-five' => 35,
  'forty' => 40,
  'forty-five' => 45,
  'fifty' => 50,
  'fifty-five' => 55,
  _ => 0,
};

int _monthNumber(String name) => const {
  'january': 1,
  'february': 2,
  'march': 3,
  'april': 4,
  'may': 5,
  'june': 6,
  'july': 7,
  'august': 8,
  'september': 9,
  'october': 10,
  'november': 11,
  'december': 12,
}[name.toLowerCase()]!;

int _weekdayNumber(String name) => const {
  'monday': DateTime.monday,
  'tuesday': DateTime.tuesday,
  'wednesday': DateTime.wednesday,
  'thursday': DateTime.thursday,
  'friday': DateTime.friday,
  'saturday': DateTime.saturday,
  'sunday': DateTime.sunday,
}[name.toLowerCase()]!;

int _wordNumber(String name) => const {
  'one': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'eleven': 11,
  'twelve': 12,
}[name.toLowerCase()]!;
