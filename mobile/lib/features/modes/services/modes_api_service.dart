import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../burn_chain/burn_chain_rules.dart';
import '../treasure_delve/delve_engine.dart';

class BurnChainApiState {
  final BurnChainState chain;
  final int acknowledgedLinks;
  const BurnChainApiState(this.chain, this.acknowledgedLinks);
}

class DelveApiStatus {
  final int runsEarned;
  final int runsUsed;
  final int runsLeft;
  final DelveStat featured;
  final int bestRun;
  final DateTime resetAtUtc;
  final DelveRun? activeRun;

  const DelveApiStatus({
    required this.runsEarned,
    required this.runsUsed,
    required this.runsLeft,
    required this.featured,
    required this.bestRun,
    required this.resetAtUtc,
    required this.activeRun,
  });

  factory DelveApiStatus.fromJson(Map<String, dynamic> j) => DelveApiStatus(
        runsEarned: (j['runsEarned'] as num?)?.toInt() ?? 0,
        runsUsed: (j['runsUsed'] as num?)?.toInt() ?? 0,
        runsLeft: (j['runsLeft'] as num?)?.toInt() ?? 0,
        featured: _stat(j['featuredStat'] as String?),
        bestRun: (j['bestRun'] as num?)?.toInt() ?? 0,
        resetAtUtc: DateTime.parse(j['resetAtUtc'] as String).toUtc(),
        activeRun: j['activeRun'] is Map<String, dynamic>
            ? _delveRun(j['activeRun'] as Map<String, dynamic>)
            : null,
      );
}

class ModesApiService {
  Future<BurnChainApiState> burnStatus() async {
    final result = _burn(
        (await ApiClient.cachedGet('/modes/burn-chain', changedArea: 'modes'))
            .data);
    await _clearLegacyModeState();
    return result;
  }

  Future<BurnChainApiState> startBurn({String? operationId}) async =>
      _burn((await ApiClient.instance.post('/modes/burn-chain/start',
              options: operationId == null
                  ? null
                  : ApiClient.mutationOptions(operationId)))
          .data);

  Future<BurnChainApiState> collectBurn({String? operationId}) async =>
      _burn((await ApiClient.instance.post('/modes/burn-chain/collect',
              options: operationId == null
                  ? null
                  : ApiClient.mutationOptions(operationId)))
          .data);

  Future<BurnChainApiState> acknowledgeBurn(int count) async =>
      _burn((await ApiClient.instance
              .post('/modes/burn-chain/acknowledge-links/$count'))
          .data);

  Future<DelveApiStatus> delveStatus() async => DelveApiStatus.fromJson(
      (await ApiClient.instance.get('/modes/treasure-delve')).data
          as Map<String, dynamic>);

  Future<DelveRun> startDelve() async => _delveRun(
      (await ApiClient.instance.post('/modes/treasure-delve/runs')).data);

  Future<DelveRun> choose(String runId, DelvePath path) async =>
      _delveRun((await ApiClient.instance.post(
        '/modes/treasure-delve/runs/$runId/choose',
        data: {'path': path.name},
      ))
          .data);

  Future<DelveRun> attempt(String runId) async => _command(runId, 'attempt');
  Future<DelveRun> continueRun(String runId) async =>
      _command(runId, 'continue');
  Future<DelveRun> bank(String runId) async => _command(runId, 'bank');
  Future<DelveRun> acknowledge(String runId) async =>
      _command(runId, 'acknowledge');

  Future<DelveRun> _command(String runId, String command) async =>
      _delveRun((await ApiClient.instance
              .post('/modes/treasure-delve/runs/$runId/$command'))
          .data);

  Future<void> _clearLegacyModeState() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool('modes.serverStateMigrated') == true) return;
    for (final key
        in preferences.getKeys().where((x) => x.startsWith('modes.'))) {
      await preferences.remove(key);
    }
    await preferences.setBool('modes.serverStateMigrated', true);
  }
}

BurnChainApiState _burn(dynamic raw) {
  final j = raw as Map<String, dynamic>;
  final phase = switch (j['phase']) {
    'live' => BurnChainPhase.live,
    'ended' => BurnChainPhase.ended,
    'cooldown' => BurnChainPhase.cooldown,
    _ => BurnChainPhase.idle,
  };
  final links = ((j['links'] as List<dynamic>?) ?? const []).map((raw) {
    final x = raw as Map<String, dynamic>;
    return ChainLink(
      activityId: x['activityId'].toString(),
      type: x['type'] as String? ?? '',
      durationMinutes: (x['durationMinutes'] as num?)?.toInt() ?? 0,
      calories: (x['calories'] as num?)?.toInt() ?? 0,
      loggedAt: DateTime.parse(x['loggedAt'] as String).toUtc(),
      kind: switch (x['kind']) {
        'beat' => ChainLinkKind.beat,
        'breaker' => ChainLinkKind.breaker,
        _ => ChainLinkKind.base,
      },
      barBefore: (x['barBefore'] as num?)?.toInt(),
    );
  }).toList();
  return BurnChainApiState(
    BurnChainState(
      phase: phase,
      startedAt: j['startedAt'] == null
          ? null
          : DateTime.parse(j['startedAt'] as String).toUtc(),
      links: links,
      endReason: switch (j['endReason']) {
        'broken' => BurnChainEndReason.broken,
        'timeUp' => BurnChainEndReason.timeUp,
        _ => null,
      },
      nextStartAt: j['nextStartAt'] == null
          ? null
          : DateTime.parse(j['nextStartAt'] as String).toUtc(),
      talentCrystals: (j['talentCrystals'] as num?)?.toInt() ?? 0,
    ),
    (j['acknowledgedLinks'] as num?)?.toInt() ?? 0,
  );
}

DelveRun _delveRun(dynamic raw) {
  final j = raw as Map<String, dynamic>;
  final options = ((j['options'] as List<dynamic>?) ?? const []).map((raw) {
    final x = raw as Map<String, dynamic>;
    return DelveOption(
      path: _path(x['path'] as String?),
      event: _event(x['event'] as String?),
      coins: (x['coins'] as num?)?.toInt() ?? 0,
      recommended: (x['recommended'] as num?)?.toInt() ?? 0,
      successChance: (x['successChance'] as num?)?.toDouble() ?? 0,
      boosted: x['boosted'] as bool? ?? false,
    );
  }).toList();
  final history = ((j['history'] as List<dynamic>?) ?? const [])
      .cast<Map<String, dynamic>>();
  final successful = history.where((x) => x['succeeded'] == true).toList();
  final last = history.isEmpty ? null : history.last;
  final chosenPath = j['chosenPath'] as String?;
  final end = switch (j['endReason']) {
    'failed' => DelveEnd.failed,
    'cleared' => DelveEnd.cleared,
    'banked' || 'expired' => DelveEnd.banked,
    _ => null,
  };
  return DelveRun(
    id: j['id'].toString(),
    chamber: (j['chamber'] as num?)?.toInt() ?? 0,
    options: options,
    phase: switch (j['phase']) {
      'challenge' => DelvePhase.challenge,
      'decision' => DelvePhase.decision,
      'result' => DelvePhase.result,
      _ => DelvePhase.choosing,
    },
    chosen: chosenPath == null
        ? null
        : options.cast<DelveOption?>().firstWhere(
              (x) => x?.path == _path(chosenPath),
              orElse: () => null,
            ),
    secured: (j['secured'] as num?)?.toInt() ?? 0,
    atRisk: (j['atRisk'] as num?)?.toInt() ?? 0,
    itemsFound: ((j['items'] as List<dynamic>?) ?? const []).length,
    lastSucceeded: last?['succeeded'] as bool?,
    lastCoins: (last?['coins'] as num?)?.toInt() ?? 0,
    lastItem: last?['itemName'] != null,
    cleared: successful.map((x) => _path(x['path'] as String?)).toList(),
    end: end,
  );
}

DelvePath _path(String? value) => switch (value) {
      'treasure' => DelvePath.treasure,
      'cursed' => DelvePath.cursed,
      _ => DelvePath.safe,
    };

DelveEvent _event(String? value) => switch (value) {
      'floodedTunnel' => DelveEvent.floodedTunnel,
      'trapCorridor' => DelveEvent.trapCorridor,
      'crystalPuzzle' => DelveEvent.crystalPuzzle,
      'longPassage' => DelveEvent.longPassage,
      _ => DelveEvent.collapsedGate,
    };

DelveStat _stat(String? value) => switch (value) {
      'end' => DelveStat.end,
      'agi' => DelveStat.agi,
      'flx' => DelveStat.flx,
      'sta' => DelveStat.sta,
      _ => DelveStat.str,
    };

final modesApiServiceProvider =
    Provider<ModesApiService>((_) => ModesApiService());
