import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../character/models/character_profile.dart';
import '../character/providers/character_provider.dart';
import 'profile_stat_metadata.dart';
import 'profile_widgets.dart';
import 'profile_overview_tab.dart';
import 'tabs/equipment_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: kProfileTabs.length, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(characterProfileProvider);
    final profile = profileAsync.valueOrNull;

    // First load — no data yet.
    if (profile == null) {
      if (profileAsync.hasError) {
        return Scaffold(
          backgroundColor: kPBg,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Failed to load profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kPTextPri),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profileAsync.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: kPTextSec),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => ref.read(characterProfileProvider.notifier).refresh(),
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return const Scaffold(
        backgroundColor: kPBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    // Profile is available — show it. Silently refreshes in background.
    return Scaffold(
      backgroundColor: kPBg,
      body: Column(
        children: [
          ProfileHeader(tabController: _tab, profile: profile),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                ProfileOverviewTab(profile: profile),
                const EquipmentTab(),
                const ProfilePlaceholderTab('Inventory', '🎒'),
                const ProfilePlaceholderTab('Achievements', '🏆'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── ProfileHeader ─────────────────────────────────────────────────────────────
class ProfileHeader extends StatelessWidget {
  final TabController tabController;
  final CharacterProfile profile;
  const ProfileHeader({super.key, required this.tabController, required this.profile});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final rankAccent = profileRankColor(profile.rank);
    final titleText = '${profile.classEmoji ?? ''} ${profile.className ?? 'Hero'}'.trim();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF080e14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x104f9eff), Color(0x00040810)],
          stops: [0.0, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: top + 12),

          // ── avatar row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // avatar
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [kPBlue, kPPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPBlue.withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      profile.avatarEmoji ?? '🧙',
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // identity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kPTextPri,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // class badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: kPGold.withOpacity(0.10),
                          border: Border.all(color: kPGold.withOpacity(0.40)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          titleText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kPGold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // rank + level sub-text
                      Row(
                        children: [
                          ProfileRankBadge(rank: profile.rank, color: rankAccent),
                          const SizedBox(width: 8),
                          Text(
                            'Level ${profile.level}',
                            style: const TextStyle(fontSize: 11, color: kPTextSec),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // settings icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kPSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kPBorder2),
                  ),
                  child: const Icon(Icons.settings_outlined, size: 18, color: kPTextSec),
                ),
              ],
            ),
          ),

          // ── tab bar ────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kPBorder)),
            ),
            child: TabBar(
              controller: tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: kPBlue,
              unselectedLabelColor: kPTextSec,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              indicatorColor: kPBlue,
              indicatorWeight: 2,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              tabs: kProfileTabs.map((t) => Tab(text: t, height: 36)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
