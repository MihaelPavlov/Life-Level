import '../../core/api/api_client.dart';
import 'models/quest_models.dart';

class QuestService {
  final _dio = ApiClient.instance;

  Future<List<UserQuestProgress>> getDailyQuests() async {
    final res = await _dio.get('/quests/daily');
    return (res.data as List<dynamic>)
        .map((j) => UserQuestProgress.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserQuestProgress>> getWeeklyQuests() async {
    final res = await _dio.get('/quests/weekly');
    return (res.data as List<dynamic>)
        .map((j) => UserQuestProgress.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserQuestProgress>> getSpecialQuests() async {
    final res = await _dio.get('/quests/special');
    return (res.data as List<dynamic>)
        .map((j) => UserQuestProgress.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
