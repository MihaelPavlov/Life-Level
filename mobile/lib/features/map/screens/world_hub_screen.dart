import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/world_zone_refresh_notifier.dart';
import '../../../core/widgets/api_error_state.dart';
import '../models/world_map_models.dart';
import '../services/world_map_selection.dart';
import '../services/world_zone_service.dart';
import '../widgets/active_journey_banner.dart';
import '../widgets/region_hero_card.dart';
import 'region_detail_screen.dart';

/// World hub — scroll of region hero cards + optional active journey banner.
/// Tapping a region pushes [RegionDetailScreen].
///
/// Matches screen 1/6 of `design-mockup/map/WORLD-MAP-FINAL-MOCKUP.html`.
class WorldHubScreen extends StatefulWidget {
  const WorldHubScreen({super.key, this.onClose});

  /// Provided when the shell opens this as an overlay so the screen can show
  /// a back button. Null when rendered as a root nav tab.
  final VoidCallback? onClose;

  @override
  State<WorldHubScreen> createState() => WorldHubScreenState();
}

class WorldHubScreenState extends State<WorldHubScreen> {
  final _service = WorldZoneService();
  late final StreamSubscription<void> _refreshSub;

  WorldMapData? _data;
  bool _loading = true;
  String? _error;

  // Inline region navigation so the shell's bottom nav bar stays visible.
  // A nested Navigator.push would cover the whole Scaffold including the nav.
  // Initial value comes from WorldMapSelection so the user returns to their
  // last-viewed region after switching tabs.
  String? _openRegionId = WorldMapSelection.openRegionId;

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
        if (_openRegionId == null) {
          RegionCard? active;
          for (final r in data.regions) {
            if (r.status == RegionStatus.active) {
              active = r;
              break;
            }
          }
          if (active != null) {
            _openRegionId = active.id;
            WorldMapSelection.openRegionId = active.id;
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
    WorldMapSelection.openRegionId = region.id;
    setState(() => _openRegionId = region.id);
  }

  void _closeRegion() {
    WorldMapSelection.openRegionId = null;
    setState(() => _openRegionId = null);
  }

  @override
  Widget build(BuildContext context) {
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
            label: 'REGIONS',
            count:
                '${data.unlockedRegionCount} / ${data.regions.length} UNLOCKED',
          ),
          const SizedBox(height: 10),
          for (final region in data.regions)
            RegionHeroCard(
              region: region,
              userLevel: data.user.level,
              onTap: () => _openRegion(region),
            ),
        ],
      ),
    );
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
        if (onClose != null) ...[
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('‹',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 10),
        ],
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
  const _SectionTitle({required this.label, required this.count});

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
