import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/character_class.dart';
import 'character_created_screen.dart';
import 'welcome_setup_screen.dart' show setupProgressDots;

const _kUnlockedAvatars = [
  '🧙', '⚔️', '🏹', '🛡️', '🧘', '🐺', '🦊', '🥷', '🦸', '🧝',
];
const _kLockedAvatars = [
  '👑', '🌟', '💎', '🔮', '⚡', '🌙',
];

class AvatarSelectionScreen extends StatefulWidget {
  final CharacterClass selectedClass;
  final List<String> ringItems;

  const AvatarSelectionScreen({
    super.key,
    required this.selectedClass,
    required this.ringItems,
  });

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Orange gradient glow at top
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.9),
                radius: 1.2,
                colors: [Color(0x12f5a623), Color(0x00040810)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFF30363d)),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'STEP 3 OF 4',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.6),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Choose Your Avatar',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'This is how other players will see you on the map and leaderboards.',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      setupProgressDots(current: 2, total: 4),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selected class badge
                        Row(
                          children: [
                            Text(widget.selectedClass.emoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              widget.selectedClass.name,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Preview circle
                        Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.blue.withOpacity(0.2),
                                  AppColors.purple.withOpacity(0.2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: _selected != null
                                    ? AppColors.orange.withOpacity(0.6)
                                    : AppColors.blue.withOpacity(0.4),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_selected != null
                                          ? AppColors.orange
                                          : AppColors.blue)
                                      .withOpacity(0.2),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _selected ?? '?',
                                style: const TextStyle(fontSize: 36),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'AVAILABLE',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _kUnlockedAvatars.length,
                          itemBuilder: (_, i) {
                            final emoji = _kUnlockedAvatars[i];
                            final picked = _selected == emoji;
                            return GestureDetector(
                              onTap: () => setState(() => _selected = emoji),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: picked
                                      ? AppColors.orange.withOpacity(0.08)
                                      : AppColors.surface,
                                  border: Border.all(
                                    color: picked
                                        ? AppColors.orange.withOpacity(0.6)
                                        : AppColors.surfaceElevated,
                                    width: picked ? 1.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: picked
                                      ? [
                                          BoxShadow(
                                              color: AppColors.orange
                                                  .withOpacity(0.15),
                                              blurRadius: 10)
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(emoji,
                                      style:
                                          const TextStyle(fontSize: 26)),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'LOCKED — UNLOCK AT HIGHER LEVELS',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.6),
                        ),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _kLockedAvatars.length,
                          itemBuilder: (_, i) => Opacity(
                            opacity: 0.35,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    border: Border.all(
                                        color: AppColors.surfaceElevated),
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(_kLockedAvatars[i],
                                        style: const TextStyle(
                                            fontSize: 26)),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text('🔒',
                                          style: TextStyle(fontSize: 8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.surfaceElevated),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Text('💡', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'More avatars unlock as you level up. Legendary avatars require Rank: Champion or higher.',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sticky CTA
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CharacterCreatedScreen(
                              selectedClass: widget.selectedClass,
                              avatarEmoji: _selected!,
                              ringItems: widget.ringItems,
                            ),
                          ),
                        ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  disabledBackgroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'CONTINUE →',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
