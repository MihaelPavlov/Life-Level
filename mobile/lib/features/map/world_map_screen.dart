import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'map_screen.dart';
import 'world_map_data.dart';
import 'world_map_detail_sheet.dart';
import 'world_map_models.dart';
import 'world_map_painter.dart';

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

  // Precomputed zone centre positions (index matches kZones order)
  late List<Offset> _zoneCentres;

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

    _zoneCentres = kZones.map(_centreFor).toList();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  Offset _centreFor(ZoneData z) {
    final y = kTopPadding + z.tier * kTierHeight;
    final x = z.relativeX * kCanvasWidth;
    return Offset(x, y);
  }

  void _onCanvasTap(TapDownDetails details) {
    final tapped = details.localPosition;
    for (int i = 0; i < kZones.length; i++) {
      final c = _zoneCentres[i];
      final z = kZones[i];
      final hitRadius = z.isCrossroads ? kDiamondHalf * 1.4 : kZoneRadius * 1.2;
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
        userLevel: kMockUserLevel,
        onEnter: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapScreen()),
          );
        },
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // ── map canvas ──────────────────────────────────────────────────────
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
                    zones: kZones,
                    centres: _zoneCentres,
                    edges: kEdges,
                    pulseValue: _pulseAnim.value,
                  ),
                ),
              ),
            ),
          ),

          // ── floating HUD pill ───────────────────────────────────────────────
          Positioned(
            top: 48, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF30363d), width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌍', style: TextStyle(fontSize: 14)),
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
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lv $kMockUserLevel',
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
      ),
    );
  }
}
