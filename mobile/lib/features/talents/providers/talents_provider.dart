import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/talent_models.dart';
import '../services/talents_service.dart';

final talentsServiceProvider =
    Provider<TalentsService>((ref) => TalentsService());

class TalentsNotifier extends AsyncNotifier<TalentScreen> {
  @override
  Future<TalentScreen> build() => ref.watch(talentsServiceProvider).getScreen();

  // Deliberately does NOT invalidate/refresh here — the draw's on-screen
  // reveal (border sweep landing, then the popped-card flip) needs the grid
  // to keep showing pre-draw data until it actually lands, otherwise the
  // unlocked/leveled talent would flash into view early and spoil the
  // reveal. The caller (TalentsScreen) invalidates this provider itself,
  // once the sweep has landed.
  Future<TalentDrawResult> draw() async {
    return ref.read(talentsServiceProvider).draw();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(talentsServiceProvider).getScreen(),
    );
  }
}

final talentsProvider =
    AsyncNotifierProvider<TalentsNotifier, TalentScreen>(TalentsNotifier.new);
