import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/avatar_icons.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/services/pending_welcome.dart';
import '../../../core/shell/main_shell.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../../core/widgets/app_toast.dart';
import '../../map/models/world_map_models.dart';
import '../../map/services/world_zone_service.dart';
import '../../map/widgets/map_icon_resolver.dart';
import '../onboarding_controller.dart';
import '../widgets/onboarding_ui.dart';

/// Step 8 — imported distance on the real region trail. The hero walks to
/// the first stop the banked km can reach; "Enter the world" saves the
/// character and sets that stop as the destination (which spends the km).
class MapStep extends StatefulWidget {
  const MapStep({super.key});

  @override
  State<MapStep> createState() => _MapStepState();
}

class _Plan {
  final RegionDetail region;
  final List<ZoneNode> trail; // current zone first
  final double banked;
  final int reachIndex; // index into [trail] the banked km reaches
  final double walkedKm;

  const _Plan(
      this.region, this.trail, this.banked, this.reachIndex, this.walkedKm);

  ZoneNode get target => trail[reachIndex];
  ZoneNode? get next =>
      reachIndex + 1 < trail.length ? trail[reachIndex + 1] : null;
}

class _MapStepState extends State<MapStep> with TickerProviderStateMixin {
  static const _visible = 6;
  late final _walk = AnimationController(vsync: this);
  final _toasts = <(int, String, String?)>[];
  int _toastSeq = 0;
  _Plan? _plan;
  String? _error;
  int _lit = 0;
  bool _done = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _walk.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final service = WorldZoneService();
      final world = await service.getFullWorld();
      final regionId = world.userProgress.currentRegionId;
      if (regionId == null || regionId.isEmpty) throw StateError('no region');
      final region = await service.getRegionDetail(regionId);
      final main = region.nodes.where((n) => n.branchOf == null).toList()
        ..sort((a, b) => a.tier.compareTo(b.tier));
      var start = main.indexWhere((n) => n.id == world.userProgress.currentZoneId);
      if (start < 0) start = 0;
      final trail = main.skip(start).take(_visible).toList();
      final banked = world.userProgress.pendingDistanceKm;

      var reach = 0;
      var walked = 0.0;
      for (var i = 1; i < trail.length; i++) {
        final km = trail[i].distanceKm;
        if (walked + km > banked + 1e-6) break;
        walked += km;
        reach = i;
        final z = trail[i];
        if (z.isChest || z.isDungeon || z.isBoss || z.isCrossroads) break;
      }
      if (!mounted) return;
      setState(() => _plan = _Plan(region, trail, banked, reach, walked));
      await _play();
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn\'t load the map.');
    }
  }

  Future<void> _play() async {
    final plan = _plan!;
    final motion = onboardingMotion(context);
    await Future.delayed(Duration(milliseconds: motion ? 600 : 0));
    if (!mounted) return;
    if (plan.reachIndex > 0) {
      _walk.duration =
          Duration(milliseconds: motion ? 900 + plan.reachIndex * 700 : 0);
      _walk.addListener(_checkZones);
      await _walk.animateTo(plan.reachIndex / (plan.trail.length - 1),
          curve: Curves.easeInOutCubic);
      _walk.removeListener(_checkZones);
    }
    _checkZones();
    if (mounted) setState(() => _done = true);
  }

  void _checkZones() {
    final plan = _plan!;
    final pos = _walk.value * (plan.trail.length - 1);
    while (_lit < plan.reachIndex && pos >= _lit + 1 - .02) {
      _lit++;
      _discover(plan.trail[_lit], _lit);
    }
  }

  void _discover(ZoneNode z, int index) {
    AppMotion.haptic(AppHaptic.selection);
    final id = ++_toastSeq;
    setState(() => _toasts.insert(0, (id, '${z.name} discovered',
        zoneNodeIconAsset(z, regionTheme: _plan!.region.theme, regionName: _plan!.region.name))));
    Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _toasts.removeWhere((t) => t.$1 == id));
    });
  }

  Future<void> _enter() async {
    final ctrl = OnboardingScope.read(context);
    final plan = _plan;
    setState(() => _saving = true);
    try {
      await ctrl.completeSetup();
      if (plan != null && plan.reachIndex > 0) {
        try {
          await WorldZoneService().setDestination(plan.target.id);
        } catch (_) {
          // The km stay banked; the player can pick a destination on the map.
        }
      }
      final cls = ctrl.chosenClass;
      final devoted = ctrl.recommendation?.traitKey != null &&
          cls?.id == ctrl.recommendation?.recommendedClassId;
      PendingWelcome.set(
          'Welcome, ${devoted ? 'Devoted ' : ''}${cls?.name ?? 'hero'}. Your streak starts today.');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => MainShell(initialRingIds: ctrl.ringItems)),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, 'Couldn\'t save your hero. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = OnboardingScope.of(context);
    final plan = _plan;
    final avatar = avatarIconAsset(ctrl.avatarEmoji);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                    Color(0x8C040810), BlendMode.srcATop),
                child: Image.asset(AppIcons.homeSceneBg, fit: BoxFit.cover),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xC0040810),
                    Color(0x26040810),
                    Color(0x33040810),
                    Color(0xF2040810),
                  ],
                  stops: [0, .3, .6, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      OnboardingBackButton(onTap: ctrl.back),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Entrance(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (plan != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.green.withValues(alpha: .12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppColors.green
                                            .withValues(alpha: .3)),
                                  ),
                                  child: Text(
                                    '${plan.region.emoji} ${plan.region.name} · Ch. ${plan.region.chapterIndex}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.green),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              const Text('Your journey so far',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AnimatedBuilder(
                              animation: _walk,
                              builder: (_, __) {
                                final km = plan == null || plan.reachIndex == 0
                                    ? 0.0
                                    : plan.walkedKm *
                                        (_walk.value *
                                                (plan.trail.length - 1) /
                                                plan.reachIndex)
                                            .clamp(0.0, 1.0);
                                return Text(km.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.green));
                              },
                            ),
                            const Text('KM WALKED',
                                style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: plan == null
                        ? Center(
                            child: _error != null
                                ? Text(_error!,
                                    style: const TextStyle(
                                        color: AppColors.red, fontSize: 13))
                                : const CircularProgressIndicator(
                                    color: AppColors.green),
                          )
                        : _Trail(
                            plan: plan,
                            walk: _walk,
                            lit: _lit,
                            avatarAsset: avatar,
                          ),
                  ),
                  if (plan != null && _done)
                    Entrance(child: _NextCard(plan: plan)),
                  const SizedBox(height: 10),
                  AnimatedOpacity(
                    opacity: _done || _error != null ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: OnboardingButton(
                      label: 'ENTER THE WORLD',
                      busy: _saving,
                      onPressed: _done || _error != null ? _enter : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).padding.top + 8,
            child: Column(
              children: [
                for (final t in _toasts)
                  Padding(
                    key: ValueKey(t.$1),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Entrance(
                      from: const Offset(0, -20),
                      fromScale: .95,
                      curve: Curves.easeOutBack,
                      child: _ZoneToast(text: t.$2, icon: t.$3),
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

class _Trail extends StatelessWidget {
  final _Plan plan;
  final AnimationController walk;
  final int lit;
  final String? avatarAsset;

  const _Trail({
    required this.plan,
    required this.walk,
    required this.lit,
    required this.avatarAsset,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final n = plan.trail.length;
      final points = [
        for (var i = 0; i < n; i++)
          Offset(
            box.maxWidth * (i.isEven ? .22 : .74),
            box.maxHeight * (.9 - .8 * (n == 1 ? 0 : i / (n - 1))),
          ),
      ];
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < n; i++) {
        final a = points[i - 1], b = points[i];
        final midY = (a.dy + b.dy) / 2;
        path.cubicTo(a.dx, midY - 10, b.dx, midY + 10, b.dx, b.dy);
      }
      final metric = path.computeMetrics().first;
      // Arc length at each zone, so walk progress maps to real positions.
      final stops = <double>[0];
      for (var i = 1; i < n; i++) {
        var best = 0.0, bestD = double.infinity;
        for (double s = stops.last; s <= metric.length; s += 3) {
          final p = metric.getTangentForOffset(s)!.position;
          final d = (p - points[i]).distanceSquared;
          if (d < bestD) {
            bestD = d;
            best = s;
          }
        }
        stops.add(best);
      }
      double lengthAt(double t) {
        final x = t * (n - 1);
        final i = x.floor().clamp(0, n - 2);
        final f = x - i;
        return n == 1 ? 0 : stops[i] + (stops[i + 1] - stops[i]) * f;
      }

      return AnimatedBuilder(
        animation: walk,
        builder: (_, __) {
          final len = lengthAt(walk.value);
          final marker = metric.getTangentForOffset(len)!.position;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(box.maxWidth, box.maxHeight),
                painter: _TrailPainter(path, metric.extractPath(0, len)),
              ),
              for (var i = 0; i < n; i++)
                Positioned(
                  left: points[i].dx - 45,
                  top: points[i].dy - 34,
                  width: 90,
                  child: _ZoneNodeView(
                    node: plan.trail[i],
                    region: plan.region,
                    lit: i <= lit,
                    target: i == plan.reachIndex && plan.reachIndex > 0,
                  ),
                ),
              Positioned(
                left: marker.dx - 22,
                top: marker.dy - 22,
                child: _Marker(asset: avatarAsset),
              ),
            ],
          );
        },
      );
    });
  }
}

class _TrailPainter extends CustomPainter {
  final Path full;
  final Path done;
  _TrailPainter(this.full, this.done);

  @override
  void paint(Canvas canvas, Size size) {
    final dotted = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: .25)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final m in full.computeMetrics()) {
      for (double d = 0; d < m.length; d += 12) {
        canvas.drawPath(m.extractPath(d, d + 2), dotted);
      }
    }
    canvas.drawPath(
      done,
      Paint()
        ..color = AppColors.green
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
    );
  }

  @override
  bool shouldRepaint(_TrailPainter old) => true;
}

class _ZoneNodeView extends StatelessWidget {
  final ZoneNode node;
  final RegionDetail region;
  final bool lit;
  final bool target;
  const _ZoneNodeView(
      {required this.node,
      required this.region,
      required this.lit,
      required this.target});

  @override
  Widget build(BuildContext context) {
    final color = lit ? AppColors.green : AppColors.border;
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey(lit),
          tween: Tween(begin: lit ? 1.25 : 1, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          builder: (_, s, child) => Transform.scale(scale: s, child: child),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xBF040810),
              border: Border.all(color: color, width: 2),
              boxShadow: lit
                  ? [BoxShadow(color: AppColors.green.withValues(alpha: .4), blurRadius: 16)]
                  : null,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: lit ? 1 : .45,
              child: MapIconOrEmoji(
                asset: zoneNodeIconAsset(node,
                    regionTheme: region.theme, regionName: region.name),
                emoji: node.emoji,
                size: 52,
                emojiSize: 30,
                visualScale: 1.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          node.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: lit ? AppColors.textPrimary : AppColors.textSecondary,
            shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

class _Marker extends StatefulWidget {
  final String? asset;
  const _Marker({required this.asset});

  @override
  State<_Marker> createState() => _MarkerState();
}

class _MarkerState extends State<_Marker> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (onboardingMotion(context) && !_pulse.isAnimating) _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 40 + 24 * _pulse.value,
              height: 40 + 24 * _pulse.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.blue.withValues(alpha: .7 * (1 - _pulse.value)),
                    width: 2),
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0B1017),
              border: Border.all(color: AppColors.blue, width: 3),
            ),
            alignment: Alignment.center,
            child: widget.asset != null
                ? AppIconImage(widget.asset!, size: 34)
                : const Icon(Icons.person, size: 20, color: AppColors.blue),
          ),
        ],
      ),
    );
  }
}

class _ZoneToast extends StatelessWidget {
  final String text;
  final String? icon;
  const _ZoneToast({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF10161F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: .18)),
        boxShadow: const [
          BoxShadow(color: Color(0x8C000000), blurRadius: 30, offset: Offset(0, 12))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0B1017),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.green.withValues(alpha: .45)),
            ),
            alignment: Alignment.center,
            child: icon != null
                ? AppIconImage(icon!, size: 32)
                : const Icon(Icons.flag_rounded, color: AppColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _NextCard extends StatelessWidget {
  final _Plan plan;
  const _NextCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final t = plan.target;
    final next = plan.next;
    final left = plan.banked - plan.walkedKm;
    String title;
    String sub;
    String icon = AppIcons.mapDestination;
    if (plan.reachIndex > 0 && (t.isDungeon || t.isBoss || t.isChest || t.isCrossroads)) {
      title = 'Stopped at ${t.name}';
      sub = t.isDungeon
          ? 'Clear its trials to go on. ${left.toStringAsFixed(1)} km banked for the road ahead.'
          : t.isChest
              ? 'Open the chest to go on. ${left.toStringAsFixed(1)} km banked.'
              : '${left.toStringAsFixed(1)} km banked for what comes next.';
    } else if (next != null) {
      final away = (next.distanceKm - left).clamp(0.0, double.infinity);
      title = 'Next stop: ${next.name}';
      sub = plan.banked <= 0
          ? '${next.distanceKm.toStringAsFixed(1)} km away. Log a run, ride or walk to start moving.'
          : '${away.toStringAsFixed(1)} km away · about 1 run';
    } else {
      title = 'You reached ${t.name}';
      sub = '${left.toStringAsFixed(1)} km banked.';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: .45)),
        boxShadow: [
          BoxShadow(color: AppColors.purple.withValues(alpha: .15), blurRadius: 24)
        ],
      ),
      child: Row(
        children: [
          AppIconImage(icon, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
