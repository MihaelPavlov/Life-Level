import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';

class MapTutorialLocalStore {
  static const _prefix = 'map_tutorial_terminal_step';

  Future<int?> readTerminalStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(await _key());
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTerminalStep(int step) async {
    if (step != -1 && step < 99) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(await _key(), step);
    } catch (_) {
      // Server persistence remains the primary path; local storage is fallback.
    }
  }

  Future<void> clearTerminalStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(await _key());
    } catch (_) {
      // Replay should still proceed if local fallback storage is unavailable.
    }
  }

  Future<String> _key() async {
    final token = await ApiClient.getToken();
    final userKey = _userKeyFromToken(token) ?? 'anonymous';
    return '$_prefix:$userKey';
  }

  String? _userKeyFromToken(String? token) {
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final claims = jsonDecode(utf8.decode(base64Decode(payload)))
          as Map<String, dynamic>;
      final id = claims['sub'] ??
          claims['nameid'] ??
          claims[
              'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
      return id?.toString();
    } catch (_) {
      return null;
    }
  }
}
