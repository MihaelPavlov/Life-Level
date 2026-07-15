import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/world_zone_refresh_notifier.dart';
import '../../../core/widgets/api_error_state.dart';
import '../../tutorial/models/tutorial_step.dart';
import '../../tutorial/providers/tutorial_provider.dart';
import '../models/world_map_models.dart';
import '../services/world_zone_service.dart';
import '../widgets/active_journey_banner.dart';
import '../widgets/region_hero_card.dart';
import 'region_detail_screen.dart';

/// World hub — scroll of region hero cards + optional active journey banner.
/// Tapping a region pushes [RegionDetailScreen].
///
/// Matches screen 1/6 of `design-mockup/map/WORLD-MAP-FINAL-MOCKUP.html`.
class WorldHubScreen extends ConsumerStatefulWidget {
  const WorldHubScreen({
    super.key,
    this.onClose,
    this.autoOpenActiveRegion = false,
  });

  /// Provided when the shell opens this as an overlay so the screen can show
  /// a back button. Null when rendered as a root nav tab.
  final VoidCallback? onClose;

  /// When true, automatically opens the player's active region on load
  /// (used when the bottom-nav "Map" tab is tapped directly).
  final bool autoOpenActiveRegion;

  @override
  ConsumerState<WorldHubScreen> createState() => WorldHubScreenState();
}

class WorldHubScreenState extends ConsumerState<WorldHubScreen> {
  final _service = WorldZoneService();
  late final StreamSubscription<void> _refreshSub;
  final GlobalKey _regionsKey = GlobalKey();

  WorldMapData? _data;
  bool _loading = true;
  String? _error;
  TutorialStep? _lastTutorialStep;

  // Inline region navigation so the shell's bottom nav bar stays visible.
  // Always starts at the hub list — tapping a region card opens RegionDetailScreen.
  String? _openRegionId;

  @override
  void initState() {
    super.initState();
    _refreshSub = WorldZoneRefreshNotifier.stream.listen((_) => _load());
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = ref.read(tutorialControllerProvider);
      c.registerKey('mapRegions', _regionsKey);
      c.ensureMapTutorialStarted();
    });
  }

  @override
  void dispose() {
    _refreshSub.cancel();
    ref.read(tutorialControllerProvider).unregisterKey('mapRegions');
    super.dispose();
  }

  /// Public hook — lets the shell re-fetch on tab switch without rebuilding.
  Future<void> refresh() => _load();

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await _service.getWorldMap();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        final tutorial = ref.read(tutorialControllerProvider);
        if (widget.autoOpenActiveRegion ||
            (tutorial.isMapTutorial && tutorial.mapTutorialStep == 1)) {
          _openRegionId = null;
          for (final r in data.regions) {
            if (r.status == RegionStatus.active) {
              _openRegionId = r.id;
              break;
            }
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openRegion(RegionCard region) {
    if (region.status == RegionStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${region.name} unlocks at level ${region.levelRequirement}'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _openRegionId = region.id);
  }

  void _closeRegion() {
    setState(() => _openRegionId = null);
  }

  @override
  Widget build(BuildContext context) {
    final tutorial = ref.watch(tutorialControllerProvider);
    final tutorialStep = tutorial.step;
    final needsRegionOpen = tutorial.isMapTutorial &&
        tutorialStep != null &&
        tutorialStep != TutorialStep.mapRegions;
    final tutorialStepChanged = tutorialStep != _lastTutorialStep;
    _lastTutorialStep = tutorialStep;

    if (tutorial.isMapTutorial &&
        tutorialStep == TutorialStep.mapRegions &&
        _openRegionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _openRegionId != null) {
          _closeRegion();
        }
      });
    }
    if (needsRegionOpen &&
        (_openRegionId == null || tutorialStepChanged) &&
        _data != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _data == null) return;
        for (final region in _data!.regions) {
          if (region.status == RegionStatus.active) {
            _openRegion(region);
            break;
          }
        }
      });
    }

    return Container(
      color: AppColors.shellBackground,
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.blue,
                      strokeWidth: 2,
                    ),
                  )
                : _error != null
                    ? ApiErrorState(
                        title: 'Failed to load world map',
                        message: _error!,
                        onRetry: _load,
                      )
                    : _buildContent(_data!),
          ),
          if (_openRegionId != null)
            RegionDetailScreen(
              key: ValueKey(_openRegionId),
              regionId: _openRegionId!,
              onBack: _closeRegion,
            ),
        ],
      ),
    );
  }

  Widget _buildContent(WorldMapData data) {
    final visibleRegions = _visibleRegions(data.regions);
    final hiddenRegionCount = data.regions.length - visibleRegions.length;

    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          _HubHeader(user: data.user, onClose: widget.onClose),
          const SizedBox(height: 14),
          if (data.activeJourney != null) ...[
            ActiveJourneyBanner(journey: data.activeJourney!),
            const SizedBox(height: 14),
          ],
          _SectionTitle(
            key: _regionsKey,
            label: 'REGIONS',
            count: '${visibleRegions.length} SHOWN',
          ),
          const SizedBox(height: 10),
          for (final region in visibleRegions)
            RegionHeroCard(
              region: region,
              userLevel: data.user.level,
              onTap: () => _openRegion(region),
            ),
          if (hiddenRegionCount > 0)
            _UnknownRealmsCard(hiddenCount: hiddenRegionCount),
        ],
      ),
    );
  }

  List<RegionCard> _visibleRegions(List<RegionCard> regions) {
    final visible = <RegionCard>[];
    bool teaserAdded = false;

    for (final region in regions) {
      if (region.status != RegionStatus.locked) {
        visible.add(region);
        continue;
      }
      if (!teaserAdded) {
        visible.add(region);
        teaserAdded = true;
      }
    }

    return visible;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HubHeader extends StatelessWidget {
  final WorldUser user;
  final VoidCallback? onClose;
  const _HubHeader({required this.user, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user.characterName.isNotEmpty)
                Text(
                  user.characterName.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              const SizedBox(height: 2),
              const Text(
                'World Map',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue, AppColors.purple],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withOpacity(0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: Text(
            'Lv ${user.level}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final String count;
  const _SectionTitle({super.key, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _UnknownRealmsCard extends StatelessWidget {
  final int hiddenCount;
  const _UnknownRealmsCard({required this.hiddenCount});

  @override
  Widget build(BuildContext context) {
    final realmLabel = hiddenCount == 1 ? 'realm' : 'realms';
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.24),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.orange.withValues(alpha: 0.08),
            AppColors.purple.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                style: BorderStyle.solid,
              ),
            ),
            child: const Text(
              '?',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unknown Beyond',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$hiddenCount more $realmLabel wait behind the fog. Keep moving to reveal the next chapter.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.45,
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
