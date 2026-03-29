import 'package:flutter/material.dart';
import '../../core/services/level_up_notifier.dart';
import '../character/character_service.dart';
import '../character/models/character_profile.dart';
import 'home_cards.dart';
import 'home_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  CharacterProfile? _profile;

  final _characterService = CharacterService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Called by MainShell when the home tab is selected.
  Future<void> refresh() async {
    final oldLevel = _profile?.level;
    await _loadProfile();
    if (mounted && _profile != null && oldLevel != null && _profile!.level > oldLevel) {
      LevelUpNotifier.notify(_profile!.level);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _characterService.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: kHBgBase,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(profile: _profile),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeXpCard(profile: _profile),
                      const HomeStreakCard(),
                      const HomeQuestsCard(),
                      const HomeLastActivityCard(),
                      const HomeStatsRow(),
                      const HomeBossCard(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
