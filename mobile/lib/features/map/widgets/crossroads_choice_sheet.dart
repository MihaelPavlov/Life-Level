import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/world_map_models.dart';
import 'map_icon_resolver.dart';

/// Bottom sheet shown when the user taps a crossroads zone (on the map) or a
/// branch row on the Home crossroads card. Presents the branch paths as
/// side-by-side cards. Tapping a card only selects it; the "Take … →" button
/// commits the choice, which sets it as the active destination and — on the
/// backend — records a permanent path choice; the sibling locks for that
/// crossroads for the rest of the run.
///
/// If the user has already chosen (`alreadyChosenBranchId != null`), the sheet
/// still shows both cards but hides the button — the chosen one gets a
/// "Chosen" pill, the other a "Locked" pill.
///
/// [onChoose] owns closing the sheet (on success and on errors that end the
/// flow); the sheet only shows a busy state while it runs.
class CrossroadsChoiceSheet extends StatefulWidget {
  final ZoneNode crossroads;
  final List<ZoneNode> branches; // expect exactly 2
  final RegionTheme? regionTheme;
  final String? regionName;
  final String? alreadyChosenBranchId;

  /// Branch pre-selected when the sheet opens (e.g. the row tapped on Home).
  /// Defaults to the first branch.
  final String? initialSelectedBranchId;
  final Future<void> Function(ZoneNode branch) onChoose;

  const CrossroadsChoiceSheet({
    super.key,
    required this.crossroads,
    required this.branches,
    this.regionTheme,
    this.regionName,
    required this.alreadyChosenBranchId,
    this.initialSelectedBranchId,
    required this.onChoose,
  });

  @override
  State<CrossroadsChoiceSheet> createState() => _CrossroadsChoiceSheetState();
}

class _CrossroadsChoiceSheetState extends State<CrossroadsChoiceSheet> {
  late String? _selectedId =
      widget.branches.any((b) => b.id == widget.initialSelectedBranchId)
          ? widget.initialSelectedBranchId
          : widget.branches.firstOrNull?.id;
  bool _busy = false;

  Future<void> _choose(ZoneNode branch) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onChoose(branch);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final already = widget.alreadyChosenBranchId != null;
    final branches = widget.branches;
    final selected = branches.where((b) => b.id == _selectedId).firstOrNull;
    final others = branches.where((b) => b.id != _selectedId).toList();

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
              _Header(
                crossroads: widget.crossroads,
                already: already,
                regionTheme: widget.regionTheme,
                regionName: widget.regionName,
              ),
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
                          regionTheme: widget.regionTheme,
                          regionName: widget.regionName,
                          isChosen: already &&
                              branches[i].id == widget.alreadyChosenBranchId,
                          isLocked: already &&
                              branches[i].id != widget.alreadyChosenBranchId,
                          isSelected: !already && branches[i].id == _selectedId,
                          // Before a choice: tapping only selects. After a
                          // choice: the locked sibling is inert, and the
                          // chosen card stays tappable (idempotent) — the
                          // backend auto-routes multi-hop, so a far-away
                          // crossroads can still set its branch as the
                          // end-of-journey destination.
                          onTap: _busy
                              ? null
                              : !already
                                  ? () => setState(
                                      () => _selectedId = branches[i].id)
                                  : branches[i].id ==
                                          widget.alreadyChosenBranchId
                                      ? () => _choose(branches[i])
                                      : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!already && selected != null) ...[
                const SizedBox(height: 16),
                _TakePathButton(
                  label: 'Take ${selected.name} →',
                  busy: _busy,
                  onTap: () => _choose(selected),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                already
                    ? 'Your path is locked in.'
                    : others.length == 1
                        ? '🔒 ${others.first.name} locks once you choose.'
                        : '🔒 The other paths lock once you choose.',
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

/// Green commit button — same look as `HomeHeroButtonStyle.solidGreen`.
class _TakePathButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onTap;

  const _TakePathButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !busy,
      label: label,
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.green, Color(0xFF2ea043)],
            ),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withValues(alpha: 0.3),
                blurRadius: 16,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
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
  final RegionTheme? regionTheme;
  final String? regionName;
  const _Header({
    required this.crossroads,
    required this.already,
    required this.regionTheme,
    required this.regionName,
  });

  @override
  Widget build(BuildContext context) {
    final iconAsset = zoneNodeIconAsset(
      crossroads,
      regionTheme: regionTheme,
      regionName: regionName,
    );

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
          child: MapIconOrEmoji(
            asset: iconAsset,
            emoji: crossroads.emoji,
            size: 32,
            emojiSize: 28,
            visualScale: 1.3,
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
  final RegionTheme? regionTheme;
  final String? regionName;
  final bool isChosen;
  final bool isLocked;

  /// Pre-commit selection (green border + filled radio).
  final bool isSelected;
  final VoidCallback? onTap;

  const _PathCard({
    required this.branch,
    required this.regionTheme,
    required this.regionName,
    required this.isChosen,
    required this.isLocked,
    required this.isSelected,
    required this.onTap,
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
    final highlighted = isChosen || isSelected;
    final border = highlighted ? AppColors.green : AppColors.border;
    final bg = highlighted
        ? AppColors.green.withOpacity(0.08)
        : AppColors.surfaceElevated;
    final radius = BorderRadius.circular(14);
    final iconAsset = zoneNodeIconAsset(
      branch,
      regionTheme: regionTheme,
      regionName: regionName,
    );

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              MapIconOrEmoji(
                asset: iconAsset,
                emoji: branch.emoji,
                size: 28,
                emojiSize: 24,
                visualScale: 1.35,
                opacity: isLocked ? 0.55 : null,
              ),
              const Spacer(),
              if (isChosen)
                const _StatusPill(label: 'CHOSEN', color: AppColors.green),
              if (isLocked)
                const _StatusPill(
                    label: '🔒 LOCKED', color: AppColors.textMuted),
              if (!isChosen && !isLocked) _SelectRadio(selected: isSelected),
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
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          selected: isSelected,
          child: content,
        ),
      ),
    );
  }
}

class _SelectRadio extends StatelessWidget {
  final bool selected;
  const _SelectRadio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.green : AppColors.border,
          width: 2,
        ),
      ),
      child: selected
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green,
              ),
            )
          : null,
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
