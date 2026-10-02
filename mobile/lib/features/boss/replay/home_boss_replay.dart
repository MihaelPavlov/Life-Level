import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/motion/reward_fx.dart';
import '../../../core/shell/shell_anchors.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../onboarding/widgets/activity_visuals.dart';
import '../widgets/boss_hit_fx.dart';
import 'boss_replay.dart';
import 'boss_seen_store.dart';
import 'boss_slain_takeover.dart';

/// Extra looks the Map button takes on during a Home replay.
enum BossOrbFxMode { charge, victory }

/// Read by the Map button; set only by [playHomeBossReplay].
final bossOrbFx = ValueNotifier<BossOrbFxMode?>(null);

/// Shakes whatever the shell wraps in [ShellShake].
class ShellShake extends StatefulWidget {
  final Widget child;
  const ShellShake({super.key, required this.child});

  static final _kick = ValueNotifier<(int, double)>((0, 0));

  /// [strength] in logical px of the first swing.
  static void shake([double strength = 6]) =>
      _kick.value = (_kick.value.$1 + 1, strength);

  @override
  State<ShellShake> createState() => _ShellShakeState();
}

class _ShellShakeState extends State<ShellShake>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  double _strength = 0;

  @override
  void initState() {
    super.initState();
    ShellShake._kick.addListener(_onKick);
  }

  void _onKick() {
    if (!mounted || !AppMotion.allowsDecorativeMotion(context)) return;
    _strength = ShellShake._kick.value.$2;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    ShellShake._kick.removeListener(_onKick);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) {
          if (!_c.isAnimating) return child!;
          final t = _c.value;
          final decay = 1 - t;
          final dx = math.sin(t * math.pi * 7) * _strength * decay;
          final dy = math.cos(t * math.pi * 5) * _strength * .4 * decay;
          return Transform.translate(offset: Offset(dx, dy), child: child);
        },
      );
}

/// A nudge that fresh combat may have landed (a workout logged, synced or
/// imported, the app resumed).
class BossReplayRequest {
  /// One line about the workouts themselves ("+120 XP · STR +2"); the recap
  /// carries it so no separate toast competes with the exchange.
  final String? summary;

  /// Runs when there is no boss exchange to play (no fight, or nothing new),
  /// e.g. to show the usual import toast instead.
  final VoidCallback? orElse;

  const BossReplayRequest({this.summary, this.orElse});
}

final _requests = StreamController<BossReplayRequest>.broadcast();

/// The shell answers each request by looking for unseen exchanges.
Stream<BossReplayRequest> get bossReplayRequests => _requests.stream;
void requestBossReplay({String? summary, VoidCallback? orElse}) {
  // No shell to play an exchange (e.g. a screen shown on its own).
  if (!_requests.hasListener) {
    orElse?.call();
    return;
  }
  _requests.add(BossReplayRequest(summary: summary, orElse: orElse));
}

bool _running = false;

/// True while a Home replay is on screen (the shell holds level-ups and
/// unlock ceremonies until it ends).
bool get homeBossReplayRunning => _running;

/// Plays [replay] on the Map button: each workout hits the boss, the boss
/// hits back; a kill gets the charge-up → VICTORY → Boss slain sequence and
/// a knock-out gets the K.O. stamp and the recovery popover.
Future<void> playHomeBossReplay(BuildContext context, BossReplay replay,
    {String? summary}) async {
  if (_running) return;
  _running = true;
  final store = BossSeenStore.instance;
  final id = replay.boss.id;
  try {
    store.update(id, bossHp: replay.startBossHp, youHp: replay.startYouHp);
    final motion = RewardFx.enabled(context);

    if (motion) {
      await _wait(450);
      final turns = replay.playable;
      for (final (i, t) in turns.indexed) {
        if (!context.mounted) break;
        final orb = ShellAnchors.mapOrb.center;
        if (orb == null) break;
        final combo = t.count > 1
            ? '×${t.count}'
            : turns.length > 1 && i > 0
                ? '×${turns.sublist(0, i + 1).fold(0, (a, x) => a + x.count)} COMBO'
                : null;

        if (t.finisher) await _charge(context, orb);
        if (!context.mounted) break;
        _hit(context, orb, t, combo);
        store.update(id, bossHp: t.bossHpAfter);

        if (t.finisher) {
          await _finisher(context, orb);
          break;
        }
        if (t.recovering) {
          RewardFx.floatText(context, orb + const Offset(0, -58),
              'Recovering · no attack', AppColors.textSecondary,
              pill: true, fontSize: 12);
          await _wait(1000);
          continue;
        }
        await _wait(720);
        if (!context.mounted) break;
        _counter(context, orb, t);
        store.update(id, youHp: t.youHpAfter);
        if (t.ko) {
          await _knockOut(context, orb);
        } else {
          await _wait(820);
        }
      }
    }

    BossReplayFinder.markSeen(replay);
    if (!context.mounted) return;
    if (replay.finished) {
      // The Boss slain screen is the recap of a kill.
      await showBossSlainTakeover(context, replay.boss);
    } else {
      // Nothing interrupts the exchange; what happened follows it.
      unawaited(_showRecap(context, replay, summary));
    }
  } finally {
    bossOrbFx.value = null;
    _running = false;
  }
}

Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

String _activityName(String type) =>
    type.isEmpty ? 'Workout' : type[0].toUpperCase() + type.substring(1);

/// The workout's hit: slash across the button, gold damage number.
void _hit(BuildContext context, Offset orb, BossReplayTurn t, String? combo) {
  AppMotion.haptic(t.finisher ? AppHaptic.heavy : AppHaptic.medium);
  BossSlash.play(context, orb, width: 120);
  RewardFx.burst(context, orb, AppColors.red, count: 14, distance: 54);
  RewardFx.floatText(context, orb + const Offset(0, -62), '−${_group(t.dealt)}',
      const Color(0xFFFFD27A),
      fontSize: 24,
      rise: 40,
      popScale: 1.25,
      duration: const Duration(milliseconds: 1200));
  if (combo != null) {
    RewardFx.floatText(
        context, orb + const Offset(-74, -26), combo, AppColors.orange,
        pill: true, fontSize: 12, delay: const Duration(milliseconds: 120));
  }
}

/// The boss hits back: red edges, shake, the green ring drains.
void _counter(BuildContext context, Offset orb, BossReplayTurn t) {
  AppMotion.haptic(AppHaptic.medium);
  ShellShake.shake(6);
  RewardFx.run(context,
      duration: const Duration(milliseconds: 620),
      builder: (v, _) => _Vignette(t: v));
  RewardFx.floatText(context, orb + const Offset(0, -46), '−${t.taken} HP',
      const Color(0xFFFF6B6B),
      pill: true, fontSize: 15, rise: 34, popScale: 1.2);
  if (t.blocked > 0) {
    RewardFx.floatText(context, orb + const Offset(70, -14),
        '${t.blocked} blocked', const Color(0xFF9CCAFF),
        pill: true, fontSize: 11, delay: const Duration(milliseconds: 140));
  }
}

/// 0.65 s: the screen dims, the button trembles and pulls sparks in.
Future<void> _charge(BuildContext context, Offset orb) async {
  bossOrbFx.value = BossOrbFxMode.charge;
  AppMotion.haptic(AppHaptic.light);
  await RewardFx.run(context,
      duration: const Duration(milliseconds: 650),
      builder: (t, origin) => _ChargeLayer(t: t, center: orb - origin));
  bossOrbFx.value = null;
}

/// Flash, ring shatters, shockwaves, VICTORY banner.
Future<void> _finisher(BuildContext context, Offset orb) async {
  ShellShake.shake(10);
  RewardFx.run(context,
      duration: const Duration(milliseconds: 220),
      builder: (t, _) => IgnorePointer(
          child: ColoredBox(
              color: Colors.white.withValues(alpha: .85 * (1 - t)),
              child: const SizedBox.expand())));
  bossOrbFx.value = BossOrbFxMode.victory;
  RewardFx.run(context,
      duration: const Duration(milliseconds: 850),
      builder: (t, origin) => _Shards(t: t, center: orb - origin));
  for (final (i, c) in [
    const Color(0xFFFFD27A),
    AppColors.red,
    const Color(0xFFFFE9A8)
  ].indexed) {
    RewardFx.ring(context, orb, c,
        maxRadius: 420,
        stroke: 3,
        duration: const Duration(milliseconds: 900),
        delay: Duration(milliseconds: i * 140));
  }
  RewardFx.rays(context, orb, const Color(0xFFFFD27A),
      radius: 140, duration: const Duration(milliseconds: 2000));
  RewardFx.sparkles(context, orb, count: 18);
  AppMotion.haptic(AppHaptic.heavy);
  await RewardFx.run(context,
      duration: const Duration(milliseconds: 1750),
      builder: (t, _) => _VictoryBanner(t: t));
}

/// Red flash, cracked glass from the button, the K.O. stamp.
Future<void> _knockOut(BuildContext context, Offset orb) async {
  AppMotion.haptic(AppHaptic.heavy);
  ShellShake.shake(9);
  await RewardFx.run(context,
      duration: const Duration(milliseconds: 2000),
      builder: (t, origin) => _KnockOutLayer(t: t, from: orb - origin));
}

OverlayEntry? _recap;

/// After the exchange: a pill just above the Map button with what the
/// workouts did. A knock-out adds the live recovery countdown.
Future<void> _showRecap(
    BuildContext context, BossReplay replay, String? summary) async {
  _recap?.remove();
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  final orb = ShellAnchors.mapOrb.center;
  if (overlay == null || orb == null) return;
  final until = replay.boss.recoveryEndsAt?.toLocal();
  final knockedOut =
      replay.endsKnockedOut && until != null && until.isAfter(DateTime.now());
  late OverlayEntry entry;
  void close() {
    if (entry.mounted) entry.remove();
    if (_recap == entry) _recap = null;
  }

  entry = OverlayEntry(
    builder: (_) => _RecapPill(
      replay: replay,
      recoveryUntil: knockedOut ? until : null,
      summary: summary,
      orbTop: orb.dy - 39,
      onClose: close,
    ),
  );
  _recap = entry;
  overlay.insert(entry);
  await _wait(knockedOut ? 6500 : 3600);
  close();
}

// ── layers ───────────────────────────────────────────────────────────────

class _Vignette extends StatelessWidget {
  final double t;
  const _Vignette({required this.t});

  @override
  Widget build(BuildContext context) {
    final a = t < .25 ? t / .25 : 1 - (t - .25) / .75;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.05,
            colors: [
              Colors.transparent,
              AppColors.red.withValues(alpha: .55 * a),
            ],
            stops: const [.55, 1],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ChargeLayer extends StatelessWidget {
  final double t;
  final Offset center;
  const _ChargeLayer({required this.t, required this.center});

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
          child: ColoredBox(
              color: const Color(0xFF02050A)
                  .withValues(alpha: .55 * Curves.easeOut.transform(t))),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _ChargePainter(t: t, center: center)),
        ),
      ]);
}

class _ChargePainter extends CustomPainter {
  final double t;
  final Offset center;
  _ChargePainter({required this.t, required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFFFD27A);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = gold;
    const dashes = 16;
    const r = 52.0;
    for (var i = 0; i < dashes; i++) {
      final a = t * math.pi * 3 + i * 2 * math.pi / dashes;
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), a,
          math.pi / dashes, false, ring);
    }
    final glow = Paint()
      ..color = gold.withValues(alpha: .35 * t)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center, 46, glow);
    final mote = Paint()..color = gold;
    for (var i = 0; i < 12; i++) {
      final phase = (t * 1.8 + i / 12) % 1;
      final a = i * 2 * math.pi / 12;
      final d = 90 * (1 - phase);
      canvas.drawCircle(center + Offset(math.cos(a), math.sin(a)) * d,
          3 * (1 - phase) + 1, mote);
    }
  }

  @override
  bool shouldRepaint(_ChargePainter old) => old.t != t;
}

class _Shards extends StatelessWidget {
  final double t;
  final Offset center;
  const _Shards({required this.t, required this.center});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _ShardPainter(t, center));
}

class _ShardPainter extends CustomPainter {
  final double t;
  final Offset c;
  _ShardPainter(this.t, this.c);

  @override
  void paint(Canvas canvas, Size size) {
    final e = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 15; i++) {
      final a = i * 2 * math.pi / 15 + .2;
      final dist = 40 + (70 + (i * 37) % 60) * e;
      final s = 6.0 + (i % 3) * 4;
      final p = c + Offset(math.cos(a), math.sin(a)) * dist;
      final paint = Paint()
        ..color = (i.isEven ? AppColors.red : const Color(0xFFFFD27A))
            .withValues(alpha: 1 - t);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a + t * 5);
      canvas.drawPath(
          Path()
            ..moveTo(0, -s)
            ..lineTo(s * .8, s * .8)
            ..lineTo(-s * .7, s * .4)
            ..close(),
          paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ShardPainter old) => old.t != t;
}

class _VictoryBanner extends StatelessWidget {
  final double t;
  const _VictoryBanner({required this.t});

  @override
  Widget build(BuildContext context) {
    // Slam in (0–14%), settle, hold, lift away (82–100%).
    final scale = t < .14
        ? 2.4 - 1.46 * Curves.easeOut.transform(t / .14)
        : t < .3
            ? .94 + .06 * ((t - .14) / .16)
            : 1.0;
    final opacity = t < .14
        ? t / .14
        : t > .82
            ? 1 - (t - .82) / .18
            : 1.0;
    final lift = t > .82 ? -30 * (t - .82) / .18 : 0.0;
    final streak = (t / .3).clamp(0.0, 1.0);
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -.3),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, lift),
            child: Transform.scale(
              scale: scale,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 360,
                    height: 150,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [
                        const Color(0xFF040810).withValues(alpha: .8),
                        Colors.transparent
                      ]),
                    ),
                  ),
                  Positioned(
                    top: 52,
                    child: Opacity(
                      opacity: 1 - streak,
                      child: Transform.rotate(
                        angle: -.1,
                        child: Container(
                          width: 420 * streak,
                          height: 5,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              Colors.white,
                              Colors.transparent
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFF6D8),
                          Color(0xFFFFD27A),
                          Color(0xFFD38B12),
                          Color(0xFFFFE9A8)
                        ],
                        stops: [0, .45, .6, 1],
                      ).createShader(r),
                      child: const Text(
                        'VICTORY',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 2,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                color: Color(0xFF5A3300), offset: Offset(0, 4)),
                            Shadow(color: Color(0xB3F5A623), blurRadius: 24),
                          ],
                        ),
                      ),
                    ),
                    const Text(
                      'THE BOSS FALLS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                        color: Color(0xFFFFD27A),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KnockOutLayer extends StatelessWidget {
  final double t;
  final Offset from;
  const _KnockOutLayer({required this.t, required this.from});

  @override
  Widget build(BuildContext context) {
    final fade = t < .08
        ? t / .08
        : t > .75
            ? 1 - (t - .75) / .25
            : 1.0;
    final slam = (t / .25).clamp(0.0, 1.0);
    final stampScale = 3 - 2.08 * Curves.easeOutBack.transform(slam);
    return IgnorePointer(
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    AppColors.red.withValues(alpha: .7)
                  ],
                  stops: const [.45, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
                painter:
                    _CrackPainter(from: from, grow: (t / .12).clamp(0.0, 1.0))),
          ),
          Align(
            alignment: const Alignment(0, -.35),
            child: Transform.rotate(
              angle: -.17,
              child: Transform.scale(
                scale: stampScale,
                child: const Text(
                  'K.O.',
                  style: TextStyle(
                    fontSize: 76,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 4,
                    color: AppColors.red,
                    shadows: [
                      Shadow(color: Colors.black, offset: Offset(0, 6)),
                      Shadow(color: Color(0xCCF85149), blurRadius: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CrackPainter extends CustomPainter {
  final Offset from;
  final double grow;
  _CrackPainter({required this.from, required this.grow});

  // Branches as (angle, length) hops from the button outwards.
  static const _branches = [
    [(-2.1, 90.0), (-1.9, 60.0), (-2.3, 80.0)],
    [(-1.0, 100.0), (-1.3, 90.0), (-0.8, 70.0)],
    [(-2.8, 110.0), (-3.0, 90.0)],
    [(-0.3, 120.0), (-0.1, 100.0)],
    [(-1.6, 140.0), (-1.75, 120.0), (-1.5, 90.0)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = AppColors.red.withValues(alpha: .5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xC0FFBEBE);
    for (final b in _branches) {
      final path = Path()..moveTo(from.dx, from.dy);
      var p = from;
      for (final (a, len) in b) {
        p = p + Offset(math.cos(a), math.sin(a)) * len * grow;
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(_CrackPainter old) => old.grow != grow;
}

class _RecapPill extends StatefulWidget {
  final BossReplay replay;
  final DateTime? recoveryUntil;
  final String? summary;
  final double orbTop;
  final VoidCallback onClose;

  const _RecapPill({
    required this.replay,
    required this.recoveryUntil,
    this.summary,
    required this.orbTop,
    required this.onClose,
  });

  @override
  State<_RecapPill> createState() => _RecapPillState();
}

class _RecapPillState extends State<_RecapPill> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    if (widget.recoveryUntil != null) {
      _tick =
          Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.replay;
    final n = r.workouts;
    final what =
        n == 1 ? _activityName(r.turns.first.activityType) : '$n workouts';
    final until = widget.recoveryUntil;
    final dealt = r.totalDealt;
    final title = until != null
        ? '${r.boss.name} knocked you out'
        : dealt == 0
            ? '$what synced'
            : '$what hit ${r.boss.name}';
    const gold = Color(0xFFFFD27A);
    const red = Color(0xFFFF8A80);
    final spans = <InlineSpan>[
      if (dealt > 0)
        TextSpan(
            text: '${_group(dealt)} dealt',
            style: const TextStyle(color: gold, fontWeight: FontWeight.w800)),
      if (dealt == 0) const TextSpan(text: 'You were recovering · no attack'),
      if (until != null) ...[
        const TextSpan(text: ' · attacks resume in '),
        TextSpan(
          text: formatCountdown(until.difference(DateTime.now()), long: true),
          style: const TextStyle(
              color: Color(0xFF9CCAFF),
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ] else if (dealt > 0) ...[
        const TextSpan(text: ' · '),
        TextSpan(
            text: '${r.totalTaken} taken',
            style: const TextStyle(color: red, fontWeight: FontWeight.w800)),
        TextSpan(text: ' · ${_group(r.last.bossHpAfter)} HP left'),
      ],
    ];
    final screenH = MediaQuery.sizeOf(context).height;
    return Positioned(
      left: 16,
      right: 16,
      bottom: screenH - widget.orbTop + 14,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration:
            AppMotion.duration(context, const Duration(milliseconds: 320)),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
              offset: Offset(0, 16 * (1 - v)), child: child),
        ),
        child: Semantics(
          liveRegion: true,
          label: title,
          child: GestureDetector(
            onTap: widget.onClose,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10161F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: until != null
                          ? AppColors.red.withValues(alpha: .45)
                          : const Color(0x29E6EDF3)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x8C000000),
                        blurRadius: 26,
                        offset: Offset(0, 10)),
                  ],
                ),
                child: Row(children: [
                  Stack(clipBehavior: Clip.none, children: [
                    AppIconImage(activityIcon(r.turns.last.activityType),
                        size: 32),
                    if (n > 1)
                      Positioned(
                        right: -6,
                        bottom: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('×$n',
                              style: const TextStyle(
                                  color: Color(0xFF1A1004),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: until != null
                                ? AppColors.red
                                : AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text.rich(
                          TextSpan(children: spans),
                          maxLines: 2,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              height: 1.3),
                        ),
                        if (widget.summary != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.summary!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `5:59:57`, or `5h 59m 57s` with [long].
String formatCountdown(Duration d, {bool long = false}) {
  if (d.isNegative) d = Duration.zero;
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return long ? '${h}h ${two(m)}m ${two(s)}s' : '$h:${two(m)}:${two(s)}';
}

String _group(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}
