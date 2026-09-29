import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/motion/app_motion.dart';
import '../character/setup/setup_resume_service.dart';
import 'onboarding_controller.dart';
import 'screens/analyze_step.dart';
import 'screens/avatar_step.dart';
import 'screens/class_step.dart';
import 'screens/connect_step.dart';
import 'screens/import_step.dart';
import 'screens/level_step.dart';
import 'screens/map_step.dart';
import 'screens/welcome_step.dart';

/// Import-first onboarding: welcome → connect → import → level → read
/// training → class → avatar → map → Home. One route; steps slide between
/// each other and the current step is persisted for resume.
class OnboardingFlow extends StatefulWidget {
  final SetupResumeState initial;
  const OnboardingFlow({super.key, required this.initial});

  /// A fresh run for a player who just registered or logged in unfinished.
  factory OnboardingFlow.start({Key? key, required List<String> ringItems}) =>
      OnboardingFlow(
        key: key,
        initial: SetupResumeState(step: SetupStep.welcome, ringItems: ringItems),
      );

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final OnboardingController _ctrl = OnboardingController(_resumable());
  SetupStep _shown = SetupStep.welcome;
  bool _forward = true;

  /// Steps that depend on in-memory data restart from the nearest step that
  /// can rebuild it (the import itself is idempotent server-side).
  SetupResumeState _resumable() {
    final s = widget.initial;
    return switch (s.step) {
      SetupStep.importing when s.importJson == null => s.copyWith(step: SetupStep.connect),
      _ => s,
    };
  }

  @override
  void initState() {
    super.initState();
    _shown = _ctrl.step;
    _ctrl.addListener(_onChange);
  }

  void _onChange() {
    if (_ctrl.step == _shown) return;
    setState(() {
      _forward = _ctrl.step.index > _shown.index;
      _shown = _ctrl.step;
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChange);
    _ctrl.dispose();
    super.dispose();
  }

  Widget _screen(SetupStep step) => switch (step) {
        SetupStep.welcome => const WelcomeStep(),
        SetupStep.connect => const ConnectStep(),
        SetupStep.importing => const ImportStep(),
        SetupStep.level => const LevelStep(),
        SetupStep.analyze => const AnalyzeStep(),
        SetupStep.classReveal => const ClassStep(),
        SetupStep.avatar => const AvatarStep(),
        SetupStep.map => const MapStep(),
      };

  @override
  Widget build(BuildContext context) {
    final canGoBack = const {
      SetupStep.connect,
      SetupStep.avatar,
      SetupStep.map,
    }.contains(_shown);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canGoBack) _ctrl.back();
      },
      child: OnboardingScope(
        controller: _ctrl,
        child: ColoredBox(
          color: AppColors.background,
          child: AnimatedSwitcher(
            duration: AppMotion.duration(
                context, const Duration(milliseconds: 380)),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              final incoming = child.key == ValueKey(_shown);
              final dir = (_forward ? 1.0 : -1.0) * (incoming ? 1 : -1);
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: Offset(.08 * dir, 0), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(key: ValueKey(_shown), child: _screen(_shown)),
          ),
        ),
      ),
    );
  }
}
