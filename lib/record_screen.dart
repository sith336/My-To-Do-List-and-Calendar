import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'app_style.dart';
import 'task.dart';

enum RecordCaptureState { idle, recording, review, saved }

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    required this.onSaveTask,
    required this.onAddManually,
    required this.onCaptureStateChanged,
    required this.categories,
  });

  final Future<void> Function(TodoTask task) onSaveTask;
  final ValueChanged<String> onAddManually;
  final ValueChanged<RecordCaptureState> onCaptureStateChanged;
  final List<TaskCategory> categories;

  @override
  State<RecordScreen> createState() => RecordScreenState();
}

class RecordScreenState extends State<RecordScreen> {
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _transcriptController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool _speechReady = false;
  bool _isListening = false;
  bool _titleEdited = false;
  bool _hasDate = false;
  bool _hasTime = false;
  DateTime _taskDateTime = DateTime.now();
  TaskCategory _category = TaskCategory.personal;
  RecordCaptureState _captureState = RecordCaptureState.idle;
  String? _errorMessage;
  Future<void>? _startFuture;

  bool get isRecording => _captureState == RecordCaptureState.recording;
  bool get isReviewing => _captureState == RecordCaptureState.review;
  bool get isSaved => _captureState == RecordCaptureState.saved;

  @override
  void dispose() {
    _speech.stop();
    _transcriptController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _setCaptureState(RecordCaptureState value) {
    if (!mounted) return;
    setState(() => _captureState = value);
    widget.onCaptureStateChanged(value);
  }

  void startRecording() {
    if (_captureState == RecordCaptureState.recording) return;
    _speech.cancel();
    _transcriptController.clear();
    _titleController.clear();
    _titleEdited = false;
    _hasDate = false;
    _hasTime = false;
    _taskDateTime = DateTime.now();
    _category = widget.categories.contains(TaskCategory.personal)
        ? TaskCategory.personal
        : widget.categories.first;
    _errorMessage = null;
    _isListening = false;
    _setCaptureState(RecordCaptureState.recording);
    _startFuture = _initializeAndListen();
  }

  Future<void> _initializeAndListen() async {
    try {
      if (!_speechReady) {
        _speechReady = await _speech.initialize(
          onStatus: (status) {
            if (!mounted) return;
            setState(() => _isListening = status == 'listening');
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _isListening = false;
              _errorMessage = 'Speech recognition error: ${error.errorMsg}';
            });
          },
        );
      }
      if (!_speechReady) {
        _errorMessage = 'Speech recognition is unavailable on this device.';
        _setCaptureState(RecordCaptureState.idle);
        return;
      }
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords;
          final parsed = words.trim().isEmpty
              ? null
              : parseVoiceTask(words, DateTime.now());
          setState(() {
            _transcriptController.text = words;
            if (parsed != null) {
              if (!_titleEdited) {
                _titleController.text = titleCaseTask(parsed.title);
              }
              _taskDateTime = parsed.dateTime;
              _hasDate = parsed.hasDate;
              _hasTime = parsed.hasTime;
            }
          });
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(minutes: 1),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: false,
        ),
      );
      if (mounted) setState(() => _isListening = _speech.isListening);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _errorMessage = 'Could not start speech recognition: $error';
      });
      _setCaptureState(RecordCaptureState.idle);
    }
  }

  Future<void> stopRecording() async {
    if (_captureState != RecordCaptureState.recording) return;
    await _startFuture;
    if (!mounted || _captureState != RecordCaptureState.recording) return;
    try {
      await _speech.stop();
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Could not stop speech recognition: $error',
      );
    }
    if (!mounted) return;
    setState(() => _isListening = false);
    if (_transcriptController.text.trim().isEmpty) {
      _errorMessage =
          'No speech was recognized. Hold the microphone and try again.';
      _setCaptureState(RecordCaptureState.idle);
    } else {
      _setCaptureState(RecordCaptureState.review);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _taskDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      _taskDateTime = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _taskDateTime.hour,
        _taskDateTime.minute,
      );
      _hasDate = true;
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_taskDateTime),
    );
    if (selected == null) return;
    setState(() {
      _taskDateTime = DateTime(
        _taskDateTime.year,
        _taskDateTime.month,
        _taskDateTime.day,
        selected.hour,
        selected.minute,
      );
      _hasTime = true;
    });
  }

  Future<void> saveReviewTask() => _saveTask();

  Future<void> _saveTask() async {
    final title = titleCaseTask(_titleController.text);
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a task title before saving.')),
      );
      return;
    }
    final task = TodoTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      dateTime: _taskDateTime,
      category: _category,
    );
    try {
      await widget.onSaveTask(task);
      if (mounted) _setCaptureState(RecordCaptureState.idle);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save task: $error')));
    }
  }

  void _resetForAnotherRecording() {
    _speech.cancel();
    _transcriptController.clear();
    _titleController.clear();
    _errorMessage = null;
    _setCaptureState(RecordCaptureState.idle);
  }

  Widget _stickyHeader(BuildContext context) {
    final colors = AppColors.of(context);
    return SliverAppBar(
      pinned: true,
      primary: false,
      backgroundColor: colors.background,
      surfaceTintColor: colors.background,
      toolbarHeight: 92,
      titleSpacing: 22,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record a task',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            'Your thoughts, turned into a plan.',
            style: TextStyle(color: colors.muted, fontSize: 15),
          ),
        ],
      ),
      actions: [
        if (_captureState == RecordCaptureState.review ||
            _captureState == RecordCaptureState.recording)
          TextButton(
            onPressed: _resetForAnotherRecording,
            child: Text('Cancel', style: TextStyle(color: colors.muted)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('record'),
      slivers: [
        _stickyHeader(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (_captureState == RecordCaptureState.saved)
                _savedContent()
              else if (_captureState == RecordCaptureState.review)
                _reviewContent()
              else
                _recordPrompt(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _recordPrompt() {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _isListening ? colors.paleRed : colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                _isListening
                    ? Icons.graphic_eq_rounded
                    : Icons.touch_app_outlined,
                color: _isListening ? colors.red : colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isListening
                      ? 'Listening — let go of the button when you’re done.'
                      : 'Press and hold the microphone to speak.',
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          constraints: const BoxConstraints(minHeight: 230),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR WORDS',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _transcriptController.text.isEmpty
                    ? 'Your task will appear here as you speak.'
                    : _transcriptController.text,
                style: TextStyle(color: colors.ink, fontSize: 22, height: 1.4),
              ),
              if (_transcriptController.text.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 22),
                  child: Text(
                    'Try “Remind me to send the update tomorrow at nine”.',
                    style: TextStyle(color: colors.muted, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: TextStyle(color: colors.red)),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => widget.onAddManually(''),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Add a task manually instead'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.blue,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewContent() {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR WORDS',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _transcriptController.text,
                style: TextStyle(color: colors.ink, fontSize: 18, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'TASK TITLE',
          style: TextStyle(
            color: colors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const ValueKey('record-task-title-field'),
          controller: _titleController,
          onChanged: (_) => _titleEdited = true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Add a task title',
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'TASK DATE & TIME',
          style: TextStyle(
            color: colors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _dateTimeButton(isDate: true)),
            const SizedBox(width: 10),
            Expanded(child: _dateTimeButton(isDate: false)),
          ],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<TaskCategory>(
          initialValue: _category,
          decoration: InputDecoration(
            labelText: 'Category',
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
        TextButton.icon(
          key: const ValueKey('rerecord-button'),
          onPressed: _resetForAnotherRecording,
          icon: const Icon(Icons.refresh),
          label: const Text('Re-record'),
          style: TextButton.styleFrom(foregroundColor: colors.red),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const ValueKey('save-voice-task-button'),
          onPressed: _saveTask,
          icon: const Icon(Icons.check),
          label: const Text('Save task'),
          style: FilledButton.styleFrom(
            backgroundColor: colors.blue,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => widget.onAddManually(_titleController.text.trim()),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit manually instead'),
        ),
      ],
    );
  }

  Widget _dateTimeButton({required bool isDate}) {
    final colors = AppColors.of(context);
    final label = isDate
        ? _hasDate
              ? '${_taskDateTime.day} ${monthName(_taskDateTime.month)} ${_taskDateTime.year}'
              : 'Choose date'
        : _hasTime
        ? formatTime(_taskDateTime)
        : 'Choose time';
    return OutlinedButton(
      onPressed: isDate ? _pickDate : _pickTime,
      style: OutlinedButton.styleFrom(
        backgroundColor: _hasDate && isDate || _hasTime && !isDate
            ? colors.paleBlue
            : colors.surface,
        foregroundColor: colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDate ? 'Date' : 'Time',
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isDate ? Icons.calendar_today_outlined : Icons.access_time,
                size: 15,
              ),
              const SizedBox(width: 6),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _savedContent() {
    final colors = AppColors.of(context);
    return Column(
      children: [
        const SizedBox(height: 28),
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: colors.paleBlue,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, color: colors.blue, size: 44),
        ),
        const SizedBox(height: 18),
        Text(
          'Task saved',
          style: TextStyle(
            color: colors.ink,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your task is on the list. Hold the microphone to record another.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.muted, fontSize: 15),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          key: const ValueKey('rerecord-button'),
          onPressed: _resetForAnotherRecording,
          icon: const Icon(Icons.refresh),
          label: Text('Re-record'),
          style: OutlinedButton.styleFrom(foregroundColor: colors.blue),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => widget.onAddManually(''),
          icon: const Icon(Icons.add),
          label: const Text('Add another task manually'),
        ),
      ],
    );
  }
}
