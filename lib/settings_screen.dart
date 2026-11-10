import 'package:flutter/material.dart';

import 'app_style.dart';
import 'task.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.onRequestNotifications,
    required this.categories,
    required this.onAddCategory,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Future<bool> Function() onRequestNotifications;
  final List<TaskCategory> categories;
  final Future<void> Function(String name, int colorValue) onAddCategory;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isRequesting = false;
  String? _notificationMessage;

  Future<void> _createCategory() async {
    var categoryNameText = '';
    var selectedColor = TaskCategory.colorOptions.first;
    final category = await showDialog<TaskCategory>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add a category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const ValueKey('new-category-name-field'),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                onChanged: (value) => categoryNameText = value,
                decoration: const InputDecoration(labelText: 'Category name'),
              ),
              const SizedBox(height: 18),
              Text(
                'Choose a color',
                style: TextStyle(
                  color: AppColors.of(context).muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final colorValue in TaskCategory.colorOptions)
                    InkWell(
                      key: ValueKey('category-color-$colorValue'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () =>
                          setDialogState(() => selectedColor = colorValue),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          shape: BoxShape.circle,
                          border: selectedColor == colorValue
                              ? Border.all(
                                  color: AppColors.of(context).ink,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: selectedColor == colorValue
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 19,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('save-category-button'),
              onPressed: () {
                final name = categoryNameText.trim();
                if (name.isEmpty) return;
                Navigator.pop(
                  context,
                  TaskCategory(id: '', name: name, colorValue: selectedColor),
                );
              },
              child: const Text('Add category'),
            ),
          ],
        ),
      ),
    );
    if (category == null || !mounted) return;
    try {
      await widget.onAddCategory(category.name, category.colorValue);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add category: $error')));
    }
  }

  Future<void> _enableNotifications() async {
    setState(() {
      _isRequesting = true;
      _notificationMessage = null;
    });
    try {
      final granted = await widget.onRequestNotifications();
      if (!mounted) return;
      setState(() {
        _isRequesting = false;
        _notificationMessage = granted
            ? 'Due-time notifications are enabled.'
            : 'Notifications are unavailable or permission was not granted.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRequesting = false;
        _notificationMessage = 'Could not enable notifications: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return CustomScrollView(
      key: const PageStorageKey('settings'),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: colors.background,
          surfaceTintColor: colors.background,
          toolbarHeight: 88,
          titleSpacing: 22,
          title: Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'APPEARANCE',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 10),
              _themeOption(
                colors: colors,
                mode: ThemeMode.light,
                icon: Icons.light_mode_outlined,
                title: 'Light mode',
                subtitle: 'A bright, clear task list.',
              ),
              const SizedBox(height: 10),
              _themeOption(
                colors: colors,
                mode: ThemeMode.dark,
                icon: Icons.dark_mode_outlined,
                title: 'Dark mode',
                subtitle: 'A comfortable look in low light.',
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'TASK CATEGORIES',
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('add-category-button'),
                    onPressed: _createCategory,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final category in widget.categories) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        category.name,
                        style: TextStyle(
                          color: colors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'NOTIFICATIONS',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task due reminders',
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Allow notifications so the app can remind you when a task is due.',
                      style: TextStyle(color: colors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const ValueKey('enable-notifications-button'),
                      onPressed: _isRequesting ? null : _enableNotifications,
                      icon: _isRequesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_active_outlined),
                      label: const Text('Enable notifications'),
                    ),
                    if (_notificationMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _notificationMessage!,
                        style: TextStyle(color: colors.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _themeOption({
    required AppColors colors,
    required ThemeMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = widget.themeMode == mode;
    return InkWell(
      key: ValueKey('theme-${mode.name}'),
      onTap: () => widget.onThemeModeChanged(mode),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? colors.blue : colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.blue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: colors.muted)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? colors.blue : colors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
