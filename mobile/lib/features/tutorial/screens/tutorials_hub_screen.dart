import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/services/nav_tab_notifier.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../../character/providers/character_provider.dart';
import '../models/tutorial_step.dart';
import '../providers/tutorial_provider.dart';

class TutorialsHubScreen extends ConsumerStatefulWidget {
  const TutorialsHubScreen({super.key});

  @override
  ConsumerState<TutorialsHubScreen> createState() => _TutorialsHubScreenState();
}

class _TutorialsHubScreenState extends ConsumerState<TutorialsHubScreen> {
  _TutorialCatalogItem? _selected;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(tutorialControllerProvider);
    final profile = ref.watch(characterProfileProvider).valueOrNull;

    final tutorials = <_TutorialCatalogItem>[
      _TutorialCatalogItem(
        id: 'first-quest',
        title: 'First Quest',
        subtitle: 'Core app basics and first progression loop',
        iconAsset: AppIcons.questFirst,
        accent: AppColors.blue,
        rewardLabel: '+500 XP · Novice Adventurer',
        stepLabel: '6 steps',
        completed: (profile?.tutorialStep ?? 0) >= 99,
        inProgress: ((profile?.tutorialStep ?? 0) > 0 &&
            (profile?.tutorialStep ?? 0) < 99),
        steps: const [
          TutorialStep.logActivity,
          TutorialStep.xpBar,
          TutorialStep.stats,
          TutorialStep.quests,
          TutorialStep.mapTab,
          TutorialStep.bossFab,
        ],
        onStart: () async {
          if (context.mounted) Navigator.of(context).maybePop();
          await controller.replayAll();
        },
      ),
      _TutorialCatalogItem(
        id: 'map-tutorial',
        title: 'Map Tutorial',
        subtitle: 'World, regions, zones, and zone types',
        iconAsset: AppIcons.mapDestination,
        accent: AppColors.green,
        rewardLabel: 'World Guide Reward',
        stepLabel: '8 steps',
        completed: (profile?.mapTutorialStep ?? 0) >= 99,
        inProgress: ((profile?.mapTutorialStep ?? 0) > 0 &&
            (profile?.mapTutorialStep ?? 0) < 99),
        steps: const [
          TutorialStep.mapWorldBack,
          TutorialStep.mapRegions,
          TutorialStep.mapZoneTrail,
          TutorialStep.mapNormalZone,
          TutorialStep.mapChestZone,
          TutorialStep.mapSpecialZone,
          TutorialStep.mapDungeonZone,
          TutorialStep.mapBossZone,
        ],
        onStart: () async {
          if (context.mounted) Navigator.of(context).maybePop();
          await controller.replayMapTutorial();
          NavTabNotifier.switchTo('world');
        },
      ),
    ];

    final selected = _selected;

    return Scaffold(
      backgroundColor: AppColors.backgroundAlt,
      body: SafeArea(
        child: Column(
          children: [
            _HubHeader(
              title: selected?.title ?? 'Tutorials',
              subtitle: selected == null
                  ? 'REPLAY ANYTIME'
                  : 'STEPS AND REWARD',
              onBack: () {
                if (selected != null) {
                  setState(() => _selected = null);
                  return;
                }
                Navigator.of(context).maybePop();
              },
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selected == null
                    ? _TutorialListView(
                        tutorials: tutorials,
                        onOpen: (item) => setState(() => _selected = item),
                      )
                    : _TutorialDetailView(item: selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialCatalogItem {
  final String id;
  final String title;
  final String subtitle;
  final String iconAsset;
  final Color accent;
  final String rewardLabel;
  final String stepLabel;
  final bool completed;
  final bool inProgress;
  final List<TutorialStep> steps;
  final Future<void> Function() onStart;

  const _TutorialCatalogItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.accent,
    required this.rewardLabel,
    required this.stepLabel,
    required this.completed,
    required this.inProgress,
    required this.steps,
    required this.onStart,
  });
}

class _HubHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _HubHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

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
              child: const Icon(
                Icons.arrow_back,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
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

class _TutorialListView extends StatelessWidget {
  final List<_TutorialCatalogItem> tutorials;
  final ValueChanged<_TutorialCatalogItem> onOpen;

  const _TutorialListView({
    required this.tutorials,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('tutorial-list'),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('TUTORIALS'),
          const SizedBox(height: 10),
          for (final tutorial in tutorials) ...[
            _TutorialCard(
              item: tutorial,
              onTap: () => onOpen(tutorial),
            ),
            const SizedBox(height: 10),
          ],
          const _HubFooter(
            text:
                'Open any tutorial to review its reward and step list before starting.',
          ),
        ],
      ),
    );
  }
}

class _TutorialDetailView extends StatelessWidget {
  final _TutorialCatalogItem item;

  const _TutorialDetailView({required this.item});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: ValueKey(item.id),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TutorialHero(item: item),
          const SizedBox(height: 14),
          const _SectionLabel('STEPS'),
          const SizedBox(height: 10),
          for (int i = 0; i < item.steps.length; i++) ...[
            _TutorialStepRow(
              index: i + 1,
              total: item.steps.length,
              step: item.steps[i],
              accent: item.accent,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: item.onStart,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [item.accent, item.accent.withValues(alpha: 0.78)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: item.accent.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                item.completed ? 'REPLAY TUTORIAL' : 'START TUTORIAL',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final _TutorialCatalogItem item;
  final VoidCallback onTap;

  const _TutorialCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = item.completed
        ? 'COMPLETED'
        : item.inProgress
            ? 'IN PROGRESS'
            : 'NOT STARTED';
    final statusColor = item.completed
        ? AppColors.green
        : item.inProgress
            ? item.accent
            : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.accent.withValues(alpha: 0.12),
              AppColors.surface,
            ],
          ),
          border: Border.all(color: item.accent.withValues(alpha: 0.28)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(
                      color: item.accent.withValues(alpha: 0.35),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: AppIconImage(
                      item.iconAsset,
                      size: 24,
                      visualScale: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaPill(
                  label: item.stepLabel.toUpperCase(),
                  color: item.accent,
                ),
                _MetaPill(
                  label: item.rewardLabel.toUpperCase(),
                  color: AppColors.orange,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialHero extends StatelessWidget {
  final _TutorialCatalogItem item;

  const _TutorialHero({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.accent.withValues(alpha: 0.18),
            AppColors.surface,
          ],
        ),
        border: Border.all(color: item.accent.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: Border.all(color: item.accent.withValues(alpha: 0.36)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: AppIconImage(
                    item.iconAsset,
                    size: 28,
                    visualScale: 1.6,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RewardPanel(item: item),
        ],
      ),
    );
  }
}

class _RewardPanel extends StatelessWidget {
  final _TutorialCatalogItem item;

  const _RewardPanel({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.orange.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: AppIconImage(
                AppIcons.rewardXpSparkle,
                size: 18,
                visualScale: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reward',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.rewardLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.stepLabel.toUpperCase(),
            style: TextStyle(
              color: item.accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialStepRow extends StatelessWidget {
  final int index;
  final int total;
  final TutorialStep step;
  final Color accent;

  const _TutorialStepRow({
    required this.index,
    required this.total,
    required this.step,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final content = kTutorialStepContent[step];
    final title = content?.title ?? step.name;
    final body = content?.body ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$index/$total',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.55,
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

class _HubFooter extends StatelessWidget {
  final String text;
  const _HubFooter({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          height: 1.55,
        ),
      ),
    );
  }
}
