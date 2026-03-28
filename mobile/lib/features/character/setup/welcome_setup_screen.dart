import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'class_selection_screen.dart';

class WelcomeSetupScreen extends StatelessWidget {
  final List<String> ringItems;
  const WelcomeSetupScreen({super.key, required this.ringItems});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Blue gradient glow at top
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.9),
                radius: 1.2,
                colors: [Color(0x1A4f9eff), Color(0x00040810)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Logo ring
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.blue.withOpacity(0.2),
                          AppColors.purple.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                          color: AppColors.blue.withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.blue.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 2),
                      ],
                    ),
                    child: const Center(
                        child: Text('⚔️', style: TextStyle(fontSize: 38))),
                  ),
                  const SizedBox(height: 28),
                  // Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.1),
                      border:
                          Border.all(color: AppColors.blue.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'YOUR ADVENTURE BEGINS',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue,
                          letterSpacing: 1.0),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Title
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.25),
                      children: [
                        TextSpan(
                            text: 'Train in the Real World.\n',
                            style: TextStyle(color: AppColors.textPrimary)),
                        TextSpan(
                            text: 'Level Up in the Game.',
                            style: TextStyle(color: AppColors.blue)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Every workout you complete earns XP, raises your stats, and moves your hero across a living RPG world. Let\'s set up your character.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.65),
                  ),
                  const SizedBox(height: 36),
                  // Pillars
                  _pillar(
                    '⚡',
                    AppColors.blue,
                    'Real activity → Real XP',
                    'Every run, gym session, or yoga class earns experience and raises your stats.',
                  ),
                  const SizedBox(height: 10),
                  _pillar(
                    '🗺️',
                    AppColors.purple,
                    'Explore the Adventure Map',
                    'Distance you cover in the real world moves your hero across zones.',
                  ),
                  const SizedBox(height: 10),
                  _pillar(
                    '🏆',
                    AppColors.orange,
                    'Compete & Conquer',
                    'Join guild raids, take on weekly challenges, and climb the leaderboard.',
                  ),
                  const Spacer(flex: 3),
                  // Progress dots
                  setupProgressDots(current: 0, total: 4),
                  const SizedBox(height: 24),
                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ClassSelectionScreen(ringItems: ringItems)),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        "LET'S GO →",
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _showSkipDialog(context),
                    child: const Text(
                      'Skip Setup',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSkipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0f1828),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.red.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: AppColors.red.withOpacity(0.1), blurRadius: 40),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🚫', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              const Text(
                'Not So Fast, Hero.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              const Text(
                'Every legend has an origin story.\nYours starts here — nameless heroes don\'t make the leaderboard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.08),
                  border: Border.all(color: AppColors.red.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '⚔️  Choose your class.\n🧙  Pick your avatar.\n🗺️  Then conquer the world.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      height: 1.7),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ClassSelectionScreen(ringItems: ringItems)),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("FORGE MY LEGEND →",
                      style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Maybe later',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillar(String emoji, Color color, String title, String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceElevated),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared progress dot indicator used across all setup screens.
Widget setupProgressDots({required int current, required int total}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(total, (i) {
      final isActive = i == current;
      final isDone = i < current;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone
              ? AppColors.green
              : isActive
                  ? AppColors.blue
                  : AppColors.surfaceElevated,
          border: (isDone || isActive)
              ? null
              : Border.all(color: const Color(0xFF30363d)),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: AppColors.blue.withOpacity(0.6),
                      blurRadius: 6)
                ]
              : null,
        ),
      );
    }),
  );
}
