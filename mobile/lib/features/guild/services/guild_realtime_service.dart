import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../../../core/api/api_client.dart';
import '../../../core/services/state_change_notifier.dart';
import '../../activity/models/activity_models.dart';
import '../models/guild_models.dart';

class GuildRealtimeService {
  HubConnection? _connection;
  bool _starting = false;
  bool _stopped = false;
  Timer? _retry;
  int _retryAttempt = 0;

  Future<void> start({
    required void Function(GuildRaidStartedInfo info) onStarted,
    required void Function(GuildRaidHpUpdatedInfo info) onHpUpdated,
    required void Function(GuildRaidVictoryInfo info) onDefeated,
    required void Function(GuildRaidExpiredInfo info) onExpired,
    required void Function() onReconnected,
  }) async {
    _stopped = false;
    if (_starting) return;
    final current = _connection;
    if (current?.state == HubConnectionState.Connected ||
        current?.state == HubConnectionState.Connecting) {
      return;
    }

    final token = await ApiClient.getToken();
    if (token == null || token.isEmpty) return;

    _starting = true;
    try {
      final connection = HubConnectionBuilder()
          .withUrl(
            '${ApiClient.realtimeBaseUrl}/hubs/guild-raid',
            options: HttpConnectionOptions(
              accessTokenFactory: () async => await ApiClient.getToken() ?? '',
              transport: HttpTransportType.WebSockets,
              skipNegotiation: true,
            ),
          )
          .withAutomaticReconnect()
          .build();

      connection.on('RaidStarted', (args) {
        final json = _firstMap(args);
        if (json != null) onStarted(GuildRaidStartedInfo.fromJson(json));
      });
      connection.on('RaidHpUpdated', (args) {
        final json = _firstMap(args);
        if (json != null) onHpUpdated(GuildRaidHpUpdatedInfo.fromJson(json));
      });
      connection.on('RaidDefeated', (args) {
        final json = _firstMap(args);
        if (json != null) onDefeated(GuildRaidVictoryInfo.fromJson(json));
      });
      connection.on('RaidExpired', (args) {
        final json = _firstMap(args);
        if (json != null) onExpired(GuildRaidExpiredInfo.fromJson(json));
      });
      connection.on('StateChanged', (args) {
        final json = _firstMap(args);
        final areas = json?['areas'];
        if (areas is List) StateChangeNotifier.notify(areas.map((e) => '$e'));
      });
      connection.onreconnected(({connectionId}) async {
        _retryAttempt = 0;
        try {
          await connection.invoke('JoinCurrentGuild');
        } catch (_) {}
        onReconnected();
      });
      connection.onclose(({error}) {
        _scheduleRetry(onStarted: onStarted, onHpUpdated: onHpUpdated,
            onDefeated: onDefeated, onExpired: onExpired,
            onReconnected: onReconnected);
      });

      _connection = connection;
      await connection.start();
      _retryAttempt = 0;
    } catch (_) {
      final failed = _connection;
      _connection = null;
      try { await failed?.stop(); } catch (_) {}
      _scheduleRetry(onStarted: onStarted, onHpUpdated: onHpUpdated,
          onDefeated: onDefeated, onExpired: onExpired,
          onReconnected: onReconnected);
    } finally {
      _starting = false;
    }
  }

  void _scheduleRetry({
    required void Function(GuildRaidStartedInfo info) onStarted,
    required void Function(GuildRaidHpUpdatedInfo info) onHpUpdated,
    required void Function(GuildRaidVictoryInfo info) onDefeated,
    required void Function(GuildRaidExpiredInfo info) onExpired,
    required void Function() onReconnected,
  }) {
    if (_stopped) return;
    _retry?.cancel();
    final seconds = 1 << (_retryAttempt > 6 ? 6 : _retryAttempt);
    if (_retryAttempt < 6) _retryAttempt++;
    _retry = Timer(Duration(seconds: seconds), () {
      if (!_stopped) {
        start(onStarted: onStarted, onHpUpdated: onHpUpdated,
            onDefeated: onDefeated, onExpired: onExpired,
            onReconnected: onReconnected);
      }
    });
  }

  Future<void> stop() async {
    _stopped = true;
    _retry?.cancel();
    final connection = _connection;
    _connection = null;
    if (connection == null) return;
    try {
      await connection.stop();
    } catch (_) {
      // Non-critical: reconnect attempts will create a fresh connection.
    }
  }

  Future<void> refreshGuildGroup() async {
    final connection = _connection;
    if (connection?.state != HubConnectionState.Connected) return;
    try {
      await connection!.invoke('JoinCurrentGuild');
    } catch (_) {
      // Non-critical. The next reconnect or startup refresh will join again.
    }
  }

  Map<String, dynamic>? _firstMap(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    return _asStringMap(args.first);
  }

  Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }
}
