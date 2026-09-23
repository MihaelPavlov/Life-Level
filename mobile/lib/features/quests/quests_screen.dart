import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import 'providers/quest_provider.dart';
import 'tabs/daily_quests_tab.dart';
import 'tabs/weekly_quests_tab.dart';
import 'tabs/special_quests_tab.dart';
import 'widgets/daily_bonus_banner.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  const QuestsScreen({super.key, this.onClose});

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        onPressed:
                            widget.onClose ?? () => Navigator.of(context).pop(),
                      ),
                    ),
                    const Text(
                      'Quests',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: refresh,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        tooltip: 'Refresh quests',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Daily bonus banner ───────────────────────────────────────────
            const DailyBonusBanner(),

            // ── Tab bar ──────────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
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
                  DailyQuestsTab(),
                  WeeklyQuestsTab(),
                  SpecialQuestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
