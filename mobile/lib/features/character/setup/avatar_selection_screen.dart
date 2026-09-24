import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/motion/app_motion.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/class_icons.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../models/character_class.dart';
import 'character_created_screen.dart';
import 'setup_resume_service.dart';
import 'welcome_setup_screen.dart' show setupProgressDots;

class _AvatarOption {
  final String emoji;
  final String iconAsset;

  const _AvatarOption(this.emoji, this.iconAsset);
}

const _kUnlockedAvatars = [
  _AvatarOption('🧙', AppIcons.avatarWizard),
  _AvatarOption('⚔️', AppIcons.avatarWarrior),
  _AvatarOption('🏹', AppIcons.avatarArcher),
  _AvatarOption('🛡️', AppIcons.avatarPaladin),
  _AvatarOption('🧘', AppIcons.avatarMonk),
  _AvatarOption('🐺', AppIcons.avatarWolf),
  _AvatarOption('🦊', AppIcons.avatarFox),
  _AvatarOption('🥷', AppIcons.avatarNinja),
  _AvatarOption('🦸', AppIcons.avatarSuperhero),
  _AvatarOption('🧝', AppIcons.avatarElf),
];

const _kLockedAvatars = [
  _AvatarOption('👑', AppIcons.avatarCrown),
  _AvatarOption('🌟', AppIcons.avatarStar),
  _AvatarOption('💎', AppIcons.avatarDiamond),
  _AvatarOption('🔮', AppIcons.avatarMystic),
  _AvatarOption('⚡', AppIcons.avatarLightning),
  _AvatarOption('🌙', AppIcons.avatarMoon),
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
  void initState() {
    super.initState();
    SetupResumeService.instance.saveAvatarSelection(
      ringItems: widget.ringItems,
      selectedClass: widget.selectedClass,
    );
  }

  @override
  Widget build(BuildContext context) {
    final classAsset = classIconAsset(
      className: widget.selectedClass.name,
      classEmoji: widget.selectedClass.emoji,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.9),
                radius: 1.2,
                colors: [Color(0x12F5A623), Color(0x00040810)],
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
                            onTap: () async {
                              await SetupResumeService.instance
                                  .saveClassSelection(
                                ringItems: widget.ringItems,
                                selectedClass: widget.selectedClass,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF30363D),
                                ),
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
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Choose Your Avatar',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'This is how other players will see you on the map and leaderboards.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
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
                        Row(
                          children: [
                            if (classAsset != null) ...[
                              AppIconImage(classAsset, size: 20),
                            ] else ...[
                              Text(
                                widget.selectedClass.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Text(
                              widget.selectedClass.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                              child: () {
                                if (_selected == null) {
                                  return const Text(
                                    '?',
                                    style: TextStyle(fontSize: 36),
                                  );
                                }

                                final opt = _kUnlockedAvatars
                                    .cast<_AvatarOption?>()
                                    .firstWhere(
                                      (o) => o?.emoji == _selected,
                                      orElse: () => null,
                                    );

                                if (opt != null) {
                                  return AppIconImage(opt.iconAsset, size: 56);
                                }

                                return Text(
                                  _selected!,
                                  style: const TextStyle(fontSize: 36),
                                );
                              }(),
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
                            letterSpacing: 0.6,
                          ),
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
                            final option = _kUnlockedAvatars[i];
                            final picked = _selected == option.emoji;

                            return GestureDetector(
                              onTap: () async {
                                setState(() => _selected = option.emoji);
                                await SetupResumeService.instance
                                    .saveAvatarSelection(
                                  ringItems: widget.ringItems,
                                  selectedClass: widget.selectedClass,
                                  avatarEmoji: _selected,
                                );
                              },
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
                                            blurRadius: 10,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child:
                                      AppIconImage(option.iconAsset, size: 44),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'LOCKED - UNLOCK AT HIGHER LEVELS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.6,
                          ),
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
                                      color: AppColors.surfaceElevated,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: AppIconImage(
                                      _kLockedAvatars[i].iconAsset,
                                      size: 44,
                                    ),
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
                                      child: Icon(
                                        Icons.lock,
                                        size: 8,
                                        color: AppColors.textSecondary,
                                      ),
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
                            border:
                                Border.all(color: AppColors.surfaceElevated),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'More avatars unlock as you level up. Legendary avatars require Rank: Champion or higher.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
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
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected == null
                    ? null
                    : () async {
                        await SetupResumeService.instance.saveCharacterCreated(
                          ringItems: widget.ringItems,
                          selectedClass: widget.selectedClass,
                          avatarEmoji: _selected!,
                        );
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          AppRoute(
                            builder: (_) => CharacterCreatedScreen(
                              selectedClass: widget.selectedClass,
                              avatarEmoji: _selected!,
                              ringItems: widget.ringItems,
                            ),
                          ),
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  disabledBackgroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
