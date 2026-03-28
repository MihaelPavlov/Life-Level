import '../../core/api/api_client.dart';
import 'models/character_class.dart';
import 'models/character_profile.dart';
import 'models/character_setup_result.dart';
import 'models/xp_history_entry.dart';

class CharacterService {
  final _dio = ApiClient.instance;

  Future<List<CharacterClass>> getClasses() async {
    final res = await _dio.get('/classes');
    return (res.data as List<dynamic>)
        .map((e) => CharacterClass.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CharacterSetupResult> setupCharacter({
    required String classId,
    required String avatarEmoji,
  }) async {
    final res = await _dio.post('/character/setup', data: {
      'classId': classId,
      'avatarEmoji': avatarEmoji,
    });
    return CharacterSetupResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CharacterProfile> getProfile() async {
    final res = await _dio.get('/character/me');
    return CharacterProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<XpHistoryEntry>> getXpHistory() async {
    final response = await _dio.get('/character/xp-history');
    final list = response.data as List<dynamic>;
    return list.map((e) => XpHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> spendStatPoint(String stat) async {
    await _dio.post('/character/spend-stat', data: {'stat': stat});
  }
}
