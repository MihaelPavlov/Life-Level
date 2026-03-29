import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../login_reward_service.dart';
import '../models/login_reward_models.dart';

// ── Service provider ───────────────────────────────────────────────────────────
final loginRewardServiceProvider =
    Provider<LoginRewardService>((ref) => LoginRewardService());

// ── Status provider ────────────────────────────────────────────────────────────
final loginRewardStatusProvider =
    FutureProvider.autoDispose<LoginRewardStatus>(
  (ref) => ref.read(loginRewardServiceProvider).getStatus(),
);
