import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/main_shell.dart';
import '../services/character_service.dart';
import '../models/character_class.dart';
import '../models/character_setup_result.dart';
import 'welcome_setup_screen.dart' show setupProgressDots;

class CharacterCreatedScreen extends StatefulWidget {
  final CharacterClass selectedClass;
  final String avatarEmoji;
  final List<String> ringItems;

  const CharacterCreatedScreen({
    super.key,
    required this.selectedClass,
    required this.avatarEmoji,
    required this.ringItems,
  });

  @override
  State<CharacterCreatedScreen> createState() =>
      _CharacterCreatedScreenState();
}

class _CharacterCreatedScreenState extends State<CharacterCreatedScreen> {
  final _service = CharacterService();
  CharacterSetupResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.setupCharacter(
        classId: widget.selectedClass.id,
        avatarEmoji: widget.avatarEmoji,
      );
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Setup failed. Tap to retry.';
        _loading = false;
      });
    }
  }

  void _enterWorld() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => MainShell(initialRingIds: widget.ringItems)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Green gradient glow
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [Color(0x183fb950), Color(0x00040810)],
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.green),
                        SizedBox(height: 16),
                        Text(
                          'Forging your character\u2026',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('\u274c',
                                  style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _setup,
                                style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.blue),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildSuccess(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final cls = widget.selectedClass;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      child: Column(
        children: [
          setupProgressDots(current: 3, total: 4),
          const SizedBox(height: 28),
          // Glow avatar ring
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green.withOpacity(0.08),
              border: Border.all(
                  color: AppColors.green.withOpacity(0.35), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: AppColors.green.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 4),
                BoxShadow(
                    color: AppColors.green.withOpacity(0.1),
                    blurRadius: 80),
              ],
            ),
            child: Center(
              child:
                  Text(widget.avatarEmoji, style: const TextStyle(fontSize: 52)),
            ),
          ),
          const SizedBox(height: 20),
          // Badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1),
              border: Border.all(color: AppColors.green.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'CHARACTER CREATED',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                  letterSpacing: 1.0),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Your Hero Awaits!',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          const Text(
            'Log your first workout to earn XP and begin your journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.65),
          ),
          const SizedBox(height: 28),
          // Character card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.surfaceElevated),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR CHARACTER',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.6),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.blue.withOpacity(0.2),
                            AppColors.purple.withOpacity(0.2),
                          ],
                        ),
                        border: Border.all(
                            color: AppColors.blue.withOpacity(0.4),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.blue.withOpacity(0.2),
                              blurRadius: 16)
                        ],
                      ),
                      child: Center(
                        child: Text(widget.avatarEmoji,
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Level 1',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _badge(cls.name, AppColors.purple),
                            const SizedBox(width: 6),
                            _badge('Novice', AppColors.orange),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _statChip('STR', '0', AppColors.red),
                    const SizedBox(width: 6),
                    _statChip('END', '0', AppColors.blue),
                    const SizedBox(width: 6),
                    _statChip('AGI', '0', const Color(0xFF38d9c8)),
                    const SizedBox(width: 6),
                    _statChip('FLX', '0', AppColors.purple),
                    const SizedBox(width: 6),
                    _statChip('STA', '0', AppColors.orange),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Starter rewards
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.surfaceElevated),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STARTER REWARDS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.6),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                        child: _rewardCard('⚡', '+500 XP',
                            'Account\nbonus', AppColors.blue)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _rewardCard('📜', '5 Quests',
                            'Daily quests\nunlocked', AppColors.purple)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _rewardCard('🗺️', 'Zone 1',
                            'Forest of\nEndurance', AppColors.green)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _enterWorld,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'ENTER THE WORLD →',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'You can update your class and avatar anytime\nfrom Profile → Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color),
        ),
      );

  Widget _statChip(String key, String val, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(key,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(val,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
        ),
      );

  Widget _rewardCard(
          String emoji, String value, String label, Color color) =>
      Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      );
}
