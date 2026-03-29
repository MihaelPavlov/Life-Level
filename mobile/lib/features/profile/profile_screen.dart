import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../character/character_service.dart';
import '../character/models/character_profile.dart';
import 'profile_stat_metadata.dart';
import 'profile_widgets.dart';
import 'profile_overview_tab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileScreen
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  CharacterProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: kProfileTabs.length, vsync: this);
    _tab.addListener(() => setState(() {}));
    _loadProfile();
  }

  Future<void> refresh() => _loadProfile();

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final profile = await CharacterService().getProfile();
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kPBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    if (_error != null) {
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
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: kPTextSec),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _loadProfile,
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

    final profile = _profile!;

    return Scaffold(
      backgroundColor: kPBg,
      body: Column(
        children: [
          ProfileHeader(tabController: _tab, profile: profile),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                ProfileOverviewTab(profile: profile, onStatSpent: _loadProfile),
                const ProfilePlaceholderTab('Equipment', '🛡️'),
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
