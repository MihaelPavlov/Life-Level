import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Icon + value pill used to show a currency/stat (coins, gems, steps) in a
/// screen header, with an optional green "+" badge.
///
/// When [onTapAdd] is provided, the whole chip (not just the "+") is
/// tappable — matches the Home screen's original "the chip is the entry
/// point into the Shop" design. Visual defaults match Home's header chips;
/// pass the style params to match a different screen's look (e.g. Region
/// Chests' darker, more opaque chip).
class CurrencyChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconAsset,
              width: iconSize, height: iconSize, fit: BoxFit.contain),
          SizedBox(width: gap),
          Text(
            value,
            style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          if (showAdd) ...[
            SizedBox(width: gap),
            Container(
              width: addSize,
              height: addSize,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.green),
              child: Icon(Icons.add, size: addIconSize, color: Colors.white),
            ),
          ],
        ],
      ),
    );

    if (onTapAdd == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTapAdd,
        child: content,
      ),
    );
  }
}
