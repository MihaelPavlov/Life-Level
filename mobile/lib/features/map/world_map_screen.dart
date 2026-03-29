import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'world_map_data.dart';
import 'world_map_detail_sheet.dart';
import 'world_map_models.dart';
import 'world_map_painter.dart';
import 'services/world_zone_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WorldMapScreen
// ─────────────────────────────────────────────────────────────────────────────

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final _service = WorldZoneService();

  List<ZoneData> _zones = [];
  Map<String, List<String>> _edges = {};
  List<Offset> _zoneCentres = [];
  int _characterLevel = 1;

  bool _loading = true;
  String? _error;

  // ── lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _load();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── data loading ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getFullWorld();

      final zones = data.zones.map(ZoneData.fromApiModel).toList();

      final edges = <String, List<String>>{};
      for (final e in data.edges) {
        edges.putIfAbsent(e.fromZoneId, () => []).add(e.toZoneId);
        if (e.isBidirectional) {
          edges.putIfAbsent(e.toZoneId, () => []).add(e.fromZoneId);
        }
      }

      setState(() {
        _zones = zones;
        _edges = edges;
        _zoneCentres = zones.map(_centreFor).toList();
        _characterLevel = data.characterLevel;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────────

  Offset _centreFor(ZoneData z) {
    // Prefer absolute canvas positions supplied by the API.
    if (z.absoluteX != null && z.absoluteY != null) {
      return Offset(z.absoluteX!, z.absoluteY!);
    }
    // Fallback: derive position from tier row + relative X fraction.
    final y = kTopPadding + z.tier * kTierHeight;
    final x = z.relativeX * kCanvasWidth;
    return Offset(x, y);
  }

  void _onCanvasTap(TapDownDetails details) {
    final tapped = details.localPosition;
    for (int i = 0; i < _zones.length; i++) {
      final c = _zoneCentres[i];
      final z = _zones[i];
      final hitRadius =
          z.isCrossroads ? kDiamondHalf * 1.4 : kZoneRadius * 1.2;
      if ((tapped - c).distance <= hitRadius) {
        _showZoneSheet(z);
        return;
      }
    }
  }

  void _showZoneSheet(ZoneData zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => WorldMapDetailSheet(
        zone: zone,
        userLevel: _characterLevel,
        onEnter: () async {
          Navigator.pop(context);
          await _handleEnterZone(zone);
        },
      ),
    );
  }

  Future<void> _handleEnterZone(ZoneData zone) async {
    try {
      await _service.setDestination(zone.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set destination: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // ── loading state ───────────────────────────────────────────────────
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.blue,
                strokeWidth: 2,
              ),
            )

          // ── error state ─────────────────────────────────────────────────────
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '⚠️',
                      style: TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load world map',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _load,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )

          // ── loaded state ────────────────────────────────────────────────────
          else ...[
            GestureDetector(
              onTapDown: _onCanvasTap,
              child: InteractiveViewer(
                constrained: false,
                minScale: 0.6,
                maxScale: 2.0,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => CustomPaint(
                    size: const Size(kCanvasWidth, kCanvasHeight),
                    painter: WorldMapPainter(
                      zones: _zones,
                      centres: _zoneCentres,
                      edges: _edges,
                      pulseValue: _pulseAnim.value,
                    ),
                  ),
                ),
              ),
            ),

            // ── floating HUD pill ─────────────────────────────────────────────
            Positioned(
              top: 48,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF30363d), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌍',
                          style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      const Text(
                        'World Map',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Lv $_characterLevel',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
