import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../notifications/models/notification_preferences.dart';
import '../notifications/services/notification_preferences_service.dart';
import 'profile_stat_metadata.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late Future<NotificationPreferences> _future;
  NotificationPreferences? _prefs;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = NotificationPreferencesService().getPreferences();
  }

  Future<void> _save(NotificationPreferences prefs) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _prefs = prefs;
    });

    try {
      final saved =
          await NotificationPreferencesService().updatePreferences(prefs);
      if (!mounted) return;
      setState(() => _prefs = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification preferences saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _update(NotificationPreferences prefs) {
    setState(() => _prefs = prefs);
    _save(prefs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPBg,
      appBar: AppBar(
        backgroundColor: kPBg,
        foregroundColor: kPTextPri,
        title: const Text('Notifications'),
      ),
      body: FutureBuilder<NotificationPreferences>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: kPTextSec),
              ),
            );
          }

          final prefs = _prefs ?? snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ToggleTile(
                title: 'Push notifications',
                value: prefs.pushEnabled,
                enabled: !_saving,
                onChanged: (value) => _update(
                  prefs.copyWith(pushEnabled: value),
                ),
              ),
              const SizedBox(height: 12),
              _PreferenceGroup(
                enabled: prefs.pushEnabled,
                children: [
                  _ToggleTile(
                    title: 'Level ups',
                    value: prefs.levelUpEnabled,
                    enabled: prefs.pushEnabled && !_saving,
                    onChanged: (value) => _update(
                      prefs.copyWith(levelUpEnabled: value),
                    ),
                  ),
                  _ToggleTile(
                    title: 'Quest progress',
                    value: prefs.questEnabled,
                    enabled: prefs.pushEnabled && !_saving,
                    onChanged: (value) => _update(
                      prefs.copyWith(questEnabled: value),
                    ),
                  ),
                  _ToggleTile(
                    title: 'Boss events',
                    value: prefs.bossEnabled,
                    enabled: prefs.pushEnabled && !_saving,
                    onChanged: (value) => _update(
                      prefs.copyWith(bossEnabled: value),
                    ),
                  ),
                  _ToggleTile(
                    title: 'Streak warnings',
                    value: prefs.streakEnabled,
                    enabled: prefs.pushEnabled && !_saving,
                    onChanged: (value) => _update(
                      prefs.copyWith(streakEnabled: value),
                    ),
                  ),
                  _ToggleTile(
                    title: 'Rank changes',
                    value: prefs.rankEnabled,
                    enabled: prefs.pushEnabled && !_saving,
                    onChanged: (value) => _update(
                      prefs.copyWith(rankEnabled: value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PreferenceGroup(
                enabled: prefs.pushEnabled,
                children: [
                  _ToggleTile(
                    title: 'Quiet hours',
                    value: prefs.quietHoursEnabled,
                    enabled: prefs.pushEnabled && !_saving,
                    onChanged: (value) => _update(
                      prefs.copyWith(quietHoursEnabled: value),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _HourPicker(
                          label: 'Start UTC',
                          value: prefs.quietHoursStartUtc,
                          enabled: prefs.pushEnabled &&
                              prefs.quietHoursEnabled &&
                              !_saving,
                          onChanged: (value) => _update(
                            prefs.copyWith(quietHoursStartUtc: value),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HourPicker(
                          label: 'End UTC',
                          value: prefs.quietHoursEndUtc,
                          enabled: prefs.pushEnabled &&
                              prefs.quietHoursEnabled &&
                              !_saving,
                          onChanged: (value) => _update(
                            prefs.copyWith(quietHoursEndUtc: value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_saving) ...[
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PreferenceGroup extends StatelessWidget {
  final bool enabled;
  final List<Widget> children;

  const _PreferenceGroup({
    required this.enabled,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceElevated),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: AppColors.orange,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        title,
        style: const TextStyle(
          color: kPTextPri,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _HourPicker extends StatelessWidget {
  final String label;
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _HourPicker({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.backgroundAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          onChanged: enabled
              ? (v) {
                  if (v != null) onChanged(v);
                }
              : null,
          items: [
            for (var hour = 0; hour < 24; hour++)
              DropdownMenuItem(
                value: hour,
                child: Text('${hour.toString().padLeft(2, '0')}:00'),
              ),
          ],
        ),
      ),
    );
  }
}
