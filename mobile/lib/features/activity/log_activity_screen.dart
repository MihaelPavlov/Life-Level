import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/level_up_notifier.dart';
import '../../core/services/inventory_full_notifier.dart';
import '../../core/services/world_zone_refresh_notifier.dart';
import '../boss/providers/boss_provider.dart';
import '../character/providers/character_provider.dart';
import '../quests/providers/quest_provider.dart';
import '../streak/providers/streak_provider.dart';
import 'activity_result_sheet.dart';
import 'models/activity_models.dart';
import 'providers/activity_provider.dart';
import '../home/providers/map_journey_provider.dart';

class LogActivityScreen extends ConsumerStatefulWidget {
  const LogActivityScreen({super.key});

  @override
  ConsumerState<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends ConsumerState<LogActivityScreen> {
  ActivityType _selectedType = ActivityType.running;
  int _durationMinutes = 30;
  double? _distanceKm;
  int? _calories;
  bool _submitting = false;

  bool get _showDistance => [
        ActivityType.running,
        ActivityType.cycling,
        ActivityType.hiking,
        ActivityType.walking,
      ].contains(_selectedType);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Log Activity',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity type
            const _SectionLabel('Activity Type'),
            const SizedBox(height: 10),
            _ActivityTypeGrid(
              selected: _selectedType,
              onSelect: (t) => setState(() {
                _selectedType = t;
                // Reset distance when switching to non-distance type
                if (![ActivityType.running, ActivityType.cycling, ActivityType.hiking, ActivityType.walking]
                    .contains(t)) {
                  _distanceKm = null;
                }
              }),
            ),
            const SizedBox(height: 24),

            // Duration
            const _SectionLabel('Duration'),
            const SizedBox(height: 10),
            _DurationPicker(
              value: _durationMinutes,
              onChanged: (v) => setState(() => _durationMinutes = v),
            ),
            const SizedBox(height: 24),

            // Distance (optional, only for running/cycling/hiking)
            if (_showDistance) ...[
              const _SectionLabel('Distance (optional)'),
              const SizedBox(height: 10),
              _NumberField(
                label: 'km',
                hint: 'e.g. 5.2',
                allowDecimal: true,
                onChanged: (v) => setState(() => _distanceKm = v),
              ),
              const SizedBox(height: 24),
            ],

            // Calories (optional)
            const _SectionLabel('Calories Burned (optional)'),
            const SizedBox(height: 10),
            _NumberField(
              label: 'kcal',
              hint: 'e.g. 350',
              allowDecimal: false,
              onChanged: (v) => setState(() => _calories = v?.toInt()),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  disabledBackgroundColor: AppColors.blue.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Log Activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final request = LogActivityRequest(
        type: _selectedType,
        durationMinutes: _durationMinutes,
        distanceKm: _distanceKm,
        calories: _calories,
      );
      final result =
          await ref.read(activityServiceProvider).logActivity(request);

      // Invalidate stale providers
      ref.invalidate(characterProfileProvider);
      ref.invalidate(dailyQuestsProvider);
      ref.invalidate(weeklyQuestsProvider);
      ref.invalidate(streakProvider);
      ref.invalidate(mapJourneyProvider);
      ref.invalidate(bossListProvider);

      WorldZoneRefreshNotifier.notify();

      // Fire level-up overlay if applicable
      if (result.leveledUp && result.newLevel != null) {
        LevelUpNotifier.notify(result.newLevel!, unlocks: result.levelUpUnlocks);
      }

      // Fire inventory-full warning for each item that was blocked
      for (final blocked in result.blockedItems) {
        InventoryFullNotifier.notify(blocked);
      }

      if (mounted) {
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => ActivityResultSheet(result: result),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log activity: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }
}

// ── Section label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Activity type grid ─────────────────────────────────────────────────────────
class _ActivityTypeGrid extends StatelessWidget {
  final ActivityType selected;
  final ValueChanged<ActivityType> onSelect;

  const _ActivityTypeGrid({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ActivityType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onSelect(type),
          child: Container(
            width: 76,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.blue.withValues(alpha: 0.15)
                  : AppColors.surface,
              border: Border.all(
                color: isSelected
                    ? AppColors.blue
                    : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Text(type.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  type.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.blue
                        : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Duration picker ────────────────────────────────────────────────────────────
class _DurationPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DurationPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(
                icon: Icons.remove,
                onTap: () {
                  if (value > 5) onChanged(value - 5);
                },
              ),
              const SizedBox(width: 24),
              Text(
                '$value min',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 24),
              _StepButton(
                icon: Icons.add,
                onTap: () {
                  if (value < 180) onChanged(value + 5);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.blue,
              inactiveTrackColor: AppColors.surfaceElevated,
              thumbColor: AppColors.blue,
              overlayColor: AppColors.blue.withValues(alpha: 0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 5,
              max: 180,
              divisions: 35,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5 min',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Text('3 hours',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}

// ── Number input field ─────────────────────────────────────────────────────────
class _NumberField extends StatelessWidget {
  final String label;
  final String hint;
  final bool allowDecimal;
  final ValueChanged<double?> onChanged;

  const _NumberField({
    required this.label,
    required this.hint,
    required this.allowDecimal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: allowDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : const TextInputType.numberWithOptions(decimal: false),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        suffixText: label,
        suffixStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
      ),
      onChanged: (text) {
        if (text.isEmpty) {
          onChanged(null);
        } else {
          final parsed = double.tryParse(text);
          onChanged(parsed);
        }
      },
    );
  }
}
