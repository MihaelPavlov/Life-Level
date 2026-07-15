import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../../core/services/world_zone_refresh_notifier.dart';
import '../../../core/widgets/api_error_state.dart';
import '../../character/providers/character_provider.dart';
import '../../tutorial/models/tutorial_step.dart';
import '../../tutorial/providers/tutorial_provider.dart';
import '../models/world_map_models.dart';
import '../services/world_zone_service.dart';
import '../../../core/services/boss_overlay_notifier.dart';
import '../../../core/widgets/chest_opened_overlay.dart';
import '../models/encounter_models.dart';
import '../widgets/crossroads_choice_sheet.dart';
import '../widgets/dungeon_floors_sheet.dart';
import '../widgets/encounter_blocker_sheet.dart';
import '../widgets/encounter_intercept_sheet.dart';
import '../widgets/encounter_merchant_sheet.dart';
import '../widgets/encounter_story_sheet.dart';
import '../widgets/map_icon_resolver.dart';
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
  static const String _tutorialSampleZonePrefix = '__tutorial_sample_';

  // Attached to the active zone bubble inside ZoneTrail so we can call
  // Scrollable.ensureVisible to auto-scroll the user there on entry.
  final GlobalKey _activeNodeKey = GlobalKey();
  final GlobalKey _backButtonKey = GlobalKey();
  final GlobalKey _trailKey = GlobalKey();
  final Map<String, GlobalKey> _tutorialZoneKeys = {};

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
  TutorialStep? _lastTutorialStep;

  @override
  void initState() {
    super.initState();
    _refreshSub = WorldZoneRefreshNotifier.stream.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _refreshSub.cancel();
    final c = ref.read(tutorialControllerProvider);
    c.unregisterKey('mapWorldBack');
    c.unregisterKey('mapZoneTrail');
    c.unregisterKey('mapNormalZone');
    c.unregisterKey('mapChestZone');
    c.unregisterKey('mapSpecialZone');
    c.unregisterKey('mapDungeonZone');
    c.unregisterKey('mapBossZone');
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
      _syncTutorialTargets(_buildVisibleRegionForTutorial(region));
      // Once the trail has laid out, snap the viewport to the active zone so
      // the user always lands on their current position.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTutorialTarget();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _scrollToActiveZone() {
    if (!mounted) return;
    final ctx = _activeNodeKey.currentContext;
    if (ctx == null) return; // no active zone in this region
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      // Land the active bubble ~30% from the top of the viewport so the user
      // sees a bit of trail above (where they came from) and below (where
      // they're going) without having to scroll.
      alignment: 0.3,
    );
  }

  void _scrollToCurrentTutorialTarget() {
    if (!mounted) return;
    final tutorial = ref.read(tutorialControllerProvider);
    if (tutorial.isMapTutorial && tutorial.step != null) {
      final keyId = tutorial.step!.targetKeyId;
      if (keyId != null && keyId != 'mapWorldBack') {
        final key = _tutorialKeyForTarget(keyId);
        final ctx = key?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            alignment: 0.36,
          );
          return;
        }
      }
    }
    _scrollToActiveZone();
  }

  GlobalKey? _tutorialKeyForTarget(String targetId) {
    switch (targetId) {
      case 'mapZoneTrail':
        return _trailKey;
      case 'mapNormalZone':
        return _tutorialZoneKeyByTarget('mapNormalZone');
      case 'mapChestZone':
        return _tutorialZoneKeyByTarget('mapChestZone');
      case 'mapSpecialZone':
        return _tutorialZoneKeyByTarget('mapSpecialZone');
      case 'mapDungeonZone':
        return _tutorialZoneKeyByTarget('mapDungeonZone');
      case 'mapBossZone':
        return _tutorialZoneKeyByTarget('mapBossZone');
      default:
        return null;
    }
  }

  final Map<String, GlobalKey> _tutorialTargetKeys = {};

  GlobalKey? _tutorialZoneKeyByTarget(String targetId) =>
      _tutorialTargetKeys[targetId];

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
    // Pre-flight: if the user is currently inside an in-progress dungeon and
    // the target isn't that dungeon, warn them before forfeiting floors.
    final dungeonInProgress = _currentInProgressDungeon();
    if (dungeonInProgress != null && dungeonInProgress.id != node.id) {
      final remaining = (dungeonInProgress.dungeonFloorsTotal ?? 0) -
          (dungeonInProgress.dungeonFloorsCompleted ?? 0);
      final confirmed = await _confirmSkipDungeonFloors(
        dungeonName: dungeonInProgress.name,
        remaining: remaining,
      );
      if (!mounted) return;
      if (confirmed != true) return; // user cancelled; no destination change
    }

    SetDestinationResult result;
    try {
      result = await _service.setDestination(node.id);
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
    } on BranchRequiresCrossroadsArrivalException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reach ${e.crossroadsName} first, then pick a path.'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 3),
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
    Navigator.of(context).pop(); // close the zone detail sheet
    await _load();
    WorldZoneRefreshNotifier.notify();
    if (!mounted) return;

    // Encounter intercept — movement was stopped at an NPC on the path
    if (result.activeEncounter != null) {
      await _showEncounterIntercept(result.activeEncounter!, node.name);
      return;
    }

    final forfeitMsg = result.forfeitedFloors > 0
        ? ' · ${result.forfeitedFloors} floor${result.forfeitedFloors == 1 ? "" : "s"} forfeited'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Destination set · ${node.name}$forfeitMsg'),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Shows the encounter intercept modal and handles the outcome:
  ///   • story / merchant → player can re-tap the zone to continue
  ///   • blocker → snackbar explains they must defeat the NPC first
  Future<void> _showEncounterIntercept(
      ActiveEncounterResult encounter, String destinationZoneName) async {
    await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EncounterInterceptSheet(
        encounter: encounter,
        destinationZoneName: destinationZoneName,
      ),
    );

    if (!mounted) return;

    if (encounter.isBlocker) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${encounter.emoji} ${encounter.name} blocks the path! Defeat them to continue.'),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    // story / merchant: no snackbar — player just re-taps the zone to continue
  }

  /// Shows a friendlier, stakes-clear confirmation dialog before abandoning
  /// an in-progress dungeon. Returns `true` only when the user taps the
  /// confirm button — any other dismissal (tap outside, back, Cancel) is a
  /// "stay in the dungeon" signal.
  Future<bool?> _confirmSkipDungeonFloors({
    required String dungeonName,
    required int remaining,
  }) {
    final floorWord = remaining == 1 ? 'floor' : 'floors';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.red.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.14),
                      border: Border.all(
                          color: AppColors.red.withValues(alpha: 0.45)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('⚠️', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Skip $remaining $floorWord?',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'If you move on now, you\'ll lose these growth opportunities '
                'at $dungeonName. Each unfinished floor is a workout type you '
                'won\'t train — and they can\'t be recovered.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.08),
                  border:
                      Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Permanent — you won\'t be able to come back for them.',
                        style: TextStyle(
                          color: AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Stay and train',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Skip anyway',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the zone node representing the user's currently in-progress
  /// dungeon in the open region (if any). Used to trigger the forfeit
  /// confirmation before switching destination.
  ZoneNode? _currentInProgressDungeon() {
    final region = _region;
    if (region == null) return null;
    for (final z in region.nodes) {
      if (z.isDungeon && z.dungeonStatus == DungeonRunStatus.inProgress) {
        return z;
      }
    }
    return null;
  }

  Future<void> _handleOpenChest(ZoneNode node) async {
    try {
      final result = await _service.openChest(node.id);
      if (!mounted) return;
      Navigator.of(context).pop(); // close the zone sheet
      await _load();
      WorldZoneRefreshNotifier.notify();
      if (!mounted) return;
      // Celebration modal — mirrors the level-up / item-obtained overlays.
      showChestOpenedOverlay(
        context,
        zoneName: result.zoneName,
        xp: result.xp,
        emoji: node.emoji.isEmpty ? '🎁' : node.emoji,
      );
    } on ChestAlreadyOpenedException catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open chest: $e'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _handleFightBoss(ZoneNode node) async {
    // Spawn the legacy Boss row bridged to this zone (idempotent), then
    // flip the shell's Boss overlay. User lands on BossScreen with Forest
    // Warden as Active and an HP bar; logging workouts damages it.
    try {
      await _service.spawnWorldBoss(node.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to summon boss: $e'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(); // close zone sheet
    BossOverlayNotifier.notify();
  }

  Future<void> _handleEnterDungeon(ZoneNode node) async {
    // Ensure there's a run to return to. Safe to call even if already in
    // progress — backend is idempotent.
    try {
      await _service.enterDungeon(node.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enter dungeon: $e'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(); // close the zone sheet first
    // Open the floors as a bottom sheet stacked over the region screen —
    // stays on the same page, no navigation push.
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DungeonFloorsSheet(zoneId: node.id),
    );
    if (!mounted) return;
    await _load();
    WorldZoneRefreshNotifier.notify();
  }

  void _showEncounterSheet(TrailEncounterNode enc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => switch (enc.type) {
        TrailEncounterType.merchant => MerchantSheet(encounter: enc),
        TrailEncounterType.blocker => BlockerSheet(
            encounter: enc,
            onFight: _handleFightTrailBlocker,
          ),
        TrailEncounterType.story => StorySheet(encounter: enc),
      },
    );
  }

  void _handleFightTrailBlocker() {
    Navigator.of(context).pop();
    BossOverlayNotifier.notify();
  }

  void _showNodeSheet(ZoneNode node) {
    if (_isTutorialSampleZone(node)) return;

    assert(() {
      debugPrint(
          '[node-tap] ${node.name} id=${node.id} isCrossroads=${node.isCrossroads} status=${node.status} branchOf=${node.branchOf}');
      return true;
    }());
    // Crossroads short-circuit: only open the two-branch choice sheet when
    // the user is actually AT the crossroads. Otherwise let the tap fall
    // through to the standard ZoneDetailSheet so they can set the
    // crossroads itself as destination (BFS auto-routes there).
    if (node.isCrossroads && node.status == ZoneNodeStatus.active) {
      _openCrossroadsSheet(node);
      return;
    }

    final isDestination = _activeDestinationZoneId == node.id;
    final canSet = node.status == ZoneNodeStatus.next ||
        node.status == ZoneNodeStatus.available;

    final atZone = node.status == ZoneNodeStatus.active;

    // Branches need parent-crossroads arrival before they're settable. Look
    // up the parent from the region's node list and check if it's active.
    ZoneNode? parentCrossroads;
    if (node.branchOf != null && _region != null) {
      for (final z in _region!.nodes) {
        if (z.id == node.branchOf) {
          parentCrossroads = z;
          break;
        }
      }
    }
    final userAtParentCrossroads =
        parentCrossroads?.status == ZoneNodeStatus.active;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ZoneDetailSheet(
        node: node,
        regionName: _region?.name ?? '',
        regionTheme: _region?.theme,
        userLevel: _userLevel,
        activeJourney: _activeJourney,
        isDestination: isDestination,
        onSetDestination: canSet ? () => _handleSetDestination(node) : null,
        onOpenChest: node.isChest && atZone && node.chestIsOpened != true
            ? () => _handleOpenChest(node)
            : null,
        onEnterDungeon: node.isDungeon &&
                atZone &&
                (node.dungeonStatus != DungeonRunStatus.completed &&
                    node.dungeonStatus != DungeonRunStatus.abandoned)
            ? () => _handleEnterDungeon(node)
            : null,
        onFightBoss:
            node.isBoss && atZone ? () => _handleFightBoss(node) : null,
        nextRegionName: node.isBoss ? _nextRegionName : null,
        parentCrossroadsName: parentCrossroads?.name,
        userAtParentCrossroads: userAtParentCrossroads,
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
      debugPrint('[crossroads] tap on ${crossroads.name} id=${crossroads.id} '
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
        regionTheme: _region?.theme,
        regionName: _region?.name,
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
    final tutorial = ref.watch(tutorialControllerProvider);
    final filteredRegion = _buildVisibleRegionForTutorial(region);

    if (tutorial.isMapTutorial && _tutorialTargetKeys.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncTutorialTargets(filteredRegion);
      });
    }

    if (tutorial.isMapTutorial && tutorial.step != _lastTutorialStep) {
      _lastTutorialStep = tutorial.step;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTutorialTarget();
      });
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _Banner(
            region: filteredRegion,
            theme: theme,
            onBack: widget.onBack ?? () => Navigator.pop(context),
            backButtonKey: _backButtonKey,
          ),
        ),
        SliverToBoxAdapter(child: _Summary(region: filteredRegion)),
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
            key: _trailKey,
            nodes: filteredRegion.nodes,
            edges: filteredRegion.edges,
            journey: _activeJourney,
            nextRegionName: _nextRegionName,
            regionTheme: region.theme,
            regionName: region.name,
            avatarEmoji: avatar,
            onTap: _showNodeSheet,
            activeNodeKey: _activeNodeKey,
            keysByNodeId: _tutorialZoneKeys,
            encounters: region.encounters,
            onEncounterTap: _showEncounterSheet,
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

  RegionDetail _buildProgressiveRevealRegion(RegionDetail region) {
    final nodes = region.nodes;
    if (nodes.isEmpty) return region;

    final visibleIds = <String>{};
    final branchRootIds = <String>{};

    for (final node in nodes) {
      switch (node.status) {
        case ZoneNodeStatus.completed:
        case ZoneNodeStatus.active:
        case ZoneNodeStatus.next:
          visibleIds.add(node.id);
          if (node.isCrossroads && node.status == ZoneNodeStatus.active) {
            branchRootIds.add(node.id);
          }
          break;
        case ZoneNodeStatus.available:
          if (node.branchOf != null && branchRootIds.contains(node.branchOf)) {
            visibleIds.add(node.id);
          }
          break;
        case ZoneNodeStatus.locked:
          break;
      }
    }

    int furthestVisibleIndex = -1;
    for (int i = 0; i < nodes.length; i++) {
      if (visibleIds.contains(nodes[i].id)) {
        furthestVisibleIndex = i;
      }
    }

    if (furthestVisibleIndex >= 0) {
      for (int i = furthestVisibleIndex + 1; i < nodes.length; i++) {
        final candidate = nodes[i];
        if (visibleIds.contains(candidate.id)) continue;
        visibleIds.add(candidate.id);
        break;
      }
    }

    final filteredNodes =
        nodes.where((node) => visibleIds.contains(node.id)).toList();
    final filteredEdges = region.edges
        .where((edge) =>
            visibleIds.contains(edge.fromId) && visibleIds.contains(edge.toId))
        .toList();

    return region.copyWith(
      nodes: filteredNodes,
      edges: filteredEdges,
    );
  }

  RegionDetail _buildVisibleRegionForTutorial(RegionDetail region) {
    final visible = _buildProgressiveRevealRegion(region);
    final tutorial = ref.read(tutorialControllerProvider);
    if (!tutorial.isMapTutorial) return visible;
    return _withTutorialSampleZones(visible);
  }

  RegionDetail _withTutorialSampleZones(RegionDetail region) {
    final nodes = [...region.nodes];
    final edges = [...region.edges];
    final existingIds = nodes.map((n) => n.id).toSet();
    final maxTier = nodes.fold<int>(0, (max, n) => n.tier > max ? n.tier : max);
    int nextTier = maxTier + 1;
    String? previousId = nodes.isEmpty ? null : nodes.last.id;

    void addSample(ZoneNode node) {
      if (existingIds.contains(node.id)) return;
      nodes.add(node);
      existingIds.add(node.id);
      if (previousId != null) {
        edges.add(ZoneEdge(fromId: previousId!, toId: node.id));
      }
      previousId = node.id;
    }

    addSample(_tutorialSampleZone(
      id: 'normal',
      name: 'Training Glade',
      tier: nextTier++,
      description: 'Tutorial-only normal zone preview.',
    ));
    addSample(_tutorialSampleZone(
      id: 'chest',
      name: 'Tutorial Chest',
      tier: nextTier++,
      description: 'Tutorial-only chest zone preview.',
      isChest: true,
      chestRewardXp: 120,
    ));
    addSample(_tutorialSampleZone(
      id: 'special',
      name: 'Tutorial Fork',
      tier: nextTier++,
      description: 'Tutorial-only crossroads preview.',
      isCrossroads: true,
    ));
    addSample(_tutorialSampleZone(
      id: 'dungeon',
      name: 'Tutorial Dungeon',
      tier: nextTier++,
      description: 'Tutorial-only dungeon zone preview.',
      isDungeon: true,
      dungeonFloorsTotal: 3,
      dungeonFloorsCompleted: 0,
      dungeonStatus: DungeonRunStatus.notEntered,
    ));
    addSample(_tutorialSampleZone(
      id: 'boss',
      name: 'Tutorial Boss Gate',
      tier: nextTier++,
      description: 'Tutorial-only boss zone preview.',
      isBoss: true,
      status: ZoneNodeStatus.locked,
    ));

    return region.copyWith(nodes: nodes, edges: edges);
  }

  ZoneNode _tutorialSampleZone({
    required String id,
    required String name,
    required int tier,
    required String description,
    ZoneNodeStatus status = ZoneNodeStatus.available,
    bool isCrossroads = false,
    bool isBoss = false,
    bool isChest = false,
    bool isDungeon = false,
    int? chestRewardXp,
    int? dungeonFloorsTotal,
    int? dungeonFloorsCompleted,
    DungeonRunStatus? dungeonStatus,
  }) {
    return ZoneNode(
      id: '$_tutorialSampleZonePrefix$id',
      name: name,
      emoji: '',
      description: description,
      tier: tier,
      levelRequirement: _userLevel,
      xpReward: isBoss ? 0 : 80,
      distanceKm: isBoss ? 0 : 1.5,
      status: status,
      isCrossroads: isCrossroads,
      isBoss: isBoss,
      isChest: isChest,
      isDungeon: isDungeon,
      chestRewardXp: chestRewardXp,
      chestIsOpened: isChest ? false : null,
      dungeonFloorsTotal: dungeonFloorsTotal,
      dungeonFloorsCompleted: dungeonFloorsCompleted,
      dungeonFloorsForfeited: isDungeon ? 0 : null,
      dungeonStatus: dungeonStatus,
    );
  }

  bool _isTutorialSampleZone(ZoneNode node) =>
      node.id.startsWith(_tutorialSampleZonePrefix);

  void _syncTutorialTargets(RegionDetail region) {
    final c = ref.read(tutorialControllerProvider);
    c.registerKey('mapWorldBack', _backButtonKey);
    c.registerKey('mapZoneTrail', _trailKey);

    ZoneNode? normal;
    ZoneNode? chest;
    ZoneNode? special;
    ZoneNode? dungeon;
    ZoneNode? boss;

    final sampleNodes =
        region.nodes.where(_isTutorialSampleZone).toList(growable: false);
    final targetNodes = sampleNodes.isNotEmpty ? sampleNodes : region.nodes;

    for (final node in targetNodes) {
      normal ??= (!node.isBoss &&
              !node.isChest &&
              !node.isDungeon &&
              !node.isCrossroads &&
              node.branchOf == null)
          ? node
          : null;
      chest ??= node.isChest ? node : null;
      special ??= node.isCrossroads ? node : null;
      dungeon ??= node.isDungeon ? node : null;
      boss ??= node.isBoss ? node : null;
    }

    _tutorialZoneKeys.clear();
    _tutorialTargetKeys.clear();

    void bind(String targetId, ZoneNode? node) {
      if (node == null) {
        c.unregisterKey(targetId);
        return;
      }
      final key = GlobalKey();
      _tutorialZoneKeys[node.id] = key;
      _tutorialTargetKeys[targetId] = key;
      c.registerKey(targetId, key);
    }

    bind('mapNormalZone', normal);
    bind('mapChestZone', chest);
    bind('mapSpecialZone', special);
    bind('mapDungeonZone', dungeon);
    bind('mapBossZone', boss);

    c.refreshMapTargets(
      hasNormalZone: normal != null,
      hasChestZone: chest != null,
      hasSpecialZone: special != null,
      hasDungeonZone: dungeon != null,
      hasBossZone: boss != null,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToCurrentTutorialTarget();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final RegionDetail region;
  final RegionThemeColors theme;
  final VoidCallback onBack;
  final Key? backButtonKey;
  const _Banner({
    required this.region,
    required this.theme,
    required this.onBack,
    this.backButtonKey,
  });

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
            key: backButtonKey,
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
              MapIconOrEmoji(
                asset: regionIconAsset(region),
                emoji: region.emoji,
                size: 56,
                emojiSize: 52,
                visualScale: 1.35,
              ),
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
              iconAsset: regionIconAsset(region),
              label: 'Zones',
              value: '${region.completedZones} / ${region.totalZones}',
              valueColor: AppColors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Tile(
              iconAsset: AppIcons.mapXpReward,
              label: 'XP earned',
              value: '${region.totalXpEarned}',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Tile(
              iconAsset: AppIcons.ringBoss,
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
  final String? iconAsset;
  final String label;
  final String value;
  final Color? valueColor;
  const _Tile({
    this.iconAsset,
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
              if (iconAsset != null)
                AppIconImage(
                  iconAsset!,
                  size: 14,
                  visualScale: 1.35,
                ),
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
