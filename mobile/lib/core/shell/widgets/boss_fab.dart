import 'package:flutter/material.dart';
import '../shell_constants.dart';

class BossFab extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const BossFab({
    super.key,
    required this.isOpen,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        width: kFabSize, height: kFabSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isOpen
              ? const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF1a2848), Color(0xFF1e3060)])
              : const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFff4040), Color(0xFFff8040)]),
          border: Border.all(
            color: isOpen
                ? const Color(0xFF4f9eff).withOpacity(0.5)
                : const Color(0xFFff7850).withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isOpen
                  ? const Color(0xFF4f9eff).withOpacity(0.25)
                  : const Color(0xFFff503c).withOpacity(0.55),
              blurRadius: 28,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isOpen
                  ? const Text('✕', key: ValueKey('x'),
                      style: TextStyle(fontSize: 22, color: Colors.white,
                          fontWeight: FontWeight.w300))
                  : const Text('⚔️', key: ValueKey('s'),
                      style: TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: 1),
            Text(isOpen ? 'CLOSE' : 'BOSS',
                style: TextStyle(
                    fontSize: 8,
                    color: Colors.white.withOpacity(isOpen ? 0.6 : 0.85),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}
