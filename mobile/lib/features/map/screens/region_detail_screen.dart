import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/world_zone_refresh_notifier.dart';
import '../../../core/widgets/api_error_state.dart';
import '../../character/providers/character_provider.dart';
import '../models/world_map_models.dart';
import '../services/world_zone_service.dart';
import '../widgets/crossroads_choice_sheet.dart';
import '../widgets/world_map_theme.dart';
import '../widgets/zone_detail_sheet.dart';
import '../widgets/zone_trail.dart';

/// Region detail — banner, 3 summary tiles, vertical zone-node trail.
/// Matches screens 2 + 4 of `design-mockup/map/WORLD-MAP-FINAL-MOCKUP.html`.
class RegionDetailScreen extends ConsumerStatefulWidget {
  final String regionId;

  /// When the hub embeds this screen inline (so the shell nav bar stays
  /// visible), the back arrow delegates here instead of popping a route.
  final VoidCallback? onBack;

  const RegionDetailScreen({super.key, required this.regionId, this.onBack});

  @override
  ConsumerState<RegionDetailScreen> createState() => _RegionDetailScreenState();
}

class _RegionDetailScreenState extends ConsumerState<RegionDetailScreen> {
  final _service = WorldZoneService();
  late final StreamSubscription<void> _refreshSub;

  RegionDetail? _region;
  // Kept locally so the sheet can render "traveling" layouts without another
  // round-trip. Sourced from the world map endpoint because region-detail
  // alone doesn't carry journey info.
  ActiveJourney? _activeJourney;
  String? _activeDestinationZoneId;
  // Derived from the world map region list so the boss bubble can render
  // "Boss · Unlocks X" without a dedicated backend field.
  String? _nextRegionName;
  int _userLevel = 1;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshSub = WorldZoneRefreshNotifier.stream.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _refreshSub.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = _region == null;
      _error = null;
    });
    try {
      // Region detail + world map in parallel — the latter gives us the
      // active journey that the detail endpoint doesn't include.
      final results = await Future.wait([
        _service.getRegionDetail(widget.regionId),
        _service.getWorldMap(),
      ]);
      final region = results[0] as RegionDetail;
      final world = results[1] as WorldMapData;
      if (!mounted) return;
      setState(() {
        _region = region;
        _activeJourney = world.activeJourney;
        _activeDestinationZoneId = _findDestinationZoneId(region, world);
        _nextRegionName = _findNextRegionName(region, world);
        _userLevel = world.user.level;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String? _findDestinationZoneId(RegionDetail region, WorldMapData world) {
    final journey = world.activeJourney;
    if (journey == null) return null;
    // Match by name since the world endpoint doesn't expose the zone id
    // directly — the journey destination name is unique within a region.
    final match = region.nodes.cast<ZoneNode?>().firstWhere(
          (z) => z!.name == journey.destinationZoneName,
          orElse: () => null,
        );
    return match?.id;
  }

  String _humanizeSetDestinationError(DioException e, ZoneNode target) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      final raw = data['message'] as String;
      if (raw.toLowerCase().contains('not adjacent')) {
        return 'You need to reach the previous zone before setting ${target.name} as your destination.';
      }
      return raw;
    }
    return 'Failed to set destination: ${e.message ?? e}';
  }

  String? _findNextRegionName(RegionDetail region, WorldMapData world) {
    final ordered = [...world.regions]
      ..sort((a, b) => a.chapterIndex.compareTo(b.chapterIndex));
    final idx = ordered.indexWhere((r) => r.id == region.id);
    if (idx < 0 || idx + 1 >= ordered.length) return null;
    return ordered[idx + 1].name;
  }

  Future<void> _handleSetDestination(ZoneNode node) async {
    try {
      await _service.setDestination(node.id);
    } on PathAlreadyChosenException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close whichever sheet is open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _humanizeSetDestinationError(e, node);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set destination: $e'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(); // close the sheet
    await _load();
    WorldZoneRefreshNotifier.notify();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Destination set · ${node.name}'),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNodeSheet(ZoneNode node) {
    assert(() {
      debugPrint(
          '[node-tap] ${node.name} id=${node.id} isCrossroads=${node.isCrossroads} status=${node.status} branchOf=${node.branchOf}');
      return true;
    }());
    // Crossroads short-circuit directly to the two-branch choice sheet —
    // no intermediate ZoneDetailSheet. The choice sheet itself handles the
    // "branches missing" case with a snackbar + debug log.
    if (node.isCrossroads) {
      _openCrossroadsSheet(node);
      return;
    }

    final isDestination = _activeDestinationZoneId == node.id;
    final canSet = node.status == ZoneNodeStatus.next ||
        node.status == ZoneNodeStatus.available;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ZoneDetailSheet(
        node: node,
        regionName: _region?.name ?? '',
        userLevel: _userLevel,
        activeJourney: _activeJourney,
        isDestination: isDestination,
        onSetDestination:
            canSet ? () => _handleSetDestination(node) : null,
      ),
    );
  }

  void _openCrossroadsSheet(ZoneNode crossroads) {
    final allNodes = _region?.nodes ?? const <ZoneNode>[];
    final branches =
        allNodes.where((z) => z.branchOf == crossroads.id).toList();

    // Loud diagnostic every time a crossroads tap lands here. Stripped in
    // release via the `assert(() { ...; return true; }())` idiom.
    assert(() {
      debugPrint(
          '[crossroads] tap on ${crossroads.name} id=${crossroads.id} '
          'branchesFound=${branches.length} '
          'regionNodes=${allNodes.map((z) => "${z.name}(id=${z.id} branchOf=${z.branchOf})").join(" | ")}');
      return true;
    }());

    if (branches.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'No branches found for ${crossroads.name}. (${branches.length} matched — check logs.)'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CrossroadsChoiceSheet(
        crossroads: crossroads,
        branches: branches.take(2).toList(),
        alreadyChosenBranchId: _region!.pathChoices[crossroads.id],
        onChoose: _handleSetDestination,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.shellBackground,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.blue,
                strokeWidth: 2,
              ),
            )
          : _error != null
              ? SafeArea(
                  child: ApiErrorState(
                    title: 'Failed to load region',
                    message: _error!,
                    onRetry: _load,
                  ),
                )
              : _buildContent(_region!),
    );
  }

  Widget _buildContent(RegionDetail region) {
    final theme = RegionThemeColors.of(region.theme);
    final avatar = ref.watch(characterProfileProvider).valueOrNull?.avatarEmoji;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _Banner(
            region: region,
            theme: theme,
            onBack: widget.onBack ?? () => Navigator.pop(context),
          ),
        ),
        SliverToBoxAdapter(child: _Summary(region: region)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              'YOUR PATH THROUGH THE REGION',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ZoneTrail(
            nodes: region.nodes,
            edges: region.edges,
            journey: _activeJourney,
            nextRegionName: _nextRegionName,
            avatarEmoji: avatar,
            onTap: _showNodeSheet,
          ),
        ),
        if (_activeJourney != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _JourneyFooter(journey: _activeJourney!),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final RegionDetail region;
  final RegionThemeColors theme;
  final VoidCallback onBack;
  const _Banner({required this.region, required this.theme, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.accent.withOpacity(0.32),
            theme.accent.withOpacity(0.06),
            AppColors.shellBackground,
          ],
          stops: const [0, 0.65, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Text('‹',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(region.emoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHAPTER ${region.chapterIndex} · ${_statusLabel(region.status).toUpperCase()}',
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      region.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (region.lore.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              region.lore,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(RegionStatus s) {
    switch (s) {
      case RegionStatus.active:
        return 'Active';
      case RegionStatus.completed:
        return 'Completed';
      case RegionStatus.locked:
        return 'Locked';
    }
  }
}

class _Summary extends StatelessWidget {
  final RegionDetail region;
  const _Summary({required this.region});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _Tile(
              icon: '🗝',
              label: 'Zones',
              value: '${region.completedZones} / ${region.totalZones}',
              valueColor: AppColors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Tile(
              icon: '⭐',
              label: 'XP earned',
              value: '${region.totalXpEarned}',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Tile(
              icon: '👹',
              label: 'Boss',
              value: _bossLabel(region),
              valueColor: _bossColor(region),
            ),
          ),
        ],
      ),
    );
  }

  String _bossLabel(RegionDetail r) {
    if (r.bossStatus == RegionBossStatus.defeated) return '✓ Defeated';
    if (r.bossStatus == RegionBossStatus.available) return 'Available';
    if (r.zonesUntilBoss != null && r.zonesUntilBoss! > 0) {
      return '${r.zonesUntilBoss} zones';
    }
    return 'Locked';
  }

  Color _bossColor(RegionDetail r) {
    switch (r.bossStatus) {
      case RegionBossStatus.defeated:
        return AppColors.green;
      case RegionBossStatus.available:
        return AppColors.orange;
      case RegionBossStatus.locked:
        return AppColors.red;
    }
  }
}

class _Tile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _JourneyFooter extends StatelessWidget {
  final ActiveJourney journey;
  const _JourneyFooter({required this.journey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x264f9eff), Color(0x1aa371f7)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'TRAVELING',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                '${journey.distanceTravelledKm.toStringAsFixed(1)} / ${journey.distanceTotalKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.hardEdge,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: journey.progress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.blue, AppColors.orange],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Arrival bonus: +${journey.arrivalXpReward} XP${journey.arrivalBonusLabel != null ? " · ${journey.arrivalBonusLabel}" : ""}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
