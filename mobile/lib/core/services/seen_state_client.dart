import '../api/api_client.dart';

class SeenStateClient {
  final _dio = ApiClient.instance;

  Future<void> markAchievements(Iterable<String> ids) async {
    final values = ids.toSet().toList();
    for (var start = 0; start < values.length; start += 500) {
      await _dio.post('/seen/achievements', data: {
        'ids': values.skip(start).take(500).toList(),
      });
    }
  }

  Future<void> markTitles(Iterable<String> ids) async {
    final values = ids.toSet().toList();
    for (var start = 0; start < values.length; start += 500) {
      await _dio.post('/seen/titles', data: {
        'ids': values.skip(start).take(500).toList(),
      });
    }
  }

  Future<Map<String, DateTime>> bossCursors() async {
    final response = await _dio.get('/seen/bosses');
    final rows = response.data as List<dynamic>;
    final result = <String, DateTime>{};
    for (final raw in rows) {
      final row = raw as Map<String, dynamic>;
      final time = DateTime.tryParse('${row['lastSeenTurnAt']}');
      if (time != null) result['${row['bossId']}'] = time;
    }
    return result;
  }

  Future<void> markBossTurn(String bossId, String turnId) async {
    await _dio.post('/seen/bosses/$bossId', data: {'turnId': turnId});
  }
}
