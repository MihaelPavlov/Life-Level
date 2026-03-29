import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import 'providers/quest_provider.dart';
import 'widgets/quest_card.dart';

// ── Surface / palette constants ────────────────────────────────────────────────
const _kBg       = Color(0xFF040810);
const _kSurface  = Color(0xFF161b22);
const _kSurface2 = Color(0xFF1e2632);
const _kBorder   = Color(0xFF30363d);

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => QuestsScreenState();
}

class QuestsScreenState extends ConsumerState<QuestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Called by MainShell when switching back to the Quests tab.
  void refresh() {
    ref.read(dailyQuestsProvider.notifier).refresh();
    ref.read(weeklyQuestsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const Text(
                    'Quests',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: refresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    tooltip: 'Refresh quests',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // ── Daily bonus banner ───────────────────────────────────────────
            const _DailyBonusBanner(),

            // ── Tab bar ──────────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Daily'),
                  Tab(text: 'Weekly'),
                  Tab(text: 'Special'),
                ],
              ),
            ),

            // ── Tab views ────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _DailyQuestsTab(),
                  _WeeklyQuestsTab(),
                  _SpecialQuestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Daily Bonus Banner ─────────────────────────────────────────────────────────
class _DailyBonusBanner extends ConsumerWidget {
  const _DailyBonusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailyQuestsProvider);
    final completed = dailyAsync.valueOrNull
            ?.where((q) => q.isCompleted)
            .length ??
        0;
    final total = dailyAsync.valueOrNull?.length ?? 5;
    final allDone = total > 0 && completed >= total;

    if (allDone) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.green.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'All Daily Quests Complete!',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '+300 XP Earned',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completed / $total Daily Quests Complete',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                _SegmentedBar(filled: completed, total: total),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Bonus',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                '+300 XP',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  final int filled;
  final int total;

  const _SegmentedBar({required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    final count = total > 0 ? total : 5;
    return Row(
      children: List.generate(count, (i) {
        final isDone = i < filled;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < count - 1 ? 3 : 0),
            decoration: BoxDecoration(
              color: isDone ? AppColors.blue : _kSurface2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ── Daily Quests Tab ───────────────────────────────────────────────────────────
class _DailyQuestsTab extends ConsumerWidget {
  const _DailyQuestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(dailyQuestsProvider);
    return questsAsync.when(
      loading: () => const _LoadingShimmer(),
      error: (e, _) => _ErrorState(
        message: 'Failed to load daily quests',
        onRetry: () => ref.read(dailyQuestsProvider.notifier).refresh(),
      ),
      data: (quests) => quests.isEmpty
          ? const _EmptyQuestsPlaceholder('Daily quests will refresh at midnight')
          : RefreshIndicator(
              color: AppColors.blue,
              backgroundColor: _kSurface,
              onRefresh: () => ref.read(dailyQuestsProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: quests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => QuestCard(quest: quests[i]),
              ),
            ),
    );
  }
}

// ── Weekly Quests Tab ──────────────────────────────────────────────────────────
class _WeeklyQuestsTab extends ConsumerWidget {
  const _WeeklyQuestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(weeklyQuestsProvider);
    return questsAsync.when(
      loading: () => const _LoadingShimmer(),
      error: (e, _) => _ErrorState(
        message: 'Failed to load weekly quests',
        onRetry: () => ref.read(weeklyQuestsProvider.notifier).refresh(),
      ),
      data: (quests) => quests.isEmpty
          ? const _EmptyQuestsPlaceholder('Weekly quests reset every Monday')
          : RefreshIndicator(
              color: AppColors.blue,
              backgroundColor: _kSurface,
              onRefresh: () => ref.read(weeklyQuestsProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: quests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => QuestCard(quest: quests[i]),
              ),
            ),
    );
  }
}

// ── Special Quests Tab ─────────────────────────────────────────────────────────
class _SpecialQuestsTab extends ConsumerWidget {
  const _SpecialQuestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questsAsync = ref.watch(specialQuestsProvider);
    return questsAsync.when(
      loading: () => const _LoadingShimmer(),
      error: (e, _) => _ErrorState(
        message: 'Failed to load special quests',
        onRetry: () => ref.invalidate(specialQuestsProvider),
      ),
      data: (quests) => quests.isEmpty
          ? const _EmptyQuestsPlaceholder(
              'Special quests unlock as you level up and explore new zones')
          : RefreshIndicator(
              color: AppColors.blue,
              backgroundColor: _kSurface,
              onRefresh: () async => ref.invalidate(specialQuestsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: quests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => QuestCard(quest: quests[i]),
              ),
            ),
    );
  }
}

// ── Loading shimmer ────────────────────────────────────────────────────────────
class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.4 + _anim.value * 0.3;
        return Container(
          height: 90,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kSurface.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder.withValues(alpha: opacity)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _kSurface2.withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: _kSurface2.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 56,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _kSurface2.withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _kSurface2.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _kSurface2.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyQuestsPlaceholder extends StatelessWidget {
  final String message;

  const _EmptyQuestsPlaceholder(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📜', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'No Quests Available',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Try Again',
                style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
