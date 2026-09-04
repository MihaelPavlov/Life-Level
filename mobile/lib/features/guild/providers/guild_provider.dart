import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guild_models.dart';
import '../services/guild_service.dart';

final guildServiceProvider = Provider<GuildService>((ref) => GuildService());

class GuildNotifier extends AsyncNotifier<GuildDetail?> {
  @override
  Future<GuildDetail?> build() => ref.watch(guildServiceProvider).mine();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(guildServiceProvider).mine());
  }

  Future<void> create(String name, String description, String icon) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(guildServiceProvider).create(
            name: name,
            description: description,
            icon: icon,
          ),
    );
  }

  Future<void> updateGuild(String name, String description, String icon) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(guildServiceProvider).update(
            name: name,
            description: description,
            icon: icon,
          ),
    );
  }

  Future<void> join(String guildId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(guildServiceProvider).join(guildId));
  }

  Future<void> leave() async {
    state = await AsyncValue.guard(() async {
      await ref.read(guildServiceProvider).leave();
      return null;
    });
  }

  Future<void> delete() async {
    state = await AsyncValue.guard(() async {
      await ref.read(guildServiceProvider).delete();
      return null;
    });
  }

  Future<void> kick(String guildId, String userId) async {
    state = await AsyncValue.guard(() async {
      await ref.read(guildServiceProvider).kick(guildId, userId);
      return ref.read(guildServiceProvider).mine();
    });
  }

  Future<void> updateMemberRole(
    String guildId,
    String userId,
    String role,
  ) async {
    state = await AsyncValue.guard(
      () => ref.read(guildServiceProvider).updateMemberRole(
            guildId,
            userId,
            role,
          ),
    );
  }

  Future<void> startRaid(String bossId) async {
    state = await AsyncValue.guard(() async {
      await ref.read(guildServiceProvider).startRaid(bossId);
      return ref.read(guildServiceProvider).mine();
    });
  }
}

final guildProvider = AsyncNotifierProvider<GuildNotifier, GuildDetail?>(
  GuildNotifier.new,
);

final guildRaidBossesProvider = FutureProvider<List<GuildRaidBoss>>(
  (ref) => ref.watch(guildServiceProvider).raidBosses(),
);

final guildRaidHistoryProvider = FutureProvider.autoDispose<List<GuildRaid>>(
  (ref) => ref.watch(guildServiceProvider).raidHistory(),
);

final guildSearchProvider = FutureProvider.autoDispose
    .family<List<GuildSearchItem>, String>(
  (ref, query) => ref.watch(guildServiceProvider).search(query),
);
