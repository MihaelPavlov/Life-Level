import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/widgets/app_icon_image.dart';
import '../../core/widgets/app_toast.dart';
import '../character/providers/character_provider.dart';
import 'models/talent_models.dart';
import 'providers/talents_provider.dart';
import 'widgets/talent_info_sheet.dart';
import 'widgets/talent_theme.dart';

class TalentsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  const TalentsScreen({super.key, this.onClose});

  @override
  ConsumerState<TalentsScreen> createState() => _TalentsScreenState();
}

class _TalentsScreenState extends ConsumerState<TalentsScreen>
    with TickerProviderStateMixin {
  String? _selectedKey;
  bool _busy = false;
  // Bumped each time paging hits "no other unlocked talent in that
  // direction" — the corresponding arrow watches this to play a shake.
  int _leftShake = 0;
  int _rightShake = 0;

  // Draw feedback happens directly on this screen: the highlight jumps
  // from tile to tile until it lands on the drawn talent, then that talent
  // opens gently in the centre.
  late final AnimationController _sweepCtrl = AnimationController(vsync: this);
  late final AnimationController _revealCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  late final Animation<double> _revealAnim =
      CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic);
  // Fractional sweep position. Tiles convert it to one active integer index
  // so the highlight jumps cleanly and never lights neighboring cards.
  Animation<double>? _sweepAnim;
  int _sweepLength = 0;
  // Authoritative data for the just-drawn talent, from the draw API result
  // itself rather than the (still-refreshing) live grid — set at the exact
  // moment the sweep lands, never before, so the reveal can't spoil itself
  // by showing the unlocked/leveled tile early.
  TalentView? _revealTalent;

  // Plays a soft scale+fade every time a talent card opens.
  late final AnimationController _popCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280));
  late final Animation<double> _popAnim =
      CurvedAnimation(parent: _popCtrl, curve: Curves.easeOutCubic);

  // A duplicate draw that leveled up an already-owned talent gets a calm
  // "Lv.2 → Lv.3" callout over the opened card.
  late final AnimationController _levelUpCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
  // Deliberately NOT curved — the banner's fade-in/hold/fade-out timing
  // reads this value as a plain fraction-of-duration. Easing lives only in
  // the banner's own scale calculation, applied to this raw value.
  Animation<double> get _levelUpAnim => _levelUpCtrl;
  int? _levelUpFrom;
  int? _levelUpTo;

  @override
  void dispose() {
    _sweepCtrl.dispose();
    _revealCtrl.dispose();
    _levelUpCtrl.dispose();
    _popCtrl.dispose();
    super.dispose();
  }

  // Paging skips locked (not-owned) talents entirely — landing on one would
  // contradict them being non-tappable from the grid. If there's no other
  // owned talent in that direction, shake the arrow instead of moving.
  void _step(int delta) {
    final talents =
        ref.read(talentsProvider).valueOrNull?.talents ?? const <TalentView>[];
    if (_selectedKey == null || talents.isEmpty) return;
    final idx = talents.indexWhere((t) => t.key == _selectedKey);
    if (idx == -1) return;
    var i = idx;
    for (var step = 0; step < talents.length; step++) {
      i = (i + delta + talents.length) % talents.length;
      if (i == idx) break;
      if (talents[i].owned) {
        setState(() {
          _selectedKey = talents[i].key;
          _revealTalent = null;
          _levelUpFrom = null;
          _levelUpTo = null;
        });
        _popCtrl.forward(from: 0);
        return;
      }
    }
    setState(() {
      if (delta < 0) {
        _leftShake++;
      } else {
        _rightShake++;
      }
    });
  }

  Future<void> _draw() async {
    if (_busy) return;
    // Snapshot the catalog in its current (pre-draw) render order — this is
    // what the border sweep spins through. Crucially, we do NOT refresh the
    // live provider until the sweep actually lands (see below) — refreshing
    // any earlier would let the grid show the unlocked/leveled tile before
    // the sweep visually gets there, spoiling the reveal.
    final talents =
        ref.read(talentsProvider).valueOrNull?.talents ?? const <TalentView>[];
    if (talents.isEmpty) return;
    setState(() => _busy = true);
    var revealing = false;
    try {
      final result = await ref.read(talentsProvider.notifier).draw();
      if (!mounted) return;
      final targetIndex = talents.indexWhere((t) => t.key == result.talent.key);
      if (targetIndex != -1) {
        // Pre-draw level, so a duplicate that leveled up an already-owned
        // talent can show "Lv.2 → Lv.3" rather than just the new level.
        final preLevel = talents[targetIndex].level;
        final leveledUp = !result.isNew &&
            result.crystalsAwarded == 0 &&
            result.talent.level > preLevel;
        await _runSweep(targetIndex, talents.length);
        if (!mounted) return;
        // Only now, having landed, do we pull in the fresh wallet/level
        // data — and show the drawn talent, popped up centre-screen exactly
        // like a manual tap, using the result's own data so it's correct
        // even before the background refetch below resolves.
        ref.invalidate(talentsProvider);
        ref.invalidate(characterProfileProvider);
        setState(() {
          _selectedKey = result.talent.key;
          _revealTalent = result.talent;
          _levelUpFrom = leveledUp ? preLevel : null;
          _levelUpTo = leveledUp ? result.talent.level : null;
        });
        _revealCtrl.forward(from: 0);
        _popCtrl.forward(from: 0);
        if (leveledUp) _levelUpCtrl.forward(from: 0);
        revealing = true;
      } else {
        // The catalog changed while this screen was open, so the server
        // returned a talent that is not present in the pre-draw grid
        // snapshot. We cannot land the roulette sweep on a missing tile;
        // refresh both read models and show the authoritative result
        // directly so the wallet/card state never stays stale.
        ref.invalidate(talentsProvider);
        ref.invalidate(characterProfileProvider);
        setState(() {
          _selectedKey = result.talent.key;
          _revealTalent = result.talent;
          _levelUpFrom = null;
          _levelUpTo = null;
        });
        _revealCtrl.forward(from: 0);
        _popCtrl.forward(from: 0);
        revealing = true;
      }
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _sweepAnim = null;
          if (!revealing) {
            _selectedKey = null;
            _revealTalent = null;
            _levelUpFrom = null;
            _levelUpTo = null;
          }
        });
      }
    }
  }

  /// Jumps a single highlight across the real grid tiles, looping a couple
  /// of times before decelerating into `targetIndex`.
  Future<void> _runSweep(int targetIndex, int length) async {
    const loops = 2;
    final totalSteps = loops * length + targetIndex;
    _sweepCtrl.duration = const Duration(milliseconds: 1500);
    final anim = Tween<double>(begin: 0, end: totalSteps.toDouble()).animate(
        CurvedAnimation(parent: _sweepCtrl, curve: Curves.easeOutCubic));
    setState(() {
      _sweepAnim = anim;
      _sweepLength = length;
    });
    await _sweepCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(talentsProvider);
    final selectedKey = _selectedKey;
    final selectedTalent = selectedKey == null
        ? null
        : _findTalent(async.valueOrNull, selectedKey) ??
            (_revealTalent?.key == selectedKey ? _revealTalent : null);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // A Stack (rather than nesting the popped card inside the grid's own
        // layout) so its scrim can cover the *entire* screen — header,
        // currency bar and draw button included — letting a tap literally
        // anywhere dismiss the popped talent, not just within the grid.
        child: Stack(
          children: [
            Column(
              children: [
                _Header(onClose: widget.onClose),
                Expanded(
                  child: async.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.blue, strokeWidth: 2),
                    ),
                    error: (e, _) => _ErrorState(
                      onRetry: () =>
                          ref.read(talentsProvider.notifier).refresh(),
                    ),
                    data: (screen) => _Body(
                      screen: screen,
                      hasSelection: selectedTalent != null,
                      busy: _busy,
                      onSelect: (k) {
                        setState(() {
                          _selectedKey = k;
                          _revealTalent = null;
                          _levelUpFrom = null;
                          _levelUpTo = null;
                        });
                        _popCtrl.forward(from: 0);
                      },
                      onDraw: _draw,
                      sweepAnim: _sweepAnim,
                      sweepLength: _sweepLength,
                    ),
                  ),
                ),
              ],
            ),
            if (selectedTalent != null)
              _PoppedOverlay(
                talent: selectedTalent,
                talentsCount: async.valueOrNull?.talents.length ?? 0,
                revealTalent: _revealTalent,
                revealAnim: _revealAnim,
                levelUpFrom: _levelUpFrom,
                levelUpTo: _levelUpTo,
                levelUpAnim: _levelUpAnim,
                popAnim: _popAnim,
                onDeselect: () => setState(() {
                  _selectedKey = null;
                  _revealTalent = null;
                  _levelUpFrom = null;
                  _levelUpTo = null;
                }),
                onStepPrev: () => _step(-1),
                onStepNext: () => _step(1),
                leftShake: _leftShake,
                rightShake: _rightShake,
              ),
          ],
        ),
      ),
    );
  }

  TalentView? _findTalent(TalentScreen? screen, String key) {
    if (screen == null) return null;
    for (final t in screen.talents) {
      if (t.key == key) return t;
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  final VoidCallback? onClose;
  const _Header({this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
      child: Row(
        children: [
          const SizedBox(width: 32),
          const Spacer(),
          const Text(
            'TALENTS',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          _InfoButton(onTap: () => showTalentInfoSheet(context)),
        ],
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _InfoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.info_outline,
            size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final TalentScreen screen;
  final bool hasSelection;
  final bool busy;
  final ValueChanged<String> onSelect;
  final VoidCallback onDraw;
  final Animation<double>? sweepAnim;
  final int sweepLength;

  const _Body({
    required this.screen,
    required this.hasSelection,
    required this.busy,
    required this.onSelect,
    required this.onDraw,
    required this.sweepAnim,
    required this.sweepLength,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        _CurrencyBar(wallet: screen.wallet),
        const SizedBox(height: 16),
        _TalentGrid(
          talents: screen.talents,
          busy: busy,
          onSelect: onSelect,
          sweepAnim: sweepAnim,
          sweepLength: sweepLength,
        ),
        const SizedBox(height: 16),
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.5,
            child: _DrawButton(
              crystalCost: screen.drawCrystalCost,
              coinCost: screen.drawCoinCost,
              // Also disabled while a talent is popped up — drawing while
              // looking at one would fight the reveal for attention.
              enabled: screen.canDraw && !busy && !hasSelection,
              onTap: onDraw,
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrencyBar extends StatelessWidget {
  final TalentWallet wallet;
  const _CurrencyBar({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _iconPill(AppIcons.homeCoinIcon, '${wallet.coins}', AppColors.orange),
        _iconPill(
            AppIcons.talentCrystalIcon, '${wallet.crystals}', AppColors.purple),
      ],
    );
  }

  Widget _iconPill(String asset, String value, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconImage(asset, size: 18),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ── Honeycomb talent grid ──────────────────────────────────────────────────
//
// JUDGMENT CALL: a plain, uniform 4-column grid — every row (bar a trailing
// partial one) holds exactly 4 tiles in straight rows/columns with regular
// gaps, matching the reference layout — rather than the earlier honeycomb
// offset-row arrangement. Hexagons are still approximated via
// `_HexagonClipper` (pointy-top, point at top/bottom).
//
// Tapping a tile pops it up centre-screen (see `_PoppedOverlay`) — matching
// the reference "card zoom" interaction — instead of the grid staying
// static with a separate detail block below it.
class _TalentGrid extends StatelessWidget {
  final List<TalentView> talents;
  final bool busy;
  final ValueChanged<String> onSelect;
  final Animation<double>? sweepAnim;
  final int sweepLength;

  static const int _kCols = 4;
  static const double _kSpacing = 12;
  static const double _kRowGap = 14;
  static const double _kPopScale = 1.85;

  const _TalentGrid({
    required this.talents,
    required this.busy,
    required this.onSelect,
    required this.sweepAnim,
    required this.sweepLength,
  });

  @override
  Widget build(BuildContext context) {
    if (talents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No talents yet',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final tileW = (width - (_kCols - 1) * _kSpacing) / _kCols;
      final tileH = tileW * 1.15;
      final rowStep = tileH + _kRowGap;
      final rowCount = (talents.length / _kCols).ceil();

      final children = <Widget>[];

      for (var idx = 0; idx < talents.length; idx++) {
        final t = talents[idx];
        final r = idx ~/ _kCols;
        final c = idx % _kCols;
        final x = c * (tileW + _kSpacing);
        final y = r * rowStep;

        children.add(Positioned(
          left: x,
          top: y,
          width: tileW,
          height: tileH,
          child: _HexTalentTile(
            talent: t,
            selected: false,
            // Locked (not-owned) talents are non-interactive; all tiles are
            // inert while a draw's sweep/win flourish is playing.
            onTap: (t.owned && !busy) ? () => onSelect(t.key) : null,
            sweepAnim: sweepAnim,
            tileIndex: idx,
            sweepLength: sweepLength,
          ),
        ));
      }

      final totalHeight = (rowCount - 1) * rowStep + tileH + 12;

      return SizedBox(
        width: width,
        height: totalHeight,
        child: Stack(clipBehavior: Clip.none, children: children),
      );
    });
  }
}

/// The popped-up talent card — shown as a screen-wide overlay (a sibling of
/// the header/grid/draw-button, not nested inside the grid's own layout) so
/// its scrim covers the *whole* screen: tapping anywhere outside the card
/// itself or its paging arrows dismisses it.
class _PoppedOverlay extends StatelessWidget {
  final TalentView talent;
  final int talentsCount;
  final TalentView? revealTalent;
  final Animation<double> revealAnim;
  // Set only when this draw was a duplicate that leveled up an
  // already-owned talent — drives the big "Lv.2 → Lv.3" zoom-in flourish.
  final int? levelUpFrom;
  final int? levelUpTo;
  final Animation<double> levelUpAnim;
  // Plays once whenever this card opens (tap, page, or draw landing) — a
  // soft scale+fade "pop" so it never just snaps into view.
  final Animation<double> popAnim;
  final VoidCallback onDeselect;
  final VoidCallback onStepPrev;
  final VoidCallback onStepNext;
  final int leftShake;
  final int rightShake;

  const _PoppedOverlay({
    required this.talent,
    required this.talentsCount,
    required this.revealTalent,
    required this.revealAnim,
    required this.levelUpFrom,
    required this.levelUpTo,
    required this.levelUpAnim,
    required this.popAnim,
    required this.onDeselect,
    required this.onStepPrev,
    required this.onStepNext,
    required this.leftShake,
    required this.rightShake,
  });

  // Matches _Body's ListView horizontal padding (16 + 16) so the popped
  // card ends up the same size it would have been sized at inside the grid.
  static const double _kHPad = 32;
  // This overlay now spans the *whole* screen (header included) so the
  // scrim can catch a tap anywhere, but the card itself should still sit
  // where the grid used to centre it — approximates the header + currency
  // bar's height above the grid.
  static const double _kTopInset = 98;

  @override
  Widget build(BuildContext context) {
    // If this popped card is the one a draw just landed on, prefer the draw
    // result's own (fresh) data over the live grid's — the grid may still
    // be mid-refetch — and drive the flip-in/Lv-grow flourish.
    final isRevealTarget =
        revealTalent != null && talent.key == revealTalent!.key;
    final displayTalent = isRevealTarget ? revealTalent! : talent;
    final levelUpColor = talentRarityColor(displayTalent.rarity);

    return Positioned.fill(
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        const tileAspect = 1.15;
        final tileW = (width -
                _kHPad -
                (_TalentGrid._kCols - 1) * _TalentGrid._kSpacing) /
            _TalentGrid._kCols;
        final tileH = tileW * tileAspect;
        final bigW = tileW * _TalentGrid._kPopScale;
        final bigH = tileH * _TalentGrid._kPopScale;
        final cx = width / 2;
        // Centre within the grid's own (deterministic) height, exactly as
        // when this card lived inside the grid's own layout — the grid
        // always has enough headroom below for the info text without
        // reaching down as far as the draw button.
        final rowCount = (talentsCount / _TalentGrid._kCols).ceil();
        final rowStep = tileH + _TalentGrid._kRowGap;
        final tilesHeightOnly = (rowCount - 1) * rowStep + tileH;
        final cy = _kTopInset + tilesHeightOnly / 2;
        final bigLeft = cx - bigW / 2;
        final bigTop = cy - bigH / 2;
        const arrowSize = 34.0;
        final arrowY = cy - arrowSize / 2;
        final leftArrowX =
            (bigLeft - arrowSize - 6).clamp(4.0, width - arrowSize - 4.0);
        final rightArrowX =
            (bigLeft + bigW + 6).clamp(4.0, width - arrowSize - 4.0);

        return AnimatedBuilder(
          animation: popAnim,
          builder: (context, _) {
            // `popAnim` uses an overshooting curve for a soft "pop" bounce
            // on the card itself; opacity is clamped since "more than fully
            // visible" isn't meaningful.
            final raw = popAnim.value;
            final fade = raw.clamp(0.0, 1.0);
            final cardScale = 0.72 + 0.28 * raw;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Full-screen scrim — a soft gray dim (not pure black) so the
                // dimmed screen stays legible — dismisses on tap.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onDeselect,
                    child: Opacity(
                      opacity: fade,
                      child: Container(
                          color: AppColors.surfaceDisabled
                              .withValues(alpha: 0.62)),
                    ),
                  ),
                ),
                Positioned(
                  left: bigLeft,
                  top: bigTop,
                  width: bigW,
                  height: bigH,
                  child: Opacity(
                    opacity: fade,
                    child: Transform.scale(
                      scale: cardScale,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap:
                            () {}, // absorb taps so the card doesn't deselect
                        child: _HexTalentTile(
                          talent: displayTalent,
                          selected: true,
                          onTap: () {},
                          revealAnim: isRevealTarget ? revealAnim : null,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isRevealTarget && levelUpFrom != null && levelUpTo != null)
                  Positioned(
                    left: bigLeft,
                    top: bigTop,
                    width: bigW,
                    height: bigH,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: levelUpAnim,
                        builder: (context, child) {
                          // Raw (linear) progress — used as-is for the
                          // fade-in/hold/fade-out timing below, so those
                          // fractions genuinely mean "fraction of the few
                          // seconds this plays for."
                          final t = levelUpAnim.value;
                          final scale =
                              0.96 + 0.16 * Curves.easeOut.transform(t);
                          final fadeIn = (t / 0.12).clamp(0.0, 1.0);
                          final fadeOut =
                              t > 0.8 ? ((1 - t) / 0.2).clamp(0.0, 1.0) : 1.0;
                          final opacity = math.min(fadeIn, fadeOut);
                          return Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: scale,
                              child: Center(
                                // A solid plaque behind the text — plain text
                                // over the card itself blended too faintly
                                // against the tile's own colour to read at a
                                // glance, whatever the tile's rarity colour.
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.background
                                        .withValues(alpha: 0.94),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                        color: levelUpColor, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                          color: levelUpColor.withValues(
                                              alpha: 0.65),
                                          blurRadius: 12,
                                          spreadRadius: 1),
                                    ],
                                  ),
                                  child: Text(
                                    'Lv.$levelUpFrom → Lv.$levelUpTo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: levelUpColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                Positioned(
                  left: leftArrowX,
                  top: arrowY,
                  child: Opacity(
                    opacity: fade,
                    child: _PopArrow(
                      icon: Icons.chevron_left,
                      onTap: onStepPrev,
                      shakeTrigger: leftShake,
                    ),
                  ),
                ),
                Positioned(
                  left: rightArrowX,
                  top: arrowY,
                  child: Opacity(
                    opacity: fade,
                    child: _PopArrow(
                      icon: Icons.chevron_right,
                      onTap: onStepNext,
                      shakeTrigger: rightShake,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: bigTop + bigH + 8,
                  child: Opacity(
                    opacity: fade,
                    child: _PoppedTalentInfo(talent: displayTalent),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

/// A paging arrow that shakes in place when `shakeTrigger` changes — the
/// parent bumps that counter when there's no other unlocked talent to page
/// to in that direction, instead of the arrow silently doing nothing.
class _PopArrow extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int shakeTrigger;
  const _PopArrow({
    required this.icon,
    required this.onTap,
    required this.shakeTrigger,
  });

  @override
  State<_PopArrow> createState() => _PopArrowState();
}

class _PopArrowState extends State<_PopArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _offset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: -2.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -2.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant _PopArrow old) {
    super.didUpdateWidget(old);
    if (widget.shakeTrigger != old.shakeTrigger) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_offset.value, 0), child: child),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Icon(widget.icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

class _PoppedTalentInfo extends StatelessWidget {
  final TalentView talent;

  const _PoppedTalentInfo({required this.talent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Text(
            talent.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            talent.owned
                ? '${talent.rarity} · Lv.${talent.level} / ${talent.maxLevel}'
                : '${talent.rarity} · not owned',
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            talent.owned ? talent.effectText : talent.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12.5, height: 1.4, color: AppColors.textPrimary),
          ),
          if (talent.owned && talent.isMaxed) ...[
            const SizedBox(height: 12),
            const Text('Max level',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  const _HexagonClipper();

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HexTalentTile extends StatelessWidget {
  final TalentView talent;
  final bool selected;
  final VoidCallback? onTap;
  // The border sweep's position plus this tile's own index/grid length.
  // Each frame resolves to exactly one highlighted tile.
  final Animation<double>? sweepAnim;
  final int? tileIndex;
  final int? sweepLength;
  // Non-null only for the popped-up card the draw just landed on — it
  // drives a soft reveal tilt plus a growing Lv badge, so the
  // "new/updated" result reads clearly without feeling jumpy.
  final Animation<double>? revealAnim;

  const _HexTalentTile({
    required this.talent,
    required this.selected,
    required this.onTap,
    this.sweepAnim,
    this.tileIndex,
    this.sweepLength,
    this.revealAnim,
  });

  @override
  Widget build(BuildContext context) {
    final accent = talentRarityColor(talent.rarity);
    final dim = !talent.owned;
    final borderW = selected ? 3.0 : 1.6;
    final anim = revealAnim;

    Widget hex;
    final sweep = sweepAnim;
    if (sweep != null &&
        sweepLength != null &&
        sweepLength! > 0 &&
        tileIndex != null) {
      hex = AnimatedBuilder(
        animation: sweep,
        builder: (context, _) {
          final activeIndex = sweep.value.floor() % sweepLength!;
          final isActive = activeIndex == tileIndex;
          return _buildHex(accent, dim, borderW, isActive ? 1.0 : 0.0);
        },
      );
    } else {
      hex = _buildHex(accent, dim, borderW, 0.0);
    }

    if (anim != null) {
      hex = AnimatedBuilder(
        animation: anim,
        builder: (context, child) {
          final angle = (1 - anim.value) * 0.22;
          final lift = (1 - anim.value) * 6;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            child: Transform.translate(offset: Offset(0, lift), child: child),
          );
        },
        child: hex,
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: hex,
    );
  }

  Widget _buildHex(
      Color accent, bool dim, double borderW, double sweepIntensity) {
    final baseColor =
        selected ? accent : accent.withValues(alpha: dim ? 0.18 : 0.55);
    final outerColor = sweepIntensity > 0
        ? Color.lerp(baseColor, AppColors.orange, sweepIntensity)!
        : baseColor;
    final glowColor = sweepIntensity > 0 ? AppColors.orange : accent;
    final glowAlpha = selected ? 0.28 : 0.55 * sweepIntensity;
    final glowBlur = selected ? 12.0 : 14.0 * sweepIntensity;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (selected || sweepIntensity > 0.01)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: glowColor.withValues(
                          alpha: glowAlpha.clamp(0.0, 1.0)),
                      blurRadius: glowBlur,
                      spreadRadius: selected ? 0 : sweepIntensity),
                ],
              ),
            ),
          ),
        // Outer hex = border colour.
        Positioned.fill(
          child: ClipPath(
            clipper: const _HexagonClipper(),
            child: ColoredBox(color: outerColor),
          ),
        ),
        // Inner hex, inset by border width = fill.
        Positioned(
          left: borderW,
          top: borderW,
          right: borderW,
          bottom: borderW,
          child: const ClipPath(
            clipper: _HexagonClipper(),
            child: ColoredBox(color: AppColors.surface),
          ),
        ),
        // Icon.
        Positioned.fill(
          child: Center(
            child: Opacity(
              opacity: dim ? 0.4 : 1,
              child: AppIconImage(talentIconAsset(talent.key), size: 30),
            ),
          ),
        ),
        // Lv.N pill, sitting within the hex's lower band.
        if (talent.owned)
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: Center(child: _lvPill(accent, revealAnim)),
          ),
      ],
    );
  }

  Widget _lvPill(Color accent, Animation<double>? anim) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Text(
        'Lv.${talent.level}',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
    if (anim == null) return pill;
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final t = anim.value.clamp(0.0, 1.0);
        final bulge = math.sin(t * math.pi);
        final scale = 0.8 + 0.2 * t + 0.25 * bulge;
        return Transform.scale(scale: scale, child: child);
      },
      child: pill,
    );
  }
}

class _DrawButton extends StatelessWidget {
  final int crystalCost;
  final int coinCost;
  final bool enabled;
  final VoidCallback onTap;

  const _DrawButton({
    required this.crystalCost,
    required this.coinCost,
    required this.enabled,
    required this.onTap,
  });

  static const _gold = Color(0xFFFFE08A);
  static const _amber = Color(0xFFE8951F);
  static const _brown = Color(0xFF6B3F14);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SizedBox(
        height: 62,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipPath(
                clipper: const _BannerClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_gold, _amber],
                      stops: [0.0, 0.85],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _OutlinedText('Card Draw',
                            fontSize: 17, letterSpacing: 0.5),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _drawChip(AppIcons.homeCoinIcon, coinCost),
                            const SizedBox(width: 14),
                            _drawChip(AppIcons.talentCrystalIcon, crystalCost),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Border, drawn as a second clipped layer behind via a slightly
              // larger inset so it reads as an outline without a stroked
              // ClipPath (Flutter can't stroke a clip path directly).
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _BannerBorderPainter()),
                ),
              ),
              if (enabled)
                const Positioned(
                  top: -6,
                  right: 4,
                  child: _AvailableBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawChip(String asset, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconImage(asset, size: 15),
        const SizedBox(width: 3),
        _OutlinedText('x$value', fontSize: 12, letterSpacing: 0),
      ],
    );
  }
}

/// Cut-corner "banner" silhouette — a hexagon-ish ribbon shape instead of a
/// plain rounded rectangle, matching the reference button's gem-cut look.
class _BannerClipper extends CustomClipper<Path> {
  const _BannerClipper();

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    const cut = 16.0;
    return Path()
      ..moveTo(cut, 0)
      ..lineTo(w - cut, 0)
      ..lineTo(w, h * 0.32)
      ..lineTo(w, h * 0.68)
      ..lineTo(w - cut, h)
      ..lineTo(cut, h)
      ..lineTo(0, h * 0.68)
      ..lineTo(0, h * 0.32)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BannerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = const _BannerClipper().getClip(size);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _DrawButton._brown,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bold white text with a dark outline — the pixel-art "stroke" look, built
/// from a stack of offset shadow copies behind the real text since Flutter
/// text has no native stroke-paint mode for arbitrary fonts.
class _OutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double letterSpacing;
  const _OutlinedText(this.text,
      {required this.fontSize, required this.letterSpacing});

  @override
  Widget build(BuildContext context) {
    final shadowStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: letterSpacing,
      color: _DrawButton._brown,
    );
    final mainStyle = shadowStyle.copyWith(color: Colors.white);
    return Stack(
      children: [
        for (final o in const [
          Offset(-1.2, -1.2),
          Offset(1.2, -1.2),
          Offset(-1.2, 1.2),
          Offset(1.2, 1.2),
        ])
          Transform.translate(offset: o, child: Text(text, style: shadowStyle)),
        Text(text, style: mainStyle),
      ],
    );
  }
}

class _AvailableBadge extends StatelessWidget {
  const _AvailableBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: const Center(
        child: Text('!',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load talents',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
