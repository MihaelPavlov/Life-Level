import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../character/providers/character_provider.dart';
import '../models/tutorial_topic.dart';
import '../providers/tutorial_provider.dart';
import '../tutorial_controller.dart';

/// The hub pushed from Profile → Settings → "Tutorials". Shows:
///   1. A "Play all" hero card that restarts the full walkthrough
///   2. A list of 5 topic rows with ✓ / ○ indicators derived from the
///      `tutorialTopicsSeen` bitmask on `CharacterProfile`
///
/// Tapping any row pops the hub + settings sheet and kicks off the matching
/// controller action — the integration pass decides how the overlay surfaces
/// back on Home. This screen itself only talks to the controller and the
/// character profile provider.
class TutorialsHubScreen extends ConsumerWidget {
  const TutorialsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(tutorialControllerProvider);
    final profileAsync = ref.watch(characterProfileProvider);

    // Prefer the live controller value (reflects the latest replay-topic
    // response) but fall back to the server profile while the controller
    // has no state yet.
    final topicsSeen = profileAsync.maybeWhen(
      data: (p) => controller.topicsSeen != 0
          ? controller.topicsSeen
          : p.tutorialTopicsSeen,
      orElse: () => controller.topicsSeen,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: SafeArea(
        child: Column(
          children: [
            _HubHeader(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PlayAllCard(
                      onPlay: () async {
                        await controller.replayAll();
                        if (context.mounted) {
                          Navigator.of(context).maybePop();
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const _SectionLabel('TOPICS'),
                    const SizedBox(height: 10),
                    for (final topic in TutorialTopic.values) ...[
                      _TopicRow(
                        topic: topic,
                        seen: tutorialTopicSeen(topicsSeen, topic),
                        onTap: () => _startTopic(context, controller, topic),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 10),
                    const _HubFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTopic(
    BuildContext context,
    TutorialController controller,
    TutorialTopic topic,
  ) async {
    await controller.startTopic(topic);
    if (context.mounted) {
      Navigator.of(context).maybePop();
    }
  }
}

// ── header ──────────────────────────────────────────────────────────────────
class _HubHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _HubHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back,
                  size: 18, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tutorials',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'REPLAY ANYTIME',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── play all hero ───────────────────────────────────────────────────────────
class _PlayAllCard extends StatelessWidget {
  final VoidCallback onPlay;
  const _PlayAllCard({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blue.withValues(alpha: 0.14),
            AppColors.purple.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: AppColors.blue.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.blue, AppColors.purple],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('\u2728', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Play all (First Quest)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Replay the full walkthrough',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _MetaPill(label: '6 STEPS'),
              SizedBox(width: 8),
              _MetaPill(label: '+0 XP ON REPLAY'),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onPlay,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.blue, Color(0xFF2f7ad8)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'START WALKTHROUGH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  const _MetaPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── topic rows ──────────────────────────────────────────────────────────────
class _TopicRow extends StatelessWidget {
  final TutorialTopic topic;
  final bool seen;
  final VoidCallback onTap;

  const _TopicRow({
    required this.topic,
    required this.seen,
    required this.onTap,
  });

  Color get _accentColor {
    switch (topic) {
      case TutorialTopic.xpStats:
        return AppColors.blue;
      case TutorialTopic.questsStreaks:
        return AppColors.orange;
      case TutorialTopic.activityLogging:
        return AppColors.blue;
      case TutorialTopic.worldMap:
        return AppColors.green;
      case TutorialTopic.bossSystem:
        return AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border.all(
                  color: _accentColor.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  topic.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    seen ? 'COMPLETED' : 'NOT YET SEEN',
                    style: TextStyle(
                      color: seen ? AppColors.green : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            _StatusDot(seen: seen),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool seen;
  const _StatusDot({required this.seen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: seen
            ? AppColors.green.withValues(alpha: 0.15)
            : AppColors.surfaceElevated,
        border: Border.all(
          color: seen
              ? AppColors.green.withValues(alpha: 0.4)
              : AppColors.border,
          style: seen ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          seen ? '\u2713' : '\u25CB',
          style: TextStyle(
            color: seen ? AppColors.green : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HubFooter extends StatelessWidget {
  const _HubFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: AppColors.border,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Replays award no XP. First completion rewards are one-shot per account.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          height: 1.55,
        ),
      ),
    );
  }
}
