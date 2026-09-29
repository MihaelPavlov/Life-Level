import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/avatar_icons.dart';
import '../../../core/constants/class_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../character/models/avatar_option.dart';
import '../../character/services/character_service.dart';
import '../onboarding_controller.dart';
import '../widgets/onboarding_ui.dart';

/// Starter avatars the setup endpoint accepts, in catalog order.
const _starters = [
  ('🧙', 'Wizard'),
  ('⚔️', 'Warrior'),
  ('🏹', 'Archer'),
  ('🛡️', 'Paladin'),
  ('🧘', 'Monk'),
  ('🐺', 'Wolf'),
  ('🦊', 'Fox'),
  ('🥷', 'Ninja'),
  ('🦸', 'Superhero'),
  ('🧝', 'Elf'),
];

/// Locked avatars with their unlock rule (mirrors the backend AvatarCatalog).
const _lockedFallback = [
  ('👑', 'Crown', 'Reach Rank Champion'),
  ('🌟', 'Star', 'Reach Level 10'),
  ('💎', 'Diamond', 'Reach Level 25'),
  ('🔮', 'Mystic', 'Complete 10 daily quests'),
  ('⚡', 'Lightning', 'Maintain a 7-day streak'),
  ('🌙', 'Moon', 'Defeat 5 bosses'),
];

/// The avatar that suits each class — pre-selected on this screen.
String suggestedAvatarFor(String? className) =>
    switch ((className ?? '').toLowerCase()) {
      'ranger' => '🏹',
      'warrior' => '⚔️',
      'mystic' => '🧘',
      'sentinel' => '🛡️',
      'tidecaller' || 'druid' => '🧝',
      'cragborn' => '🐺',
      'wayfarer' => '🦊',
      'vanguard' || 'stormrunner' => '🦸',
      'spellblade' => '🥷',
      _ => '🧙',
    };

/// Step 7 — pick how other players see you. The avatar that suits the class
/// drops into the preview; locked avatars show what they need.
class AvatarStep extends StatefulWidget {
  const AvatarStep({super.key});

  @override
  State<AvatarStep> createState() => _AvatarStepState();
}

class _AvatarStepState extends State<AvatarStep> {
  final _previewKey = GlobalKey();
  final _lockedShake = <String, GlobalKey<ShakerState>>{};
  late List<(String, String, String)> _locked = _lockedFallback;
  String _hint =
      'More avatars unlock as you level up. Tap a locked one to see what it needs.';
  int _swapTick = 0;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = OnboardingScope.read(context);
      if (ctrl.profile == null) {
        ctrl.loadLevel().then((_) {
          if (mounted) setState(() {});
        }).catchError((_) {});
      }
      final suggested = suggestedAvatarFor(ctrl.chosenClass?.name);
      final delay = onboardingMotion(context) ? 1150 : 0;
      Timer(Duration(milliseconds: delay), () {
        if (!mounted) return;
        final current = ctrl.avatarEmoji;
        final valid = _starters.any((s) => s.$1 == current);
        _select(valid ? current! : suggested, fromSuggestion: !valid);
      });
    });
  }

  Future<void> _loadCatalog() async {
    try {
      final all = await CharacterService().getAvatars();
      final starterSet = _starters.map((s) => s.$1).toSet();
      final locked = all
          .where((a) => !starterSet.contains(a.emoji))
          .map((AvatarOption a) => (
                a.emoji,
                a.name,
                a.isUnlocked
                    ? 'Unlocked. Equip it from Profile after setup'
                    : (a.unlockRequirement ?? 'Keep playing to unlock'),
              ))
          .toList();
      if (mounted && locked.isNotEmpty) setState(() => _locked = locked);
    } catch (_) {
      // Keep the built-in list.
    }
  }

  void _select(String emoji, {bool fromSuggestion = false}) {
    final ctrl = OnboardingScope.read(context);
    final suggested = suggestedAvatarFor(ctrl.chosenClass?.name);
    ctrl.chooseAvatar(emoji);
    setState(() {
      _swapTick++;
      final name = _starters.firstWhere((s) => s.$1 == emoji).$2;
      _hint = fromSuggestion
          ? 'We picked $name because it suits a ${ctrl.chosenClass?.name ?? 'hero'}. Tap any avatar to change it.'
          : emoji == suggested
              ? '$name suits a ${ctrl.chosenClass?.name ?? 'hero'}. Good pick.'
              : 'You can change your avatar any time from Profile.';
    });
    AppMotion.haptic(AppHaptic.selection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = RewardFx.centerOf(_previewKey);
      if (c != null && mounted) {
        RewardFx.ring(context, c, AppColors.orange, maxRadius: 70);
        RewardFx.burst(context, c, AppColors.orange, count: 16, distance: 60);
      }
    });
  }

  void _tapLocked(String emoji, String name, String requirement) {
    _lockedShake[emoji]?.currentState?.shake(amplitude: 4, ms: 300);
    final ctrl = OnboardingScope.read(context);
    final level = ctrl.profile?.level;
    final lvlMatch = RegExp(r'Level (\d+)').firstMatch(requirement);
    setState(() {
      _hint = '🔒 $name · $requirement.'
          '${lvlMatch != null && level != null ? ' You\'re Level $level of ${lvlMatch.group(1)}.' : ''}';
    });
  }

  double _progress(String requirement) {
    final m = RegExp(r'Level (\d+)').firstMatch(requirement);
    final level = OnboardingScope.read(context).profile?.level ?? 1;
    if (m == null) return 0;
    return (level / int.parse(m.group(1)!)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final cls = ctrl.chosenClass;
    final selected = ctrl.avatarEmoji;
    final suggested = suggestedAvatarFor(cls?.name);
    final classColor = classColorForName(cls?.name);
    final devoted = ctrl.recommendation?.traitKey != null &&
        cls?.id == ctrl.recommendation?.recommendedClassId;

    return OnboardingScaffold(
      step: 4,
      onBack: ctrl.back,
      glow: AppColors.orange,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Entrance(
              child: OnboardingTitle(
                'Choose Your Avatar',
                subtitle:
                    'This is how other players will see you on the map and leaderboards.',
              ),
            ),
            const SizedBox(height: 10),
            if (cls != null)
              Entrance(
                delay: const Duration(milliseconds: 140),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceElevated),
                  ),
                  child: Row(
                    children: [
                      ClassIcon(className: cls.name, size: 30),
                      const SizedBox(width: 10),
                      Text('${devoted ? 'Devoted ' : ''}${cls.name}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: classColor)),
                      const Spacer(),
                      const Text('YOUR CLASS',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .6,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Center(
              child: Entrance.pop(
                delay: const Duration(milliseconds: 250),
                child: AnimatedContainer(
                  key: _previewKey,
                  duration: const Duration(milliseconds: 200),
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.blue.withValues(alpha: .2),
                        AppColors.purple.withValues(alpha: .2),
                      ],
                    ),
                    border: Border.all(
                      color: selected != null
                          ? AppColors.orange.withValues(alpha: .6)
                          : AppColors.blue.withValues(alpha: .4),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (selected != null
                                ? AppColors.orange
                                : AppColors.blue)
                            .withValues(alpha: .2),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: selected == null
                      ? const Text('?',
                          style: TextStyle(
                              fontSize: 36, color: AppColors.textSecondary))
                      : TweenAnimationBuilder<double>(
                          key: ValueKey(_swapTick),
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(
                              milliseconds:
                                  onboardingMotion(context) ? 460 : 0),
                          builder: (_, t, child) {
                            final s = t < .7
                                ? .3 + .82 * Curves.easeOut.transform(t / .7)
                                : 1.12 - .12 * ((t - .7) / .3);
                            return Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: Transform.rotate(
                                angle: -.44 * (1 - t),
                                child: Transform.scale(scale: s, child: child),
                              ),
                            );
                          },
                          child: AppIconImage(
                              avatarIconAsset(selected) ?? '', size: 76),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                selected == null
                    ? ''
                    : _starters.firstWhere((s) => s.$1 == selected).$2,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 10),
            const _Section('AVAILABLE'),
            const SizedBox(height: 8),
            _Grid(
              children: [
                for (var i = 0; i < _starters.length; i++)
                  Entrance(
                    delay: Duration(milliseconds: 380 + i * 40),
                    duration: const Duration(milliseconds: 380),
                    from: Offset.zero,
                    fromScale: .6,
                    curve: Curves.easeOutBack,
                    child: _AvatarTile(
                      emoji: _starters[i].$1,
                      name: _starters[i].$2,
                      picked: selected == _starters[i].$1,
                      fitsClass: suggested == _starters[i].$1 ? cls?.name : null,
                      fitColor: classColor,
                      onTap: () => _select(_starters[i].$1),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const _Section('LOCKED · UNLOCK AS YOU PLAY'),
            const SizedBox(height: 8),
            _Grid(
              children: [
                for (var i = 0; i < _locked.length; i++)
                  Entrance(
                    delay: Duration(milliseconds: 700 + i * 40),
                    duration: const Duration(milliseconds: 380),
                    from: Offset.zero,
                    fromScale: .6,
                    curve: Curves.easeOutBack,
                    child: Shaker(
                      key: _lockedShake.putIfAbsent(
                          _locked[i].$1, () => GlobalKey<ShakerState>()),
                      child: _LockedTile(
                        emoji: _locked[i].$1,
                        name: _locked[i].$2,
                        progress: _progress(_locked[i].$3),
                        onTap: () => _tapLocked(
                            _locked[i].$1, _locked[i].$2, _locked[i].$3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Entrance(
              delay: const Duration(milliseconds: 950),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(_hint),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceElevated),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_hint,
                            style: const TextStyle(
                                fontSize: 11,
                                height: 1.45,
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: Entrance(
        delay: const Duration(milliseconds: 1000),
        child: OnboardingButton(
          label: 'CONTINUE',
          onPressed: selected == null ? null : ctrl.next,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: .6,
          color: AppColors.textSecondary));
}

class _Grid extends StatelessWidget {
  final List<Widget> children;
  const _Grid({required this.children});

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: children,
      );
}

class _AvatarTile extends StatelessWidget {
  final String emoji;
  final String name;
  final bool picked;
  final String? fitsClass;
  final Color fitColor;
  final VoidCallback onTap;

  const _AvatarTile({
    required this.emoji,
    required this.name,
    required this.picked,
    required this.fitsClass,
    required this.fitColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: picked,
      label: name,
      child: AppPressable(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: picked
                    ? AppColors.orange.withValues(alpha: .08)
                    : AppColors.surface,
                border: Border.all(
                  color: picked
                      ? AppColors.orange.withValues(alpha: .6)
                      : AppColors.surfaceElevated,
                  width: picked ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: picked
                    ? [
                        BoxShadow(
                            color: AppColors.orange.withValues(alpha: .15),
                            blurRadius: 10)
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: AppIconImage(avatarIconAsset(emoji) ?? '', size: 48),
            ),
            if (fitsClass != null)
              Positioned(
                bottom: -7,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1017),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: fitColor.withValues(alpha: .45)),
                  ),
                  child: Text(
                    'SUITS ${fitsClass!.toUpperCase()}',
                    style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .4,
                        color: fitColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LockedTile extends StatelessWidget {
  final String emoji;
  final String name;
  final double progress;
  final VoidCallback onTap;

  const _LockedTile({
    required this.emoji,
    required this.name,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final asset = avatarIconAsset(emoji);
    return Semantics(
      button: true,
      label: '$name, locked',
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: .4,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.surfaceElevated),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: asset != null
                    ? AppIconImage(asset, size: 44)
                    : Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: AppColors.surface, shape: BoxShape.circle),
                  child: const Icon(Icons.lock,
                      size: 9, color: AppColors.textSecondary),
                ),
              ),
              if (progress > 0)
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 3,
                      child: Stack(
                        children: [
                          Container(color: AppColors.surfaceElevated),
                          FractionallySizedBox(
                            widthFactor: math.max(.05, progress),
                            child: Container(color: AppColors.purple),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
