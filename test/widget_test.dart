import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytodolist/main.dart';
import 'package:mytodolist/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('voice parsing extracts a relative date, time, and task title', () {
    final parsed = parseVoiceTask(
      'Remind me to send the project update tomorrow at nine.',
      DateTime(2026, 11, 10, 15),
    );

    expect(parsed.title, 'send the project update');
    expect(parsed.dateTime, DateTime(2026, 11, 11, 9));
    expect(parsed.hasDate, isTrue);
    expect(parsed.hasTime, isTrue);
  });

  test('voice parsing marks missing date and time for review', () {
    final parsed = parseVoiceTask(
      'Call the dentist',
      DateTime(2026, 11, 10, 15),
    );

    expect(parsed.title, 'Call the dentist');
    expect(parsed.hasDate, isFalse);
    expect(parsed.hasTime, isFalse);
  });

  test('task titles capitalize the first letter of each word', () {
    expect(titleCaseTask('call the dentist'), 'Call The Dentist');
  });

  test('saved tasks still read legacy built-in category values', () {
    final task = TodoTask.fromJson({
      'id': 'legacy',
      'title': 'Call The Dentist',
      'dateTime': '2026-11-10T09:00:00.000',
      'category': 'work',
      'isComplete': false,
    });

    expect(task.category, TaskCategory.work);
    expect(task.toJson()['category'], TaskCategory.work.toJson());
  });

  test('voice parsing recognizes a weekday and explicit time', () {
    final parsed = parseVoiceTask(
      'Book an appointment next Friday at 2:30 PM',
      DateTime(2026, 11, 10),
    );

    expect(parsed.title, 'Book an appointment');
    expect(parsed.dateTime, DateTime(2026, 11, 20, 14, 30));
  });

  test('voice parsing recognizes common numeric and spoken time formats', () {
    final numeric = parseVoiceTask(
      'Submit the report tomorrow at 6:45 p.m.',
      DateTime(2026, 11, 10, 15),
    );
    expect(numeric.title, 'Submit the report');
    expect(numeric.dateTime, DateTime(2026, 11, 11, 18, 45));
    expect(numeric.hasTime, isTrue);

    final spoken = parseVoiceTask(
      'Call Sam at five thirty pm',
      DateTime(2026, 11, 10, 15),
    );
    expect(spoken.title, 'Call Sam');
    expect(spoken.dateTime, DateTime(2026, 11, 10, 17, 30));
    expect(spoken.hasTime, isTrue);
  });

  test('voice parsing skips unrelated numbers before the due time', () {
    final parsed = parseVoiceTask(
      'Buy 3 apples at 5 pm',
      DateTime(2026, 11, 10, 15),
    );

    expect(parsed.title, 'Buy 3 apples');
    expect(parsed.dateTime, DateTime(2026, 11, 10, 17));
    expect(parsed.hasTime, isTrue);
  });

  testWidgets('manual tasks can be added from the home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('To Do List'), findsOneWidget);
    expect(
      find.text('Nothing on your list today. Enjoy the breathing room.'),
      findsOneWidget,
    );
    expect(find.text('Review project brief'), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('add-task-button')));
    await tester.tap(find.byKey(const ValueKey('add-task-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('task-title-field')),
      'Call the dentist',
    );
    await tester.tap(find.byKey(const ValueKey('save-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Call The Dentist'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('complete-Call The Dentist')));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('task details can be viewed and deleted', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-task-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('task-title-field')),
      'Pay the bill',
    );
    await tester.tap(find.byKey(const ValueKey('save-task-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pay The Bill'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('task-details-title')), findsOneWidget);
    expect(find.text('Pay The Bill'), findsNWidgets(2));
    await tester.tap(find.text('Delete task'));
    await tester.pumpAndSettle();
    expect(find.text('Delete task?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-delete-task')));
    await tester.pumpAndSettle();
    expect(find.text('Pay The Bill'), findsNothing);
  });

  testWidgets('navigation opens the calendar screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(find.text('Make room for what matters.'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('SUN'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calendar-add-task-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('task-title-field')), findsOneWidget);
  });

  testWidgets('record screen explains press-and-hold capture', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('record-button')));
    await tester.pumpAndSettle();

    expect(find.text('Record a task'), findsOneWidget);
    expect(
      find.text('Press and hold the microphone to speak.'),
      findsOneWidget,
    );
  });

  testWidgets('settings can switch the app to dark mode', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-dark')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Task due reminders'), findsOneWidget);
  });

  testWidgets('custom colored categories can be created and assigned', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('open-settings-button')),
    );
    await tester.tap(find.byKey(const ValueKey('open-settings-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('add-category-button')),
    );
    await tester.tap(find.byKey(const ValueKey('add-category-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('new-category-name-field')),
      'Study',
    );
    await tester.tap(
      find.byKey(ValueKey('category-color-${TaskCategory.colorOptions[2]}')),
    );
    await tester.tap(find.byKey(const ValueKey('save-category-button')));
    await tester.pumpAndSettle();

    expect(find.text('Study'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('add-task-button')));
    await tester.tap(find.byKey(const ValueKey('add-task-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Study').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('task-title-field')),
      'Read a chapter',
    );
    await tester.tap(find.byKey(const ValueKey('save-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Study'), findsOneWidget);
    expect(find.text('Read A Chapter'), findsOneWidget);
  });
}
