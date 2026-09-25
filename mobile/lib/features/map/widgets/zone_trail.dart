import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/reward_fx.dart';
import '../models/encounter_models.dart';
import '../models/world_map_models.dart';
import 'zone_node_tile.dart';

/// A banked-km journey for the trail to play ("trail walk"): the walker hops
/// from [fromZoneId] to wherever the freshly loaded trail puts the player,
/// counting [bankedKm] down on its tag. [done] completes once the arrival
/// (or "km to go") moment has played, so the caller can continue.
class TrailTravel {
  final int id;
  final String fromZoneId;
  final double bankedKm;
  final Completer<void> done = Completer<void>();
  TrailTravel(
      {required this.id, required this.fromZoneId, required this.bankedKm});
}

/// Duolingo-style vertical trail of zone bubbles connected by status-coloured
/// cubic Bezier curves. Mirrors `.rv3-trail` in
/// `design-mockup/map/WORLD-MAP-FINAL-MOCKUP.html` — bubbles alternate left /
/// right by index with boss and crossroads forced to the centre, and the SVG
/// curve layer sits behind them.
class ZoneTrail extends StatefulWidget {
  final List<ZoneNode> nodes;
  final List<ZoneEdge> edges;
  final ActiveJourney? journey;
  final String? nextRegionName;
  final RegionTheme? regionTheme;
  final String? regionName;

  /// Character avatar rendered on the walker token. When null, the walker is
  /// suppressed — we'd rather show nothing than a placeholder.
  final String? avatarEmoji;

  final void Function(ZoneNode) onTap;

  /// When provided, attached to the bubble of the node currently in
  /// [ZoneNodeStatus.active]. Lets the parent screen call
  /// `Scrollable.ensureVisible` to auto-scroll to the active zone.
  final Key? activeNodeKey;
  final Map<String, Key> keysByNodeId;

  final List<TrailEncounterNode> encounters;
  final void Function(TrailEncounterNode)? onEncounterTap;

  /// Set right after a banked-km "Travel here" to animate the journey.
  final TrailTravel? travel;

  const ZoneTrail({
    super.key,
    required this.nodes,
    required this.edges,
    required this.journey,
    required this.nextRegionName,
    this.regionTheme,
    this.regionName,
    required this.avatarEmoji,
    required this.onTap,
    this.activeNodeKey,
    this.keysByNodeId = const {},
    this.encounters = const [],
    this.onEncounterTap,
    this.travel,
  });

  static const double _rowHeight = 110;
  static const double _tailSpace = 24;

  @override
  State<ZoneTrail> createState() => _ZoneTrailState();

  /// Groups nodes by `tier`. Single-node tiers alternate left / right (with
  /// boss / crossroads forced to centre); two-node tiers — the branches of a
  /// crossroads — render side-by-side at `left` and `right` slots.
  ///
  /// Returned list is aligned to `nodes` by index so the caller's `for (i..)`
  /// loop can pair node[i] with layouts[i].
  static List<_Layout> _buildLayouts(List<ZoneNode> nodes) {
    // Group by tier, preserving original order within each tier.
    final byTier = <int, List<int>>{}; // tier → list of node indices
    for (int i = 0; i < nodes.length; i++) {
      byTier.putIfAbsent(nodes[i].tier, () => []).add(i);
    }
    final tiersSorted = byTier.keys.toList()..sort();

    final layouts = List<_Layout?>.filled(nodes.length, null);
    int standardSlotIndex = 0; // alternation counter for single-node rows
    int rowIndex = 0;

    for (final tier in tiersSorted) {
      final row = byTier[tier]!;
      final y = _rowHeight * (rowIndex + 0.5);

      if (row.length == 1) {
        final idx = row.first;
        final n = nodes[idx];
        _Slot slot;
        if (n.isBoss || n.isCrossroads) {
          slot = _Slot.center;
        } else {
          slot = standardSlotIndex.isEven ? _Slot.left : _Slot.right;
          standardSlotIndex++;
        }
        layouts[idx] = _Layout(
          zoneId: n.id,
          slot: slot,
          yCenter: y,
          status: n.status,
        );
      } else {
        // Branch row — expect exactly two siblings. Place them at left / right
        // and do NOT advance `standardSlotIndex` so the trail's alternation
        // rhythm resumes cleanly after rejoin.
        for (int k = 0; k < row.length; k++) {
          final idx = row[k];
          final n = nodes[idx];
          final slot = k == 0 ? _Slot.left : _Slot.right;
          layouts[idx] = _Layout(
            zoneId: n.id,
            slot: slot,
            yCenter: y,
            status: n.status,
          );
        }
      }
      rowIndex++;
    }

    // All slots are guaranteed filled because every node belongs to some
    // tier bucket — cast to non-null.
    return layouts.cast<_Layout>();
  }
}

class _ZoneTrailState extends State<ZoneTrail> with TickerProviderStateMixin {
  List<ZoneNode> get nodes => widget.nodes;
  List<ZoneEdge> get edges => widget.edges;
  ActiveJourney? get journey => widget.journey;
  String? get nextRegionName => widget.nextRegionName;
  RegionTheme? get regionTheme => widget.regionTheme;
  String? get regionName => widget.regionName;
  String? get avatarEmoji => widget.avatarEmoji;
  void Function(ZoneNode) get onTap => widget.onTap;
  Key? get activeNodeKey => widget.activeNodeKey;
  Map<String, Key> get keysByNodeId => widget.keysByNodeId;
  List<TrailEncounterNode> get encounters => widget.encounters;
  void Function(TrailEncounterNode)? get onEncounterTap =>
      widget.onEncounterTap;

  // Last laid-out geometry, used to place effects between builds.
  List<_Layout>? _layouts;
  double? _width;

  // ── Trail walk (spending banked km) ──
  late final AnimationController _travelCtrl = AnimationController(vsync: this)
    ..addListener(_onTravelTick);
  bool _travelPending = false;
  List<Offset> _travelPts = const [];
  List<double> _travelCum = const [];
  double _travelKm = 0, _travelBanked = 0, _travelLeftKm = 0;
  int _travelHops = 1, _travelLastHop = 0;
  String? _travelArriveId;
  TrailTravel? _travelReq;

  bool get _traveling => _travelPending || _travelCtrl.isAnimating;
  double get _travelE {
    final v = _travelCtrl.value;
    return v < .5 ? 2 * v * v : 1 - math.pow(-2 * v + 2, 2) / 2;
  }

  // ── Pin hop (journey progress) ──
  // Logged distance moves the walker toward the next zone in short hops;
  // the trail's travelled fill follows it instead of jumping.
  static const _hopMs = 280;
  late final AnimationController _hop = AnimationController(vsync: this)
    ..addListener(_onHopTick);
  double _hopFrom = 0, _hopTo = 0;
  int _hops = 1, _lastHop = 0;
  bool get _hopping => _hop.isAnimating;

  double get _hopT {
    final v = _hop.value * _hops;
    final seg = v.floor().clamp(0, _hops - 1);
    final local = (v - seg).clamp(0.0, 1.0);
    return _hopFrom + (_hopTo - _hopFrom) * ((seg + local) / _hops);
  }

  double get _hopLift {
    if (!_hopping) return 0;
    final v = _hop.value * _hops;
    return 18 * math.sin((v - v.floor()) * math.pi);
  }

  void _onHopTick() {
    final seg = (_hop.value * _hops).floor();
    if (seg != _lastHop && seg <= _hops) {
      _lastHop = seg;
      _dustAtWalker();
    }
    setState(() {});
  }

  void _dustAtWalker() {
    final layouts = _layouts, width = _width, j = journey;
    if (layouts == null || width == null || j == null) return;
    final local = _walkerPlacement(nodes, layouts, j, width, t: _hopT);
    final box = context.findRenderObject() as RenderBox?;
    if (local == null || box == null || !box.attached) return;
    RewardFx.burst(
        context, box.localToGlobal(local + const Offset(0, 14)), AppColors.blue,
        count: 6,
        distance: 16,
        size: 4,
        duration: const Duration(milliseconds: 350));
  }

  // ── Fog clears (zone unlock) ──
  late final AnimationController _fog = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..addListener(() => setState(() {}))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(_revealing.clear);
    });
  final Set<String> _revealing = {};

  Offset? _nodeCenter(String id) {
    final layouts = _layouts, width = _width;
    if (layouts == null || width == null) return null;
    final i = layouts.indexWhere((l) => l.zoneId == id);
    if (i < 0) return null;
    return Offset(_xFor(layouts[i].slot, width), layouts[i].yCenter);
  }

  @override
  void didUpdateWidget(ZoneTrail old) {
    super.didUpdateWidget(old);
    final travel = widget.travel;
    if (travel != null && travel.id != old.travel?.id) {
      if (RewardFx.enabled(context)) {
        // Hide the walker at its new spot until the walk starts next frame
        // (it needs this frame's layout to trace the route).
        _travelPending = true;
        _travelReq = travel;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _startTravel(travel));
      } else if (!travel.done.isCompleted) {
        travel.done.complete();
      }
      return;
    }
    if (!RewardFx.enabled(context)) return;

    final a = old.journey, b = widget.journey;
    if (a != null &&
        b != null &&
        a.destinationZoneName == b.destinationZoneName &&
        b.distanceTotalKm > 0 &&
        b.distanceTravelledKm > a.distanceTravelledKm) {
      _hopFrom = (a.distanceTravelledKm / b.distanceTotalKm).clamp(0.0, 1.0);
      _hopTo = (b.distanceTravelledKm / b.distanceTotalKm).clamp(0.0, 1.0);
      _hops = ((_hopTo - _hopFrom) / .08).ceil().clamp(1, 6);
      _lastHop = 0;
      _hop.duration = Duration(milliseconds: _hops * _hopMs);
      _hop.forward(from: 0);
    }

    final was = {for (final n in old.nodes) n.id: n.status};
    final opened = [
      for (final n in widget.nodes)
        if (was[n.id] == ZoneNodeStatus.locked &&
            n.status != ZoneNodeStatus.locked)
          n.id
    ];
    if (opened.isNotEmpty) {
      _revealing
        ..clear()
        ..addAll(opened);
      _fog.forward(from: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) => _sparks(opened));
    }
  }

  /// Sparks run along the path into each newly opened zone, which pulses.
  void _sparks(List<String> ids) {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final layouts = _layouts, width = _width;
    if (box == null || !box.attached || layouts == null || width == null) {
      return;
    }
    for (final id in ids) {
      final toIdx = layouts.indexWhere((l) => l.zoneId == id);
      if (toIdx <= 0) continue;
      final from = layouts[toIdx - 1], to = layouts[toIdx];
      final p0 = Offset(_xFor(from.slot, width), from.yCenter);
      final p3 = Offset(_xFor(to.slot, width), to.yCenter);
      final midY = (p0.dy + p3.dy) / 2;
      Offset at(double t) => box.localToGlobal(
          _cubicBezier(t, p0, Offset(p0.dx, midY), Offset(p3.dx, midY), p3));
      for (var k = 0; k < 3; k++) {
        RewardFx.run(
          context,
          duration: const Duration(milliseconds: 800),
          delay: Duration(milliseconds: 400 + k * 220),
          builder: (t, origin) {
            final p = at(Curves.easeInOut.transform(t)) - origin;
            return Positioned(
              left: p.dx - 5,
              top: p.dy - 5,
              child: Opacity(
                opacity: t > .9 ? (1 - t) / .1 : 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Color(0xFF7DFFB0), blurRadius: 10),
                      BoxShadow(color: AppColors.green, blurRadius: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
      final c = at(1);
      RewardFx.ring(context, c, AppColors.orange,
          maxRadius: 62, delay: const Duration(milliseconds: 1100));
      RewardFx.burst(context, c, const Color(0xFFFFE28C),
          count: 12, distance: 46, delay: const Duration(milliseconds: 1100));
    }
  }

  /// Shortest route between two zones along the trail's edges.
  List<String>? _route(String from, String to) {
    if (from == to) return [from];
    final next = <String, List<String>>{};
    for (final e in edges) {
      next.putIfAbsent(e.fromId, () => []).add(e.toId);
    }
    final prev = <String, String>{};
    final queue = [from];
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      for (final n in next[cur] ?? const <String>[]) {
        if (n == from || prev.containsKey(n)) continue;
        prev[n] = cur;
        if (n == to) {
          final path = [to];
          while (path.first != from) {
            path.insert(0, prev[path.first]!);
          }
          return path;
        }
        queue.add(n);
      }
    }
    return null;
  }

  static void _sampleEdge(List<Offset> pts, Offset a, Offset b, double upTo) {
    final midY = (a.dy + b.dy) / 2;
    for (var i = 1; i <= 16; i++) {
      pts.add(_cubicBezier(
          i / 16 * upTo, a, Offset(a.dx, midY), Offset(b.dx, midY), b));
    }
  }

  void _startTravel(TrailTravel t) {
    if (!mounted || _travelReq != t) return;
    final layouts = _layouts, width = _width;
    List<Offset>? pts;
    var km = 0.0;
    if (layouts != null && width != null) {
      final idx = {for (final (i, n) in nodes.indexed) n.id: i};
      final activeIdx =
          nodes.indexWhere((n) => n.status == ZoneNodeStatus.active);
      final route = activeIdx < 0 || !idx.containsKey(t.fromZoneId)
          ? null
          : _route(t.fromZoneId, nodes[activeIdx].id);
      if (route != null) {
        Offset c(int i) =>
            Offset(_xFor(layouts[i].slot, width), layouts[i].yCenter);
        pts = [c(idx[route.first]!)];
        for (var k = 1; k < route.length; k++) {
          final to = idx[route[k]]!;
          _sampleEdge(pts, c(idx[route[k - 1]]!), c(to), 1);
          km += nodes[to].distanceKm;
        }
        final j = journey;
        final nextIdx =
            nodes.indexWhere((n) => n.status == ZoneNodeStatus.next);
        if (j != null && j.distanceTotalKm > 0 && nextIdx >= 0) {
          _sampleEdge(pts, c(activeIdx), c(nextIdx),
              (j.distanceTravelledKm / j.distanceTotalKm).clamp(0.0, 1.0));
          km += j.distanceTravelledKm;
          _travelArriveId = null;
          _travelLeftKm =
              math.max(0, j.distanceTotalKm - j.distanceTravelledKm);
        } else {
          _travelArriveId = nodes[activeIdx].id;
        }
      }
    }
    if (pts == null || pts.length < 2 || km <= .01) {
      setState(() => _travelPending = false);
      if (!t.done.isCompleted) t.done.complete();
      return;
    }
    final cum = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      cum.add(cum.last + (pts[i] - pts[i - 1]).distance);
    }
    _travelPts = pts;
    _travelCum = cum;
    _travelKm = km;
    _travelBanked = math.max(t.bankedKm, km);
    _travelHops = (km * 3.5).round().clamp(4, 18);
    _travelLastHop = 0;
    // ~0.3 s per km, never more than 3 s.
    _travelCtrl.duration =
        Duration(milliseconds: math.min(3000, 300 * km + 700).round());
    setState(() => _travelPending = false);
    _travelCtrl.forward(from: 0).whenComplete(() => _endTravel(t));
  }

  /// Point [f] (0..1) of the way along the travel route, by distance.
  Offset _travelAt(double f) {
    final total = _travelCum.last, d = f * total;
    var i = 1;
    while (i < _travelCum.length - 1 && _travelCum[i] < d) {
      i++;
    }
    final seg = _travelCum[i] - _travelCum[i - 1];
    final k = seg <= 0 ? 0.0 : (d - _travelCum[i - 1]) / seg;
    return Offset.lerp(_travelPts[i - 1], _travelPts[i], k.clamp(0.0, 1.0))!;
  }

  void _onTravelTick() {
    final hop = (_travelE * _travelHops).floor();
    if (hop != _travelLastHop && hop < _travelHops) {
      _travelLastHop = hop;
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.attached) {
        RewardFx.burst(
            context,
            box.localToGlobal(_travelAt(_travelE) + const Offset(0, 16)),
            const Color(0xCCA0DCFF),
            count: 5,
            distance: 14,
            size: 3,
            duration: const Duration(milliseconds: 350));
      }
    }
    setState(() {});
  }

  void _endTravel(TrailTravel t) {
    if (!mounted) {
      if (!t.done.isCompleted) t.done.complete();
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.attached) {
      final arriveId = _travelArriveId;
      if (arriveId != null) {
        final node = nodes.where((n) => n.id == arriveId).firstOrNull;
        final c = box.localToGlobal(_nodeCenter(arriveId) ?? _travelPts.last);
        RewardFx.ring(context, c, AppColors.green, maxRadius: 60);
        RewardFx.burst(context, c, const Color(0xFF7DFFB0),
            count: 14, distance: 50);
        if (node != null && node.xpReward > 0) {
          RewardFx.floatText(context, c + const Offset(0, -40),
              '+${node.xpReward} XP', AppColors.orange,
              rise: 34, duration: const Duration(milliseconds: 1500));
        }
      } else if (_travelLeftKm > 0) {
        RewardFx.floatText(
            context,
            box.localToGlobal(_travelPts.last + const Offset(0, 40)),
            '${_travelLeftKm.toStringAsFixed(1)} km to go',
            AppColors.blue,
            fontSize: 12,
            rise: 14,
            pill: true,
            duration: const Duration(milliseconds: 2000));
      }
    }
    setState(() {});
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!t.done.isCompleted) t.done.complete();
    });
  }

  @override
  void dispose() {
    _hop.dispose();
    _fog.dispose();
    _travelCtrl.dispose();
    for (final t in [_travelReq]) {
      if (t != null && !t.done.isCompleted) t.done.complete();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const SizedBox(height: ZoneTrail._rowHeight);
    }

    final layouts = ZoneTrail._buildLayouts(nodes);
    // Total height comes from how many tier-rows we actually used, not how
    // many nodes — branch rows pack two nodes into one row.
    final rowCount = layouts.map((l) => l.yCenter).toSet().length;
    final totalHeight = ZoneTrail._rowHeight * rowCount + ZoneTrail._tailSpace;
    final traveling = journey != null;

    // 0..1 progress along the active edge, or null when not traveling. Drives
    // the progressive-fill effect on the active→next path: the traveled prefix
    // is painted in the "done" green, the remainder stays in the destination
    // hue so the path visibly fills up as the user logs km.
    final double? journeyProgress;
    if (journey != null && journey!.distanceTotalKm > 0) {
      journeyProgress = _hopping
          ? _hopT
          : (journey!.distanceTravelledKm / journey!.distanceTotalKm)
              .clamp(0.0, 1.0);
    } else {
      journeyProgress = null;
    }
    _layouts = layouts;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      _width = width;
      final walkerBase = (traveling && avatarEmoji != null)
          ? _walkerPlacement(nodes, layouts, journey!, width,
              t: _hopping ? _hopT : null)
          : null;
      final walkerPos = walkerBase == null || _traveling
          ? null
          : walkerBase + Offset(0, -_hopLift);

      final encounterPlacements =
          <({TrailEncounterNode enc, Offset nodePos, Offset anchorPos})>[];
      for (final enc in encounters) {
        final pos = _encounterPlacement(enc, nodes, layouts, width);
        if (pos != null) {
          encounterPlacements
              .add((enc: enc, nodePos: pos.node, anchorPos: pos.anchor));
        }
      }

      return SizedBox(
        width: width,
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _TrailPainter(
                  layouts: layouts,
                  edges: edges,
                  traveling: traveling,
                  journeyProgress: journeyProgress,
                  connectors: encounterPlacements
                      .map((p) => (
                            anchor: p.anchorPos,
                            node: p.nodePos,
                            type: p.enc.type,
                          ))
                      .toList(),
                ),
              ),
            ),
            for (int i = 0; i < nodes.length; i++)
              Positioned(
                top: layouts[i].yCenter - ZoneTrail._rowHeight / 2,
                left: 0,
                right: 0,
                height: ZoneTrail._rowHeight,
                child: _SlotAlign(
                  slot: layouts[i].slot,
                  child: ZoneNodeBubble(
                    key: keysByNodeId[nodes[i].id] ??
                        (nodes[i].status == ZoneNodeStatus.active
                            ? activeNodeKey
                            : null),
                    node: nodes[i],
                    journey: journey,
                    regionTheme: regionTheme,
                    regionName: regionName,
                    nextRegionName: nodes[i].isBoss ? nextRegionName : null,
                    onTap: () => onTap(nodes[i]),
                  ),
                ),
              ),
            if (walkerPos != null)
              Positioned(
                left: walkerPos.dx,
                top: walkerPos.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: _Walker(
                    avatarEmoji: avatarEmoji!,
                    travelledKm: _hopping
                        ? _hopT * journey!.distanceTotalKm
                        : journey!.distanceTravelledKm,
                  ),
                ),
              ),
            if (_travelCtrl.isAnimating) ...[
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter:
                        _TravelAheadPainter(_travelPts, _travelAt, _travelE),
                  ),
                ),
              ),
              Builder(builder: (_) {
                final e = _travelE;
                final frac = e * _travelHops - (e * _travelHops).floor();
                final p =
                    _travelAt(e) + Offset(0, -9 * math.sin(frac * math.pi));
                return Positioned(
                  left: p.dx,
                  top: p.dy,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: _WalkerBody(
                      avatarEmoji: avatarEmoji ?? '🧙',
                      travelledKm: 0,
                      caption:
                          'BANKED · ${(_travelBanked - e * _travelKm).clamp(0, double.infinity).toStringAsFixed(1)} KM',
                    ),
                  ),
                );
              }),
            ],
            for (final id in _revealing)
              if (_nodeCenter(id) case final c?)
                Positioned(
                  left: c.dx - 70,
                  top: c.dy - 70,
                  width: 140,
                  height: 140,
                  child: IgnorePointer(child: _FogCloud(progress: _fog.value)),
                ),
            for (final p in encounterPlacements) ...[
              if (p.enc.type == TrailEncounterType.blocker)
                Positioned(
                  top: p.anchorPos.dy - 12,
                  left: 0,
                  right: 0,
                  child: const _BlockedBanner(),
                ),
              Positioned(
                left: p.nodePos.dx,
                top: p.nodePos.dy,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: _EncounterNodeWidget(
                    type: p.enc.type,
                    emoji: _encounterEmoji(p.enc),
                    label: _encounterLabel(p.enc),
                    onTap: () => onEncounterTap?.call(p.enc),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

enum _Slot { left, right, center }

class _Layout {
  final String zoneId;
  final _Slot slot;
  final double yCenter;
  final ZoneNodeStatus status;
  const _Layout({
    required this.zoneId,
    required this.slot,
    required this.yCenter,
    required this.status,
  });
}

// Shared x-coordinate for a given slot — used by both the curve painter and
// the walker placement helper so they never drift apart.
const double _xLeftRatio = 110 / 390;
const double _xRightRatio = 280 / 390;
const double _xCenterRatio = 0.5;

double _xFor(_Slot s, double width) {
  switch (s) {
    case _Slot.left:
      return width * _xLeftRatio;
    case _Slot.right:
      return width * _xRightRatio;
    case _Slot.center:
      return width * _xCenterRatio;
  }
}

// Cubic Bezier point at parameter t (0..1) for the same curve shape the
// painter draws: (p0) → control1=(p0.x, midY) → control2=(p3.x, midY) → (p3).
Offset _cubicBezier(double t, Offset p0, Offset p1, Offset p2, Offset p3) {
  final u = 1 - t;
  final uu = u * u;
  final uuu = uu * u;
  final tt = t * t;
  final ttt = tt * t;
  final x = uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
  final y = uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;
  return Offset(x, y);
}

Offset? _walkerPlacement(
  List<ZoneNode> nodes,
  List<_Layout> layouts,
  ActiveJourney journey,
  double width, {
  double? t,
}) {
  if (journey.distanceTotalKm <= 0) return null;
  final activeIdx = nodes.indexWhere((n) => n.status == ZoneNodeStatus.active);
  final nextIdx = nodes.indexWhere((n) => n.status == ZoneNodeStatus.next);
  if (activeIdx < 0 || nextIdx < 0) return null;

  final a = layouts[activeIdx];
  final b = layouts[nextIdx];
  final x0 = _xFor(a.slot, width);
  final y0 = a.yCenter;
  final x1 = _xFor(b.slot, width);
  final y1 = b.yCenter;
  final midY = (y0 + y1) / 2;
  final progress = t ??
      (journey.distanceTravelledKm / journey.distanceTotalKm).clamp(0.0, 1.0);
  return _cubicBezier(
    progress,
    Offset(x0, y0),
    Offset(x0, midY),
    Offset(x1, midY),
    Offset(x1, y1),
  );
}

String _encounterEmoji(TrailEncounterNode enc) {
  switch (enc.type) {
    case TrailEncounterType.story:
      return '🧙';
    case TrailEncounterType.merchant:
      return '🪙';
    case TrailEncounterType.blocker:
      return '💀';
  }
}

String _encounterLabel(TrailEncounterNode enc) {
  switch (enc.type) {
    case TrailEncounterType.story:
      return 'Story';
    case TrailEncounterType.merchant:
      final d = enc.merchant?.timeLeft;
      if (d == null) return 'Merchant';
      final h = d.inHours;
      return 'Merchant · ${h}h';
    case TrailEncounterType.blocker:
      return 'BLOCKED';
  }
}

({Offset node, Offset anchor})? _encounterPlacement(
  TrailEncounterNode enc,
  List<ZoneNode> nodes,
  List<_Layout> layouts,
  double width,
) {
  final fromIdx = nodes.indexWhere((n) => n.id == enc.fromZoneId);
  final toIdx = nodes.indexWhere((n) => n.id == enc.toZoneId);
  if (fromIdx < 0 || toIdx < 0) return null;

  final a = layouts[fromIdx];
  final b = layouts[toIdx];
  final x0 = _xFor(a.slot, width);
  final y0 = a.yCenter;
  final x1 = _xFor(b.slot, width);
  final y1 = b.yCenter;
  final midY = (y0 + y1) / 2;

  final anchor = _cubicBezier(
    enc.t,
    Offset(x0, y0),
    Offset(x0, midY),
    Offset(x1, midY),
    Offset(x1, y1),
  );
  return (node: anchor + Offset(enc.sideOffset, 0), anchor: anchor);
}

class _SlotAlign extends StatelessWidget {
  final _Slot slot;
  final Widget child;
  const _SlotAlign({required this.slot, required this.child});

  @override
  Widget build(BuildContext context) {
    switch (slot) {
      case _Slot.left:
        return Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Align(alignment: Alignment.centerLeft, child: child),
        );
      case _Slot.right:
        return Padding(
          padding: const EdgeInsets.only(right: 40),
          child: Align(alignment: Alignment.centerRight, child: child),
        );
      case _Slot.center:
        return Align(alignment: Alignment.center, child: child);
    }
  }
}

// ─── Curve painter ───────────────────────────────────────────────────────────

class _TrailPainter extends CustomPainter {
  final List<_Layout> layouts;
  final List<ZoneEdge> edges;
  final bool traveling;
  // Fraction of the active edge already covered (0..1). Null when no active
  // journey or the journey edge has no known total distance.
  final double? journeyProgress;
  final List<({Offset anchor, Offset node, TrailEncounterType type})>
      connectors;

  _TrailPainter({
    required this.layouts,
    required this.edges,
    required this.traveling,
    required this.journeyProgress,
    this.connectors = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (layouts.length < 2 || edges.isEmpty) return;

    // Index layouts by zone id for O(1) edge lookup.
    final byId = <String, _Layout>{
      for (final l in layouts) l.zoneId: l,
    };

    for (final edge in edges) {
      final a = byId[edge.fromId];
      final b = byId[edge.toId];
      if (a == null || b == null) continue;

      final x0 = _xFor(a.slot, size.width);
      final y0 = a.yCenter;
      final x1 = _xFor(b.slot, size.width);
      final y1 = b.yCenter;
      final midY = (y0 + y1) / 2;

      final path = Path()
        ..moveTo(x0, y0)
        ..cubicTo(x0, midY, x1, midY, x1, y1);

      final fromStatus = a.status;
      final toStatus = b.status;
      final unlocked = _isUnlocked(fromStatus) && _isUnlocked(toStatus);

      if (unlocked) {
        final isActiveToNext = fromStatus == ZoneNodeStatus.active &&
            toStatus == ZoneNodeStatus.next;

        if (isActiveToNext && journeyProgress != null) {
          // Progressive fill: draw the remaining segment in the destination
          // hue (dim), then overlay the already-traveled prefix in the
          // "completed" green. Path.computeMetrics yields exactly one metric
          // for a single cubicTo path.
          final metric = path.computeMetrics().first;
          final traveledLen = metric.length * journeyProgress!;

          final remainingPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..color = AppColors.orange.withOpacity(0.35);
          if (journeyProgress! < 1.0) {
            canvas.drawPath(
                metric.extractPath(traveledLen, metric.length), remainingPaint);
          }

          if (journeyProgress! > 0.0) {
            const doneGreen = Color(0x993fb950); // green @ 0.6 alpha
            final traveledPaint = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4
              ..strokeCap = StrokeCap.round
              ..color = doneGreen;
            canvas.drawPath(metric.extractPath(0, traveledLen), traveledPaint);
          }
        } else {
          final paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _solidGradient(fromStatus, toStatus, traveling),
            ).createShader(Rect.fromLTRB(0, y0, size.width, y1));
          canvas.drawPath(path, paint);
        }

        if (isActiveToNext) {
          final halo = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round
            ..color = (traveling ? AppColors.orange : AppColors.blue)
                .withOpacity(0.12);
          canvas.drawPath(path, halo);
        }
      } else {
        // Dashed grey for any edge touching an un-entered / locked zone.
        // Edges into a "locked-by-choice" branch fade further so the un-chosen
        // fork reads as de-emphasised rather than a hard wall.
        final dim = toStatus == ZoneNodeStatus.locked &&
            fromStatus == ZoneNodeStatus.active;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.butt
          ..color = AppColors.border.withOpacity(dim ? 0.4 : 0.7);
        _drawDashed(canvas, path, paint, 7, 6);
      }
    }

    for (final c in connectors) {
      final typeColor = _encounterColor(c.type);
      // Dashed connector line
      final connPath = Path()
        ..moveTo(c.node.dx, c.node.dy)
        ..lineTo(c.anchor.dx, c.anchor.dy);
      final connPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = typeColor.withOpacity(0.5);
      _drawDashed(canvas, connPath, connPaint, 4, 3);
      // Anchor dot
      canvas.drawCircle(
          c.anchor, 5, Paint()..color = typeColor.withOpacity(0.85));
    }
  }

  static Color _encounterColor(TrailEncounterType t) {
    switch (t) {
      case TrailEncounterType.story:
        return const Color(0xFFa371f7);
      case TrailEncounterType.merchant:
        return const Color(0xFFf5a623);
      case TrailEncounterType.blocker:
        return const Color(0xFFf85149);
    }
  }

  static bool _isUnlocked(ZoneNodeStatus s) =>
      s == ZoneNodeStatus.completed ||
      s == ZoneNodeStatus.active ||
      s == ZoneNodeStatus.next;

  List<Color> _solidGradient(
      ZoneNodeStatus from, ZoneNodeStatus to, bool traveling) {
    const green60 = Color(0x993fb950); // 0.6 alpha
    const green30 = Color(0x4d3fb950); // 0.3
    const green40 = Color(0x663fb950); // 0.4
    const blue60 = Color(0x994f9eff);
    const orange70 = Color(0xb3f5a623);

    if (from == ZoneNodeStatus.active) {
      // Active → next: green base, tip coloured by travel state.
      return [green40, traveling ? orange70 : blue60];
    }
    if (to == ZoneNodeStatus.active) {
      return [green40, blue60];
    }
    return [green60, green30];
  }

  void _drawDashed(
      Canvas canvas, Path path, Paint paint, double dash, double gap) {
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final next = (d + dash).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrailPainter old) {
    if (old.traveling != traveling) return true;
    if (old.journeyProgress != journeyProgress) return true;
    if (old.layouts.length != layouts.length) return true;
    if (old.edges.length != edges.length) return true;
    if (old.connectors.length != connectors.length) return true;
    for (int i = 0; i < layouts.length; i++) {
      if (old.layouts[i].slot != layouts[i].slot ||
          old.layouts[i].yCenter != layouts[i].yCenter ||
          old.layouts[i].status != layouts[i].status ||
          old.layouts[i].zoneId != layouts[i].zoneId) {
        return true;
      }
    }
    for (int i = 0; i < edges.length; i++) {
      if (old.edges[i].fromId != edges[i].fromId ||
          old.edges[i].toId != edges[i].toId) {
        return true;
      }
    }
    return false;
  }
}

// ─── Walker token ────────────────────────────────────────────────────────────

class _Walker extends StatefulWidget {
  final String avatarEmoji;
  final double travelledKm;
  const _Walker({required this.avatarEmoji, required this.travelledKm});

  @override
  State<_Walker> createState() => _WalkerState();
}

class _WalkerState extends State<_Walker> with SingleTickerProviderStateMixin {
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (_, __) {
        final t = _bob.value; // 0..1..0
        return Transform.translate(
          offset: Offset(0, -3 * t),
          child: _WalkerBody(
            avatarEmoji: widget.avatarEmoji,
            travelledKm: widget.travelledKm,
          ),
        );
      },
    );
  }
}

class _WalkerBody extends StatelessWidget {
  final String avatarEmoji;
  final double travelledKm;

  /// Replaces the "YOU · x KM" tag (the trail walk shows banked km).
  final String? caption;
  const _WalkerBody({
    required this.avatarEmoji,
    required this.travelledKm,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.blue.withOpacity(0.45)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withOpacity(0.25),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Text(
              avatarEmoji,
              style: const TextStyle(
                fontSize: 22,
                shadows: [
                  Shadow(
                    color: Color(0x80000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              caption ?? 'YOU · ${travelledKm.toStringAsFixed(1)} KM',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Encounter node widget ────────────────────────────────────────────────────

class _EncounterNodeWidget extends StatefulWidget {
  final TrailEncounterType type;
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _EncounterNodeWidget({
    required this.type,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  State<_EncounterNodeWidget> createState() => _EncounterNodeWidgetState();
}

class _EncounterNodeWidgetState extends State<_EncounterNodeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _scale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _encounterNodeColor(widget.type);
    final labelColor = _encounterNodeColor(widget.type);
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withOpacity(_opacity.value),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.2),
                    border: Border.all(color: color.withOpacity(0.7), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child:
                      Text(widget.emoji, style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: TextStyle(
              color: labelColor,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

Color _encounterNodeColor(TrailEncounterType t) {
  switch (t) {
    case TrailEncounterType.story:
      return const Color(0xFFa371f7);
    case TrailEncounterType.merchant:
      return const Color(0xFFf5a623);
    case TrailEncounterType.blocker:
      return const Color(0xFFf85149);
  }
}

// ─── Blocked banner ───────────────────────────────────────────────────────────

class _BlockedBanner extends StatelessWidget {
  const _BlockedBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Expanded(child: _DashedLine()),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x2Ef85149),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0x99f85149)),
            ),
            child: const Text(
              '⛔ PATH BLOCKED',
              style: TextStyle(
                color: Color(0xFFf85149),
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const Expanded(child: _DashedLine()),
        ],
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xB3f85149)
      ..strokeWidth = 2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(
          Offset(x, 0), Offset((x + 6).clamp(0, size.width), 0), paint);
      x += 12;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Soft fog that hides a newly opened zone and then blows away to reveal it.
/// [progress] 0 = full fog, 1 = cleared.
class _FogCloud extends StatelessWidget {
  final double progress;
  const _FogCloud({required this.progress});

  static const _blobs = [
    (Offset(-22, -8), 38.0),
    (Offset(18, 4), 34.0),
    (Offset(0, 26), 30.0),
    (Offset(36, 22), 24.0),
    (Offset(-36, 18), 24.0),
    (Offset(-6, -32), 26.0),
  ];

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final (i, (o, r)) in _blobs.indexed)
            Builder(builder: (_) {
              final p = Curves.easeIn
                  .transform(((progress - i * .05) / .7).clamp(0.0, 1.0));
              final c = const Offset(70, 70) + o + Offset(-90 * p, -10 * p);
              return Positioned(
                left: c.dx - r,
                top: c.dy - r,
                child: Opacity(
                  opacity: (1 - p) * .85,
                  child: Container(
                    width: r * 2,
                    height: r * 2,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFB4C8CD),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Dims the part of the travel route the walker hasn't reached yet, so the
/// trail visibly "fills in" behind them.
class _TravelAheadPainter extends CustomPainter {
  final List<Offset> pts;
  final Offset Function(double) at;
  final double e;
  _TravelAheadPainter(this.pts, this.at, this.e);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2 || e >= 1) return;
    final path = Path();
    final start = at(e);
    path.moveTo(start.dx, start.dy);
    const steps = 48;
    for (var i = 1; i <= steps; i++) {
      final p = at(e + (1 - e) * i / steps);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xE6040E12),
    );
    // Dashed light line on top: the way still to walk.
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        canvas.drawPath(
          m.extractPath(d, math.min(d + 2.5, m.length)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..color = const Color(0x5CC8E6FF),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TravelAheadPainter old) => old.e != e;
}
