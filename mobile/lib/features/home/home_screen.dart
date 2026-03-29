import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../character/providers/character_provider.dart';
import 'home_cards.dart';
import 'home_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(characterProfileProvider).valueOrNull;

    return Stack(
      children: [
        Container(
          color: kHBgBase,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(profile: profile),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeXpCard(profile: profile),
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
