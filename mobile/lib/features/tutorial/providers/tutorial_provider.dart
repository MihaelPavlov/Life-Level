import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tutorial_controller.dart';

/// App-wide singleton [TutorialController]. Kept as a regular `Provider`
/// (not autoDispose) so the tutorial state survives tab switches and the
/// transient rebuild of the settings sheet while a replay is mid-flight.
///
/// `MainShell` watches this in its listener to show the overlay; the
/// profile settings sheet and the hub both call `ref.read(...).startTopic`
/// / `.replayAll()` to kick things off.
final tutorialControllerProvider = Provider<TutorialController>((ref) {
  final controller = TutorialController();
  ref.onDispose(controller.dispose);
  return controller;
});
