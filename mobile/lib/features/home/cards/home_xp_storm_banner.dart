import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Transient XP Storm banner that sits above the streak strip.
/// Matches `.home3-storm` in home-v3.html.
///
/// Scaffold only — passing [state] == null hides the banner entirely.
/// Data wiring is owned by LL-001 (XP Storm system).
class HomeXpStormBanner extends StatelessWidget {
  final XpStormUiState? state;

  const HomeXpStormBanner({super.key, this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s == null || !s.active) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.orange.withValues(alpha: 0.18),
              AppColors.purple.withValues(alpha: 0.22),
            ],
          ),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.45),
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.2),
              blurRadius: 22,
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('\u26A1', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'XP STORM ACTIVE \u00B7 \u00D7${s.multiplier.toStringAsFixed(s.multiplier % 1 == 0 ? 0 : 1)} BONUS',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'All workouts earn bonus XP until storm ends',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x40000000),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _fmt(s.remaining),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

/// Minimal UI-layer state model for the banner. The real feed will
/// replace this with a Riverpod provider once LL-001 lands.
class XpStormUiState {
  final bool active;
  final double multiplier;
  final Duration remaining;

  const XpStormUiState({
    required this.active,
    required this.multiplier,
    required this.remaining,
  });
}
