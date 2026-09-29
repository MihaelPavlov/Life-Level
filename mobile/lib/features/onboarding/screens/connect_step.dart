import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/services/oauth_code_guard.dart';
import '../../../core/widgets/app_toast.dart';
import '../../character/setup/setup_resume_service.dart';
import '../../integrations/providers/integrations_provider.dart';
import '../../integrations/services/health_sync_service.dart';
import '../../integrations/services/strava_service.dart';
import '../onboarding_controller.dart';
import '../widgets/onboarding_ui.dart';

enum _SourceState { idle, connecting, done }

/// Step 2 — connect Strava or Health Connect. The workout count found is the
/// reward for connecting; "log by hand" skips straight to the class picker.
class ConnectStep extends ConsumerStatefulWidget {
  const ConnectStep({super.key});

  @override
  ConsumerState<ConnectStep> createState() => _ConnectStepState();
}

class _ConnectStepState extends ConsumerState<ConnectStep>
    with WidgetsBindingObserver {
  final _state = <String, _SourceState>{};
  final _logoKeys = {
    OnboardingSource.strava: GlobalKey(),
    OnboardingSource.health: GlobalKey(),
  };
  StreamSubscription<Uri>? _links;
  bool _awaitingStrava = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // MainShell (which normally owns deep links) isn't mounted during
    // onboarding, so listen for the Strava redirect here.
    _links = AppLinks().uriLinkStream.listen(_onLink);
    AppLinks().getInitialLink().then((uri) {
      if (uri != null) _onLink(uri);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = OnboardingScope.read(context);
      if (ctrl.source != null && ctrl.foundWorkouts != null) {
        setState(() => _state[ctrl.source!] = _SourceState.done);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _links?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the browser without authorising → stop the spinner.
    if (state == AppLifecycleState.resumed && _awaitingStrava) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _awaitingStrava) {
          setState(() {
            _awaitingStrava = false;
            _state[OnboardingSource.strava] = _SourceState.idle;
          });
        }
      });
    }
  }

  void _onLink(Uri uri) {
    if (uri.scheme != 'lifelevel' || uri.host != 'oauth') return;
    if (!uri.pathSegments.contains('strava')) return;
    final code = uri.queryParameters['code'];
    if (code == null || !OAuthCodeGuard.claim(code)) return;
    _finishStrava(code);
  }

  Future<void> _connectStrava() async {
    final ctrl = OnboardingScope.read(context);
    ctrl.chooseSource(OnboardingSource.strava);
    _markOthersIdle(OnboardingSource.strava);
    setState(() => _state[OnboardingSource.strava] = _SourceState.connecting);

    // Already linked (e.g. resumed onboarding) → just count workouts.
    final sync = ref.read(integrationSyncProvider);
    if (sync.isStravaConnected) {
      await _countStrava();
      return;
    }
    _awaitingStrava = true;
    try {
      final result = await StravaService().authorize();
      if (result != null && OAuthCodeGuard.claim(result.code)) {
        await _finishStrava(result.code, redirectUri: result.redirectUri);
      }
    } catch (e) {
      _awaitingStrava = false;
      _fail(OnboardingSource.strava, 'Could not open Strava: $e');
    }
  }

  Future<void> _finishStrava(String code, {String? redirectUri}) async {
    _awaitingStrava = false;
    if (!mounted) return;
    setState(() => _state[OnboardingSource.strava] = _SourceState.connecting);
    final error = await ref
        .read(integrationSyncProvider.notifier)
        .connectStrava(code, redirectUri: redirectUri);
    if (!mounted) return;
    if (error != null) {
      final message = error.contains('credentials are not configured')
          ? 'Local Strava credentials are not configured.'
          : 'Strava didn\'t connect. Try again.';
      _fail(OnboardingSource.strava, message);
      return;
    }
    await _countStrava();
  }

  Future<void> _countStrava() async {
    final ctrl = OnboardingScope.read(context);
    try {
      await ctrl.previewStrava();
      _done(OnboardingSource.strava);
    } catch (_) {
      _fail(OnboardingSource.strava, 'Couldn\'t read your Strava workouts.');
    }
  }

  Future<void> _connectHealth() async {
    final ctrl = OnboardingScope.read(context);
    ctrl.chooseSource(OnboardingSource.health);
    _markOthersIdle(OnboardingSource.health);
    setState(() => _state[OnboardingSource.health] = _SourceState.connecting);
    final health = HealthSyncService();
    final granted = await health.requestPermissions();
    if (!mounted) return;
    if (!granted) {
      _fail(OnboardingSource.health,
          'Allow workout access in Health Connect to import your history.');
      return;
    }
    final workouts = await health.readRecentWorkouts(days: 30);
    if (!mounted) return;
    ctrl.healthWorkouts = workouts;
    ctrl.foundWorkouts = workouts.length;
    _done(OnboardingSource.health);
  }

  void _markOthersIdle(String keep) {
    for (final k in _state.keys.toList()) {
      if (k != keep) _state[k] = _SourceState.idle;
    }
  }

  void _done(String source) {
    if (!mounted) return;
    setState(() => _state[source] = _SourceState.done);
    AppMotion.haptic(AppHaptic.light);
    final c = RewardFx.centerOf(_logoKeys[source]!);
    if (c != null) {
      RewardFx.ring(context, c, AppColors.green, maxRadius: 44);
      RewardFx.burst(context, c, AppColors.green, count: 12, distance: 36);
    }
  }

  void _fail(String source, String message) {
    if (!mounted) return;
    setState(() => _state[source] = _SourceState.idle);
    AppToast.error(context, message);
  }

  void _logByHand() {
    final ctrl = OnboardingScope.read(context);
    ctrl.chooseSource(null);
    ctrl.goTo(SetupStep.classReveal);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final connected =
        ctrl.source != null && _state[ctrl.source] == _SourceState.done;

    Widget row(int i, String key, String name, String sub, Color brand,
            String letter, VoidCallback? onTap) =>
        Entrance(
          delay: Duration(milliseconds: 220 + i * 90),
          from: const Offset(0, 20),
          child: _SourceRow(
            name: name,
            subtitle: sub,
            brand: brand,
            letter: letter,
            logoKey: _logoKeys[key],
            state: _state[key] ?? _SourceState.idle,
            found: ctrl.source == key ? ctrl.foundWorkouts : null,
            hint: i == 0 && ctrl.source == null,
            onTap: onTap,
          ),
        );

    return OnboardingScaffold(
      step: 1,
      onBack: ctrl.back,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Entrance(
              delay: Duration(milliseconds: 80),
              child: OnboardingTitle(
                'Where do you track your training?',
                subtitle:
                    'We import your last 30 days once, then new workouts sync on their own.',
              ),
            ),
            const SizedBox(height: 20),
            row(0, OnboardingSource.strava, 'Strava', 'Runs, rides, swims',
                const Color(0xFFFC4C02), 'S', _connectStrava),
            const SizedBox(height: 10),
            row(
                1,
                OnboardingSource.health,
                'Health Connect',
                'Workouts from any app on this phone',
                const Color(0xFF4285F4),
                'H',
                _connectHealth),
            const SizedBox(height: 10),
            row(2, 'garmin', 'Garmin Connect', 'Coming soon',
                const Color(0xFF007CC3), 'G', null),
            const SizedBox(height: 12),
            Entrance(
              delay: const Duration(milliseconds: 520),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceElevated),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'We only read workouts. Routes stay private unless you share them.',
                        style: TextStyle(
                            fontSize: 11.5,
                            height: 1.5,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: Entrance(
        delay: const Duration(milliseconds: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingButton(
              label: 'IMPORT MY HISTORY',
              onPressed: connected ? ctrl.next : null,
            ),
            OnboardingTextLink('I\'ll log workouts by hand', onTap: _logByHand),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatefulWidget {
  final String name;
  final String subtitle;
  final Color brand;
  final String letter;
  final GlobalKey? logoKey;
  final _SourceState state;
  final int? found;
  final bool hint;
  final VoidCallback? onTap;

  const _SourceRow({
    required this.name,
    required this.subtitle,
    required this.brand,
    required this.letter,
    required this.logoKey,
    required this.state,
    required this.found,
    required this.hint,
    required this.onTap,
  });

  @override
  State<_SourceRow> createState() => _SourceRowState();
}

class _SourceRowState extends State<_SourceRow>
    with SingleTickerProviderStateMixin {
  late final _hint = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncHint();
  }

  @override
  void didUpdateWidget(covariant _SourceRow old) {
    super.didUpdateWidget(old);
    _syncHint();
  }

  void _syncHint() {
    final on = widget.hint &&
        widget.state == _SourceState.idle &&
        onboardingMotion(context);
    if (on && !_hint.isAnimating) {
      _hint.repeat(reverse: true);
    } else if (!on && _hint.isAnimating) {
      _hint
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _hint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final done = widget.state == _SourceState.done;
    final busy = widget.state == _SourceState.connecting;

    return Semantics(
      button: !disabled,
      label: '${widget.name}, ${done ? 'connected' : widget.subtitle}',
      child: AppPressable(
        onTap: disabled || busy ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _hint,
          builder: (_, child) {
            final h = Curves.easeInOut.transform(_hint.value);
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: done
                    ? AppColors.green.withValues(alpha: .06)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: done
                      ? AppColors.green.withValues(alpha: .6)
                      : Color.lerp(AppColors.border,
                          AppColors.purple.withValues(alpha: .85), h)!,
                ),
                boxShadow: h > 0
                    ? [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: .2 * h),
                          spreadRadius: 5 * h,
                        )
                      ]
                    : null,
              ),
              child: child,
            );
          },
          child: Opacity(
            opacity: disabled ? .45 : 1,
            child: Row(
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (busy)
                        const SizedBox(
                          width: 68,
                          height: 68,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.purple,
                            backgroundColor: Color(0x2EA371F7),
                          ),
                        ),
                      AnimatedScale(
                        scale: busy ? .88 : 1,
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeInOut,
                        child: Container(
                          key: widget.logoKey,
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: widget.brand,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            widget.letter,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      if (done && widget.found != null)
                        Row(
                          children: [
                            const Text('Connected · ',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.green)),
                            CountUp(
                              value: widget.found!,
                              duration: const Duration(milliseconds: 700),
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.green),
                            ),
                            Text(
                                ' workout${widget.found == 1 ? '' : 's'} found',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.green)),
                          ],
                        )
                      else
                        Text(
                          busy ? 'Connecting…' : widget.subtitle,
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                if (done)
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                        color: AppColors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white),
                  )
                else if (!disabled && !busy)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text('Connect',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
