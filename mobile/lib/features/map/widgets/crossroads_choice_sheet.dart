import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/world_map_models.dart';

/// Bottom sheet shown when the user taps a crossroads zone. Presents the two
/// branch paths (Easy / Hard) as side-by-side cards. Picking one sets it as
/// the active destination and — on the backend — records a permanent path
/// choice; the sibling locks for that crossroads for the rest of the run.
///
/// If the user has already chosen (`alreadyChosenBranchId != null`), the sheet
/// still shows both cards but hides the CTAs — the chosen one gets a "Chosen"
/// pill, the other a "Locked" pill.
class CrossroadsChoiceSheet extends StatelessWidget {
  final ZoneNode crossroads;
  final List<ZoneNode> branches; // expect exactly 2
  final String? alreadyChosenBranchId;
  final void Function(ZoneNode branch) onChoose;

  const CrossroadsChoiceSheet({
    super.key,
    required this.crossroads,
    required this.branches,
    required this.alreadyChosenBranchId,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final already = alreadyChosenBranchId != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x8C000000),
            blurRadius: 40,
            offset: Offset(0, -18),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 4, bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _Header(crossroads: crossroads, already: already),
              const SizedBox(height: 16),
              // IntrinsicHeight gives the Row a defined height = tallest
              // card, so crossAxisAlignment.stretch can make both siblings
              // equal height. Without this, the stretch-in-unbounded-height
              // inside a scroll-controlled modal sheet throws
              // "BoxConstraints forces an infinite height".
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < branches.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _PathCard(
                          branch: branches[i],
                          isChosen: already &&
                              branches[i].id == alreadyChosenBranchId,
                          isLocked: already &&
                              branches[i].id != alreadyChosenBranchId,
                          // Tap suppressed on the locked sibling after a
                          // choice. Idempotent for the already-chosen card.
                          // Backend now auto-routes multi-hop, so even a
                          // far-away crossroads can set its branch as the
                          // end-of-journey destination.
                          onChoose: (already &&
                                  branches[i].id != alreadyChosenBranchId)
                              ? null
                              : () => onChoose(branches[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                already
                    ? 'Your path is locked in.'
                    : 'Tap a path to set it as your destination.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ZoneNode crossroads;
  final bool already;
  const _Header({required this.crossroads, required this.already});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.14),
            border: Border.all(color: AppColors.purple.withOpacity(0.45)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            crossroads.emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                crossroads.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                already ? 'Your path is chosen' : 'Choose your path',
                style: TextStyle(
                  color: already ? AppColors.textSecondary : AppColors.purple,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PathCard extends StatelessWidget {
  final ZoneNode branch;
  final bool isChosen;
  final bool isLocked;
  final VoidCallback? onChoose;

  const _PathCard({
    required this.branch,
    required this.isChosen,
    required this.isLocked,
    required this.onChoose,
  });

  String get _difficultyLabel {
    final km = branch.distanceKm;
    if (km <= 5) return 'Short';
    if (km <= 8) return 'Moderate';
    return 'Long';
  }

  @override
  Widget build(BuildContext context) {
    final accent = isLocked ? AppColors.textMuted : AppColors.green;
    final border = isChosen ? AppColors.green : AppColors.border;
    final bg = isChosen
        ? AppColors.green.withOpacity(0.08)
        : AppColors.surfaceElevated;
    final radius = BorderRadius.circular(14);

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(branch.emoji, style: const TextStyle(fontSize: 24)),
              const Spacer(),
              if (isChosen)
                const _StatusPill(label: 'CHOSEN', color: AppColors.green),
              if (isLocked)
                const _StatusPill(label: '🔒 LOCKED', color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            branch.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            branch.description.isEmpty
                ? 'A branching path from the crossroads.'
                : branch.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _Stat(
              label: 'DISTANCE',
              value: '${branch.distanceKm.toStringAsFixed(1)} km',
              color: accent),
          const SizedBox(height: 4),
          _Stat(
              label: 'XP REWARD',
              value: '+${branch.xpReward}',
              color: AppColors.orange),
          const SizedBox(height: 4),
          _Stat(
              label: 'DIFFICULTY',
              value: _difficultyLabel,
              color: AppColors.textSecondary),
        ],
      ),
    );

    // Whole card is the tap target. Keep the widget stack as simple as
    // possible so the Flutter hit-tester has no reason to trip on mouse
    // tracker assertions: Material → InkWell → content. No AnimatedScale,
    // no Opacity wrapper (locked state is communicated via the faded accent
    // + 🔒 pill instead).
    return Material(
      color: bg,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: border,
          width: isChosen ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onChoose,
        child: content,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
