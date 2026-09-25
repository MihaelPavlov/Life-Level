import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../motion/app_motion.dart';
import '../motion/motion_widgets.dart';

/// Icon + value pill used to show a currency/stat (coins, gems, steps) in a
/// screen header, with an optional green "+" badge.
///
/// When [onTapAdd] is provided, the whole chip (not just the "+") is
/// tappable — matches the Home screen's original "the chip is the entry
/// point into the Shop" design. Visual defaults match Home's header chips;
/// pass the style params to match a different screen's look (e.g. Region
/// Chests' darker, more opaque chip).
///
/// When [value] changes the changed digits flip like a split-flap board and
/// a small pill with the difference ("+250" / "−320") drops out beneath the
/// chip and fades.
class CurrencyChip extends StatefulWidget {
  final String iconAsset;
  final String value;
  final bool showAdd;
  final VoidCallback? onTapAdd;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final double iconSize;
  final double valueFontSize;
  final double gap;
  final double addSize;
  final double addIconSize;

  const CurrencyChip({
    super.key,
    required this.iconAsset,
    required this.value,
    this.showAdd = true,
    this.onTapAdd,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    this.backgroundColor = const Color(0x73000000), // Colors.black @ 45%
    this.borderColor = const Color(0x29FFFFFF), // Colors.white @ 16%
    this.borderRadius = const BorderRadius.all(Radius.circular(11)),
    this.iconSize = 14,
    this.valueFontSize = 10.5,
    this.gap = 4,
    this.addSize = 14,
    this.addIconSize = 10,
  });

  @override
  State<CurrencyChip> createState() => _CurrencyChipState();
}

class _CurrencyChipState extends State<CurrencyChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pill = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..addListener(() => setState(() {}));
  int _delta = 0;
  final _mountedAt = DateTime.now();

  static int? _num(String s) {
    final d = s.replaceAll(RegExp(r'[^0-9]'), '');
    return d.isEmpty ? null : int.tryParse(d);
  }

  @override
  void didUpdateWidget(CurrencyChip old) {
    super.didUpdateWidget(old);
    final a = _num(old.value), b = _num(widget.value);
    if (a == null || b == null || a == b) return;
    if (!AppMotion.isFull(context)) return;
    // Ignore the initial load (placeholder → real balance).
    if (DateTime.now().difference(_mountedAt) <
        const Duration(milliseconds: 1500)) {
      return;
    }
    _delta = b - a;
    _pill.forward(from: 0);
  }

  @override
  void dispose() {
    _pill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final up = _delta > 0;
    final tint = up ? AppColors.orange : AppColors.red;
    final t = _pill.value;
    final glow =
        _pill.isAnimating ? (t < .3 ? t / .3 : 1 - (t - .3) / .7) : 0.0;

    final content = Container(
      padding: w.padding,
      decoration: BoxDecoration(
        color: w.backgroundColor,
        border: Border.all(color: Color.lerp(w.borderColor, tint, glow)!),
        borderRadius: w.borderRadius,
        boxShadow: glow > 0
            ? [
                BoxShadow(
                    color: tint.withValues(alpha: .5 * glow), blurRadius: 14)
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(w.iconAsset,
              width: w.iconSize, height: w.iconSize, fit: BoxFit.contain),
          SizedBox(width: w.gap),
          FlapText(
            w.value,
            style: TextStyle(
                fontSize: w.valueFontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          if (w.showAdd) ...[
            SizedBox(width: w.gap),
            Container(
              width: w.addSize,
              height: w.addSize,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.green),
              child: Icon(Icons.add, size: w.addIconSize, color: Colors.white),
            ),
          ],
        ],
      ),
    );

    final chip = _pill.isAnimating ? _withPill(content, up, tint, t) : content;

    if (w.onTapAdd == null) return chip;
    return Material(
      color: Colors.transparent,
      borderRadius: w.borderRadius,
      child: InkWell(
        borderRadius: w.borderRadius,
        onTap: w.onTapAdd,
        child: chip,
      ),
    );
  }

  Widget _withPill(Widget content, bool up, Color tint, double t) {
    final inT = (t / .2).clamp(0.0, 1.0);
    final opacity = t < .75 ? inT : 1 - (t - .75) / .25;
    final dy = 16 * Curves.easeOut.transform(inT) +
        8 * ((t - .75).clamp(0.0, .25) / .25);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        content,
        Positioned(
          top: dy + 14,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: .6 + .4 * inT,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: .2),
                    border: Border.all(color: tint.withValues(alpha: .65)),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '${up ? '+' : '−'}${_delta.abs()}',
                    style: TextStyle(
                      color: up
                          ? const Color(0xFFFFE2A8)
                          : const Color(0xFFFFC3CF),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
