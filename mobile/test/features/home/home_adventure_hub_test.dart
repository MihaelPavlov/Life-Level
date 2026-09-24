import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/home/cards/home_adventure_hub.dart';
import 'package:life_level/features/home/providers/adventure_hub_status_provider.dart';

final _rewardsReadyProvider = StateProvider<bool>((ref) => false);

void main() {
  testWidgets('shows a live Rewards alert when claimable state changes',
      (tester) async {
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adventureHubSignalsProvider.overrideWith((ref) async {
            final rewardsReady = ref.watch(_rewardsReadyProvider);
            return AdventureHubSignals(
              rewards: rewardsReady,
              streak: false,
              talents: false,
              season: false,
              titles: false,
              achievements: false,
            );
          }),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return const MaterialApp(
              home: Scaffold(body: HomeAdventureHub()),
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('!'), findsNothing);

    container.read(_rewardsReadyProvider.notifier).state = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('!'), findsOneWidget);
  });
}
