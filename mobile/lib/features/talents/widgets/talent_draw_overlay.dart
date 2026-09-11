import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../models/talent_models.dart';
import 'talent_theme.dart';

/// Animated reveal for a talent draw — mirrors `showChestOpenedOverlay`.
void showTalentDrawnOverlay(BuildContext context, TalentDrawResult result) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss talent draw',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 360),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero)
                  .animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.86, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
    pageBuilder: (ctx, _, __) => _TalentDrawnDialog(result: result),
  );
}

class _TalentDrawnDialog extends StatefulWidget {
  final TalentDrawResult result;
  const _TalentDrawnDialog({required this.result});

  @override
  State<_TalentDrawnDialog> createState() => _TalentDrawnDialogState();
}

class _TalentDrawnDialogState extends State<_TalentDrawnDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final t = r.talent;
    final accent = talentRarityColor(t.rarity);
    final isNew = r.isNew;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isNew ? '✦ NEW TALENT ✦' : '✦ SHARDS ✦',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: accent,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  final v = _pulse.value;
                  return Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.28 + 0.18 * v),
                          blurRadius: 26 + 14 * v,
                        ),
                      ],
                    ),
                    child: Center(
                      child: AppIconImage(talentIconAsset(t.iconKey), size: 48),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              Text(
                t.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                isNew
                    ? '${t.rarity} · Lv.${t.level}'
                    : '+${r.shardsAwarded} shards · ${t.rarity} · Lv.${t.level}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t.effectText,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (r.shieldsGranted > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '+${r.shieldsGranted} streak shield',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: const Color(0xFF05101f),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Nice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
