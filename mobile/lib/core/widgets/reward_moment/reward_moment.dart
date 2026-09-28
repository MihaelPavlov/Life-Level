import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_icons.dart';
import '../../motion/app_motion.dart';
import '../../motion/reward_fx.dart';
import 'reward_hud.dart';

export 'reward_hud.dart' show RewardKind, RewardHud, RewardHudTarget;

/// How big a moment is. Small, frequent news is a [banner] that doesn't
/// block; medium wins get a [card]; big wins take over the screen.
enum RewardMomentSize { banner, card, takeover }

/// A [loss] drops the accent to grey and desaturates the hero; a [warning]
/// banner stays up longer.
enum RewardMomentTone { win, warning, loss }

/// One line of the rewards "receipt".
class RewardLine {
  final RewardKind kind;
  final String label;

  /// Counted up from 0 on reveal. Ignored when [valueText] is set.
  final int amount;
  final String? valueText;

  /// Overrides the default icon for [kind].
  final Widget? icon;

  const RewardLine({
    required this.kind,
    required this.label,
    this.amount = 0,
    this.valueText,
    this.icon,
  });

  const RewardLine.xp(int amount, {String label = 'XP'})
      : this(kind: RewardKind.xp, label: label, amount: amount);

  const RewardLine.coins(int amount, {String label = 'Coins'})
      : this(kind: RewardKind.coins, label: label, amount: amount);

  const RewardLine.gems(int amount, {String label = 'Crystals'})
      : this(kind: RewardKind.gems, label: label, amount: amount);

  const RewardLine.item(String name, {String valueText = 'New', Widget? icon})
      : this(
            kind: RewardKind.item,
            label: name,
            valueText: valueText,
            icon: icon);
}

// ── Clean HUD palette ───────────────────────────────────────────────────────
const _kPanel = Color(0xFF10161F);
const _kHeroBg = Color(0xFF0B1017);
const _kTakeoverBg = Color(0xFF070B12);
const _kLine = Color(0x1AE6EDF3); // text primary @ 10%

/// One component for every game-event popup (chest opened, boss slain,
/// level up…). Clean HUD style: flat, left-aligned, rewards listed like a
/// receipt. Claiming flies each reward into its HUD element
/// ([RewardHudTarget]) before the moment closes.
class RewardMoment {
  RewardMoment._();

  static OverlayEntry? _banner;

  /// Shows a moment and completes when it has closed.
  ///
  /// [onPrimary] runs after the rewards have been claimed and the moment
  /// has closed; [onSecondary] after it has closed. Tapping outside a card
  /// (or swiping a banner away) closes it without the claim animation.
  static Future<void> show(
    BuildContext context, {
    required RewardMomentSize size,
    RewardMomentTone tone = RewardMomentTone.win,
    required Color accent,
    required Widget hero,
    required String label,
    required String title,
    String? subtitle,
    List<RewardLine> rewards = const [],
    Widget? details,
    String? primaryLabel,
    VoidCallback? onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
    Duration? bannerDuration,
  }) {
    final spec = _Spec(
      size: size,
      tone: tone,
      accent: tone == RewardMomentTone.loss ? AppColors.textSecondary : accent,
      hero: hero,
      label: label,
      title: title,
      subtitle: subtitle,
      rewards: rewards,
      details: details,
      primaryLabel: primaryLabel ??
          (rewards.isNotEmpty
              ? 'Claim'
              : size == RewardMomentSize.banner
                  ? 'OK'
                  : 'Continue'),
      onPrimary: onPrimary,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
    );
    return size == RewardMomentSize.banner
        ? _showBanner(
            context,
            spec,
            bannerDuration ??
                (tone == RewardMomentTone.win
                    ? const Duration(milliseconds: 3500)
                    : const Duration(seconds: 6)))
        : _showDialog(context, spec);
  }

  static Future<void> _showDialog(BuildContext context, _Spec spec) {
    final takeover = spec.size == RewardMomentSize.takeover;
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: !takeover,
      barrierLabel: spec.title,
      barrierColor:
          takeover ? Colors.transparent : Colors.black.withValues(alpha: 0.72),
      transitionDuration: AppMotion.duration(
          context, const Duration(milliseconds: 240),
          reduced: const Duration(milliseconds: 120)),
      pageBuilder: (_, __, ___) => _MomentView(spec: spec),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final faded = FadeTransition(opacity: curved, child: child);
        if (!AppMotion.isFull(context)) return faded;
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, takeover ? .02 : .03),
            end: Offset.zero,
          ).animate(curved),
          child: faded,
        );
      },
    );
  }

  static Future<void> _showBanner(
      BuildContext context, _Spec spec, Duration duration) {
    final done = Completer<void>();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      done.complete();
      return done.future;
    }
    _banner?.remove();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _BannerView(
        spec: spec,
        duration: duration,
        onClosed: () {
          if (_banner == entry) _banner = null;
          if (entry.mounted) entry.remove();
          if (!done.isCompleted) done.complete();
        },
      ),
    );
    _banner = entry;
    // Moments are often fired from notifier listeners mid-frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (overlay.mounted) overlay.insert(entry);
      });
    } else {
      overlay.insert(entry);
    }
    return done.future;
  }
}

class _Spec {
  final RewardMomentSize size;
  final RewardMomentTone tone;
  final Color accent;
  final Widget hero;
  final String label;
  final String title;
  final String? subtitle;
  final List<RewardLine> rewards;
  final Widget? details;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _Spec({
    required this.size,
    required this.tone,
    required this.accent,
    required this.hero,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.rewards,
    required this.details,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  bool get isLoss => tone == RewardMomentTone.loss;
}

// ─────────────────────────────────────────────────────────────────────────────
// Claim: every reward flies from its row into its HUD element.
// ─────────────────────────────────────────────────────────────────────────────

Widget _kindIcon(RewardKind kind, double size) => switch (kind) {
      RewardKind.xp => Image.asset(AppIcons.rewardXpSparkle,
          width: size, height: size, fit: BoxFit.contain),
      RewardKind.coins => Image.asset(AppIcons.homeCoinIcon,
          width: size, height: size, fit: BoxFit.contain),
      RewardKind.gems => Image.asset(AppIcons.homeGemIcon,
          width: size, height: size, fit: BoxFit.contain),
      RewardKind.item =>
        Icon(Icons.backpack_rounded, size: size, color: AppColors.orange),
      RewardKind.other =>
        Icon(Icons.star_rounded, size: size, color: AppColors.orange),
    };

Widget _lineIcon(RewardLine line, double size) => line.icon == null
    ? _kindIcon(line.kind, size)
    : SizedBox(
        width: size,
        height: size,
        child: FittedBox(child: line.icon),
      );

/// Launches the fly-to-HUD effect for [rewards] from [origins] and returns
/// when the last one lands. [fxContext] must outlive the moment (use the
/// root navigator's context).
Future<void> _flyRewards(
  BuildContext fxContext,
  List<RewardLine> rewards,
  List<Offset?> origins,
  Color accent,
) async {
  if (!RewardFx.enabled(fxContext)) return;
  final rng = math.Random();
  final flights = <Future<void>>[];
  for (var i = 0; i < rewards.length; i++) {
    final from = origins[i];
    if (from == null) continue;
    final line = rewards[i];
    final target = RewardHud.rectFor(line.kind)?.center;
    // No HUD for this reward on screen: drift up and out of view.
    final to = target ?? Offset(from.dx, -24);
    final count = line.kind == RewardKind.item || line.valueText != null
        ? 1
        : (math.log(line.amount + 1) / math.ln10 * 1.6).round().clamp(2, 5);
    final landed = <Future<void>>[];
    for (var j = 0; j < count; j++) {
      landed.add(RewardFx.fly(
        fxContext,
        child: _lineIcon(line, 22),
        from: from +
            Offset(rng.nextDouble() * 20 - 10, rng.nextDouble() * 12 - 6),
        to: to,
        lift: -60,
        sideways: rng.nextDouble() * 80 - 40,
        endScale: target == null ? .4 : .7,
        duration: const Duration(milliseconds: 560),
        delay: Duration(milliseconds: i * 120 + j * 70),
      ));
    }
    flights.add(Future.wait(landed).then((_) {
      if (target == null || !fxContext.mounted) return;
      RewardFx.burst(fxContext, target, accent, count: 8, distance: 26);
      AppMotion.haptic(AppHaptic.light);
    }));
  }
  await Future.wait(flights);
}

// ─────────────────────────────────────────────────────────────────────────────
// Card + takeover
// ─────────────────────────────────────────────────────────────────────────────

class _MomentView extends StatefulWidget {
  final _Spec spec;
  const _MomentView({required this.spec});

  @override
  State<_MomentView> createState() => _MomentViewState();
}

class _MomentViewState extends State<_MomentView>
    with SingleTickerProviderStateMixin {
  _Spec get spec => widget.spec;
  bool get _takeover => spec.size == RewardMomentSize.takeover;

  late final AnimationController _intro = AnimationController(vsync: this)
    ..addListener(() => setState(() {}));
  late final List<GlobalKey> _rowKeys =
      List.generate(spec.rewards.length, (_) => GlobalKey());
  bool _started = false;
  bool _claimed = false;

  // Reveal timeline (ms): hero, header text, details, one reward row at a
  // time with its value counting up, then the actions.
  double get _rowStep => _takeover ? 260 : 180;
  double get _countMs => _takeover ? 800 : 550;
  double get _rowsAt => spec.details == null ? 300 : 380;
  double get _actionsAt => _rowsAt + spec.rewards.length * _rowStep + 80;
  double get _totalMs => math.max(_actionsAt + 300,
      _rowsAt + math.max(0, spec.rewards.length - 1) * _rowStep + _countMs);

  double _p(double start, double len, [Curve curve = Curves.easeOutCubic]) {
    final ms = _intro.value * _totalMs;
    return curve.transform(((ms - start) / len).clamp(0.0, 1.0));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _intro.duration = Duration(milliseconds: _totalMs.round());
    if (AppMotion.isFull(context)) {
      _intro.forward();
    } else {
      _intro.value = 1;
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    if (_claimed) return;
    setState(() => _claimed = true);
    _intro.value = 1;
    final nav = Navigator.of(context, rootNavigator: true);
    final fxContext = nav.context;
    final origins = [for (final k in _rowKeys) RewardFx.centerOf(k)];
    final flying = _flyRewards(fxContext, spec.rewards, origins, spec.accent);
    // Close as the rewards take off so the HUD they land in is visible.
    if (spec.rewards.isNotEmpty && RewardFx.enabled(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    if (mounted) nav.pop();
    spec.onPrimary?.call();
    await flying;
  }

  void _secondary() {
    Navigator.of(context, rootNavigator: true).pop();
    spec.onSecondary?.call();
  }

  // ── pieces ────────────────────────────────────────────────────────────────

  Widget _rise(double start, Widget child, {double dy = 10, double len = 320}) {
    final p = _p(start, len);
    if (p >= 1) return child;
    return Opacity(
      opacity: p,
      child: Transform.translate(offset: Offset(0, dy * (1 - p)), child: child),
    );
  }

  Widget _heroTile(double size) {
    final p = _p(0, 300, Curves.easeOutBack);
    Widget hero = Padding(
      padding: EdgeInsets.all(size * .12),
      child: FittedBox(child: spec.hero),
    );
    if (spec.isLoss) {
      hero = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          .33, .33, .33, 0, 0, //
          .33, .33, .33, 0, 0, //
          .33, .33, .33, 0, 0, //
          0, 0, 0, .8, 0,
        ]),
        child: hero,
      );
    }
    return Opacity(
      opacity: _p(0, 160),
      child: Transform.scale(
        scale: .6 + .4 * p,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _kHeroBg,
            borderRadius: BorderRadius.circular(size * .24),
            border: Border.all(color: spec.accent.withValues(alpha: .45)),
          ),
          child: hero,
        ),
      ),
    );
  }

  Widget _labelText() => Text(
        spec.label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: spec.accent,
        ),
      );

  Widget _titleText(double size) => Text(
        spec.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          height: 1.15,
        ),
      );

  Widget? _subtitleText(double size) => spec.subtitle == null
      ? null
      : Text(
          spec.subtitle!,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: size,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        );

  Widget _receipt() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < spec.rewards.length; i++)
            _row(i, spec.rewards[i]),
        ],
      ),
    );
  }

  Widget _row(int i, RewardLine line) {
    final start = _rowsAt + i * _rowStep;
    final p = _p(start, 260);
    final count = _p(start, _countMs);
    final value = line.valueText ?? '+${_fmt((line.amount * count).round())}';
    return Opacity(
      opacity: p * (_claimed ? .35 : 1),
      child: Transform.translate(
        offset: Offset(-12 * (1 - p), 0),
        child: Container(
          key: _rowKeys[i],
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border:
                i == 0 ? null : const Border(top: BorderSide(color: _kLine)),
          ),
          child: Row(
            children: [
              _lineIcon(line, 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  line.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: spec.accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions() {
    final primary = FilledButton(
      onPressed: _claimed ? null : _claim,
      style: FilledButton.styleFrom(
        backgroundColor: spec.accent,
        foregroundColor: const Color(0xFF0A0A0A),
        disabledBackgroundColor: spec.accent.withValues(alpha: .5),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      child: Text(spec.primaryLabel),
    );
    if (spec.secondaryLabel == null) return primary;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _claimed ? null : _secondary,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: Color(0x2EE6EDF3)),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            child: Text(spec.secondaryLabel!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: primary),
      ],
    );
  }

  @override
  Widget build(BuildContext context) =>
      _takeover ? _buildTakeover(context) : _buildCard(context);

  Widget _buildCard(BuildContext context) {
    final sub = _subtitleText(12.5);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: _kPanel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0x2EE6EDF3)),
            ),
            clipBehavior: Clip.antiAlias,
            elevation: 16,
            shadowColor: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header band: hero tile + label, title, subtitle.
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        spec.accent.withValues(alpha: .16),
                        spec.accent.withValues(alpha: .02),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      _heroTile(58),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _rise(60, _labelText()),
                            const SizedBox(height: 3),
                            _rise(110, _titleText(19)),
                            if (sub != null) ...[
                              const SizedBox(height: 3),
                              _rise(160, sub),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (spec.details != null) ...[
                        _rise(220, spec.details!),
                        const SizedBox(height: 12),
                      ],
                      if (spec.rewards.isNotEmpty) ...[
                        _receipt(),
                        const SizedBox(height: 12),
                      ],
                      _rise(_actionsAt, _actions()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTakeover(BuildContext context) {
    final sub = _subtitleText(14);
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _claimed ? null : _claim,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .45],
              colors: [
                Color.alphaBlend(
                    spec.accent.withValues(alpha: .18), _kTakeoverBg),
                _kTakeoverBg.withValues(alpha: .97),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _heroTile(84),
                  ),
                  const SizedBox(height: 16),
                  _rise(80, _labelText()),
                  const SizedBox(height: 6),
                  _rise(130, _titleText(32)),
                  if (sub != null) ...[
                    const SizedBox(height: 6),
                    _rise(180, sub),
                  ],
                  const SizedBox(height: 22),
                  if (spec.details != null) ...[
                    _rise(240, spec.details!),
                    const SizedBox(height: 14),
                  ],
                  if (spec.rewards.isNotEmpty) ...[
                    _receipt(),
                    const SizedBox(height: 16),
                  ],
                  _rise(_actionsAt, _actions()),
                  const SizedBox(height: 12),
                  _rise(
                    _actionsAt + 120,
                    const Text(
                      'Tap anywhere to continue',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner
// ─────────────────────────────────────────────────────────────────────────────

class _BannerView extends StatefulWidget {
  final _Spec spec;
  final Duration duration;
  final VoidCallback onClosed;

  const _BannerView({
    required this.spec,
    required this.duration,
    required this.onClosed,
  });

  @override
  State<_BannerView> createState() => _BannerViewState();
}

class _BannerViewState extends State<_BannerView>
    with TickerProviderStateMixin {
  _Spec get spec => widget.spec;
  late final AnimationController _slide = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));
  late final AnimationController _timer =
      AnimationController(vsync: this, duration: widget.duration);
  final _actionKey = GlobalKey();
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _timer.addStatusListener((s) {
      if (s == AnimationStatus.completed) _close(claim: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_slide.isAnimating || _slide.value > 0) return;
    if (AppMotion.isFull(context)) {
      _slide.forward();
    } else {
      _slide.value = 1;
    }
    _timer.forward();
  }

  @override
  void dispose() {
    _slide.dispose();
    _timer.dispose();
    super.dispose();
  }

  /// [claim] flies the rewards into the HUD first (tap on the action, or
  /// the banner timing out); a swipe just dismisses.
  Future<void> _close({required bool claim, bool action = false}) async {
    if (_closing) return;
    _closing = true;
    _timer.stop();
    final fxContext = Navigator.of(context, rootNavigator: true).context;
    if (claim && spec.rewards.isNotEmpty) {
      final from = RewardFx.centerOf(_actionKey);
      unawaited(_flyRewards(fxContext, spec.rewards,
          List.filled(spec.rewards.length, from), spec.accent));
    }
    if (AppMotion.isFull(context)) {
      await _slide.animateBack(0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInCubic);
    }
    widget.onClosed();
    if (action) spec.onPrimary?.call();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 8;
    return Positioned(
      top: top,
      left: 12,
      right: 12,
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: _slide,
          builder: (context, child) {
            final p = Curves.easeOutCubic.transform(_slide.value);
            return FractionalTranslation(
              translation: Offset(0, -1.3 * (1 - p)),
              child: Opacity(opacity: p.clamp(0.0, 1.0), child: child),
            );
          },
          child: GestureDetector(
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < -100) _close(claim: false);
            },
            child: _banner(),
          ),
        ),
      ),
    );
  }

  Widget _banner() {
    return Container(
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x2EE6EDF3)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x8C000000), blurRadius: 30, offset: Offset(0, 12)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _kHeroBg,
                    borderRadius: BorderRadius.circular(11),
                    border:
                        Border.all(color: spec.accent.withValues(alpha: .45)),
                  ),
                  child: FittedBox(child: spec.hero),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        spec.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: spec.accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spec.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (spec.subtitle != null)
                        Text(
                          spec.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      if (spec.details != null) ...[
                        const SizedBox(height: 6),
                        spec.details!,
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  key: _actionKey,
                  onPressed:
                      _closing ? null : () => _close(claim: true, action: true),
                  style: TextButton.styleFrom(
                    foregroundColor: spec.accent,
                    backgroundColor: spec.accent.withValues(alpha: .12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side:
                          BorderSide(color: spec.accent.withValues(alpha: .45)),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  child: Text(spec.primaryLabel),
                ),
              ],
            ),
          ),
          // Time left before it hides itself.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _timer,
              builder: (_, __) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 1 - _timer.value,
                child: Container(
                    height: 3, color: spec.accent.withValues(alpha: .7)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Details: optional blocks shown above the rewards receipt.
// ─────────────────────────────────────────────────────────────────────────────

/// One segment per step, the first [done] lit — dungeon floors.
class RewardMomentProgress extends StatelessWidget {
  final int done;
  final int total;
  final Color color;
  const RewardMomentProgress({
    super.key,
    required this.done,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i <= done ? color : const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A wrap of coloured stat chips — item bonuses.
class RewardMomentChips extends StatelessWidget {
  final List<(String, Color)> chips;
  const RewardMomentChips({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (label, color) in chips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              border: Border.all(color: color.withValues(alpha: .35)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
      ],
    );
  }
}

/// Label / value rows — raid contribution, damage dealt.
class RewardMomentStats extends StatelessWidget {
  final List<(String, String)> rows;
  const RewardMomentStats({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A thin HP bar — how much of a boss was left.
class RewardMomentHpBar extends StatelessWidget {
  final double fraction;
  final Color color;
  const RewardMomentHpBar(
      {super.key, required this.fraction, this.color = AppColors.red});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF0D1117)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0.0, 1.0),
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// One unlocked thing (stat point, zone, item) — level up.
class RewardUnlock {
  final Widget icon;
  final String name;
  final String description;
  final String badge;
  final Color color;
  const RewardUnlock({
    required this.icon,
    required this.name,
    required this.description,
    required this.badge,
    required this.color,
  });
}

class RewardMomentUnlocks extends StatelessWidget {
  final List<RewardUnlock> unlocks;
  const RewardMomentUnlocks({super.key, required this.unlocks});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < unlocks.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : const Border(top: BorderSide(color: _kLine)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: FittedBox(child: unlocks[i].icon),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unlocks[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          unlocks[i].description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: unlocks[i].color.withValues(alpha: .1),
                      border: Border.all(
                          color: unlocks[i].color.withValues(alpha: .45)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      unlocks[i].badge,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6,
                        color: unlocks[i].color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Emoji hero, sized by the tile it sits in.
class RewardEmoji extends StatelessWidget {
  final String emoji;
  const RewardEmoji(this.emoji, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(emoji, style: const TextStyle(fontSize: 48, height: 1));
}

String _fmt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return n < 0 ? '-$b' : b.toString();
}
