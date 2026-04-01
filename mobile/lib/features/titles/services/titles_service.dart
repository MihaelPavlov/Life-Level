import '../../../core/api/api_client.dart';
import '../models/title_models.dart';

class TitlesService {
  final _dio = ApiClient.instance;

  Future<TitlesAndRanksResponse> getTitlesAndRanks() async {
    final res = await _dio.get('/titles');
    return TitlesAndRanksResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TitleDto> equipTitle(String titleId) async {
    final res = await _dio.post(
      '/titles/equip',
      data: {'titleId': titleId},
    );
    return TitleDto.fromJson(res.data as Map<String, dynamic>);
  }
}
