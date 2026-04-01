import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/nav_tab_notifier.dart';
import '../../features/activity/models/activity_models.dart';

// ── constants ──────────────────────────────────────────────────────────────────
const _kCardWidth    = 360.0;
const _kIconSize     = 72.0;
const _kBorderRadius = 20.0;
const _kCardBg       = Color(0xFF1e2632);
const _kOrange       = AppColors.orange;

/// Returns a human-readable hint for the next inventory slot tier.
String _nextUnlockHint(int level) {
  if (level < 5)  return 'Level 5 \u2192 30 slots';
  if (level < 10) return 'Level 10 \u2192 40 slots';
  if (level < 15) return 'Level 15 \u2192 50 slots';
  if (level < 25) return 'Level 25 \u2192 60 slots';
  if (level < 35) return 'Level 35 \u2192 75 slots';
  if (level < 50) return 'Level 50 \u2192 100 slots';
  return 'Max slots reached';
}

/// Shows the inventory-full warning card as a dialog with slide-up + fade.
void showInventoryFullOverlay(
    BuildContext context, BlockedItemInfo item, int currentLevel) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss inventory full popup',
    barrierColor: Colors.black.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 320),
    transitionBuilder: (ctx, anim, _, child) {
      final curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, _, __) =>
        _InventoryFullDialog(item: item, currentLevel: currentLevel),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _InventoryFullDialog
// ─────────────────────────────────────────────────────────────────────────────
class _InventoryFullDialog extends StatelessWidget {
  final BlockedItemInfo item;
  final int currentLevel;

  const _InventoryFullDialog({
    required this.item,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    final hint = _nextUnlockHint(currentLevel);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: _kCardWidth,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(_kBorderRadius),
            border: Border.all(
              color: _kOrange.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _kOrange.withValues(alpha: 0.18),
                blurRadius: 32,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── eyebrow ──────────────────────────────────────────────────
              Text(
                '\u26a0 INVENTORY FULL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kOrange,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 20),

              // ── item icon circle ──────────────────────────────────────────
              Container(
                width: _kIconSize,
                height: _kIconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kOrange.withValues(alpha: 0.12),
                  border: Border.all(
                      color: _kOrange.withValues(alpha: 0.55), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.25),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    item.itemIcon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── item name ─────────────────────────────────────────────────
              Text(
                item.itemName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // ── body text ─────────────────────────────────────────────────
              const Text(
                'Your bag is full. Level up to unlock more slots.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // ── next unlock hint ──────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kOrange.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Next unlock: $hint',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kOrange,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── View Inventory button ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    NavTabNotifier.switchTo('profile');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFf5a623), Color(0xFFd4861a)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _kOrange.withValues(alpha: 0.30),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'View Inventory',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // ── Dismiss button ────────────────────────────────────────────
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
