import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guild_models.dart';
import '../services/guild_service.dart';
import '../../../core/services/client_experience_service.dart';

final guildServiceProvider = Provider<GuildService>((ref) => GuildService());

class GuildNotifier extends AsyncNotifier<GuildDetail?> {
  @override
  Future<GuildDetail?> build() => ref.watch(guildServiceProvider).mine();

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    final next =
        await AsyncValue.guard(() => ref.read(guildServiceProvider).mine());
    if (next.hasValue || previous == null) state = next;
  }

  Future<void> create(String name, String description, String icon) async {
    final result = await ref.read(guildServiceProvider).create(
          name: name,
          description: description,
          icon: icon,
        );
    state = AsyncData(result);
  }

  Future<void> updateGuild(String name, String description, String icon) async {
    final previous = state.requireValue!;
    if (!ClientExperienceService.instance.enabled('guild')) {
      state = AsyncData(await ref.read(guildServiceProvider).update(
            name: name,
            description: description,
            icon: icon,
          ));
      return;
    }
    state = AsyncData(
        previous.copyWith(name: name, description: description, icon: icon));
    try {
      state = AsyncData(await ref.read(guildServiceProvider).update(
            name: name,
            description: description,
            icon: icon,
          ));
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> join(String guildId) async {
    final result = await ref.read(guildServiceProvider).join(guildId);
    state = AsyncData(result);
  }

  Future<void> leave() async => _removeGuild(
        () => ref.read(guildServiceProvider).leave(),
      );

  Future<void> delete() async => _removeGuild(
        () => ref.read(guildServiceProvider).delete(),
      );

  Future<void> _removeGuild(Future<void> Function() request) async {
    final previous = state.valueOrNull;
    if (!ClientExperienceService.instance.enabled('guild')) {
      await request();
      state = const AsyncData(null);
      return;
    }
    state = const AsyncData(null);
    try {
      await request();
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> kick(String guildId, String userId) async {
    final previous = state.requireValue!;
    if (!ClientExperienceService.instance.enabled('guild')) {
      await ref.read(guildServiceProvider).kick(guildId, userId);
      await refresh();
      return;
    }
    final members = previous.members
        .where((member) => member.userId != userId)
        .toList(growable: false);
    state = AsyncData(
        previous.copyWith(members: members, memberCount: members.length));
    try {
      await ref.read(guildServiceProvider).kick(guildId, userId);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> updateMemberRole(
    String guildId,
    String userId,
    String role,
  ) async {
    final previous = state.requireValue!;
    if (!ClientExperienceService.instance.enabled('guild')) {
      state = AsyncData(
        await ref.read(guildServiceProvider).updateMemberRole(
              guildId,
              userId,
              role,
            ),
      );
      return;
    }
    state = AsyncData(previous.copyWith(
      members: [
        for (final member in previous.members)
          member.userId == userId ? member.copyWith(role: role) : member,
      ],
    ));
    try {
      state = AsyncData(
        await ref.read(guildServiceProvider).updateMemberRole(
              guildId,
              userId,
              role,
            ),
      );
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> startRaid(String bossId) async {
    final current = state.requireValue!;
    final raid = await ref.read(guildServiceProvider).startRaid(bossId);
    state = AsyncData(current.copyWith(activeRaid: raid));
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

final guildSearchProvider =
    FutureProvider.autoDispose.family<List<GuildSearchItem>, String>(
  (ref, query) => ref.watch(guildServiceProvider).search(query),
);
