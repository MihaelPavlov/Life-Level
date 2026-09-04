import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../activity/models/activity_models.dart';
import '../models/guild_models.dart';

class GuildService {
  Future<GuildDetail?> mine() async {
    final response = await ApiClient.instance.get('/guild/mine');
    final data = _decode(response.data);
    if (data == null || data == 'null' || data == '') return null;
    if (data is! Map<String, dynamic>) {
      throw StateError('Unexpected guild response: ${data.runtimeType}');
    }
    return GuildDetail.fromJson(data);
  }

  Future<GuildDetail> create({
    required String name,
    required String description,
    required String icon,
  }) async {
    final response = await ApiClient.instance.post('/guild', data: {
      'name': name,
      'description': description,
      'icon': icon,
    });
    return GuildDetail.fromJson(_map(response.data));
  }

  Future<GuildDetail> update({
    required String name,
    required String description,
    required String icon,
  }) async {
    final response = await ApiClient.instance.put('/guild', data: {
      'name': name,
      'description': description,
      'icon': icon,
    });
    return GuildDetail.fromJson(_map(response.data));
  }

  Future<List<GuildSearchItem>> search(String query) async {
    final response = await ApiClient.instance.get(
      '/guild/search',
      queryParameters: {'q': query, 'take': 20},
    );
    final list = (_decode(response.data) as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(GuildSearchItem.fromJson)
        .toList();
  }

  Future<GuildDetail> join(String guildId) async {
    final response = await ApiClient.instance.post('/guild/$guildId/join');
    return GuildDetail.fromJson(_map(response.data));
  }

  Future<void> leave() async {
    await ApiClient.instance.post('/guild/leave');
  }

  Future<void> delete() async {
    await ApiClient.instance.delete('/guild');
  }

  Future<void> kick(String guildId, String userId) async {
    await ApiClient.instance.post('/guild/$guildId/kick/$userId');
  }

  Future<GuildDetail> updateMemberRole(
    String guildId,
    String userId,
    String role,
  ) async {
    final response = await ApiClient.instance.put(
      '/guild/$guildId/members/$userId/role',
      data: {'role': role},
    );
    return GuildDetail.fromJson(_map(response.data));
  }

  Future<List<GuildRaidBoss>> raidBosses() async {
    final response = await ApiClient.instance.get('/guild/raid/bosses');
    final list = (_decode(response.data) as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(GuildRaidBoss.fromJson)
        .toList();
  }

  Future<GuildRaid> startRaid(String bossId) async {
    final response = await ApiClient.instance.post(
      '/guild/raid/start',
      data: {'bossId': bossId},
    );
    return GuildRaid.fromJson(_map(response.data));
  }

  Future<List<GuildRaid>> raidHistory() async {
    final response = await ApiClient.instance.get('/guild/raid/history');
    final list = (_decode(response.data) as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(GuildRaid.fromJson)
        .toList();
  }

  Future<List<GuildRaidVictoryInfo>> pendingRaidVictories() async {
    final response = await ApiClient.instance.get('/guild/raid/victories/pending');
    final list = (_decode(response.data) as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(GuildRaidVictoryInfo.fromJson)
        .toList();
  }

  Future<void> acknowledgeRaidVictory(String guildRaidId) async {
    await ApiClient.instance.post(
      '/guild/raid/victories/ack',
      data: {'guildRaidId': guildRaidId},
    );
  }

  Future<List<GuildRaidExpiredInfo>> pendingRaidExpiries() async {
    final response = await ApiClient.instance.get('/guild/raid/expiries/pending');
    final list = (_decode(response.data) as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(GuildRaidExpiredInfo.fromJson)
        .toList();
  }

  Future<void> acknowledgeRaidExpiry(String guildRaidId) async {
    await ApiClient.instance.post(
      '/guild/raid/expiries/ack',
      data: {'guildRaidId': guildRaidId},
    );
  }

  String messageFor(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) return data['message'];
      if (data is Map && data['error'] is String) return data['error'];
      return error.message ?? 'Request failed';
    }
    return error.toString();
  }

  dynamic _decode(dynamic data) {
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty || trimmed == 'null') return null;
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  Map<String, dynamic> _map(dynamic data) {
    final decoded = _decode(data);
    if (decoded is Map<String, dynamic>) return decoded;
    throw StateError('Unexpected guild response: ${decoded.runtimeType}');
  }
}
