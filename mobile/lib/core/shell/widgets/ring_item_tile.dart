import 'package:flutter/material.dart';
import '../shell_constants.dart';
import '../shell_models.dart';

class RingItemTile extends StatelessWidget {
  final RingItem item;
  const RingItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  kItemSize,
      height: kItemSize,
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withOpacity(0.65), width: 1.5),
        boxShadow: [
          BoxShadow(color: item.color.withOpacity(0.22), blurRadius: 16),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 2),
          Text(item.label,
              style: TextStyle(
                  fontSize: 8,
                  color: item.color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}
