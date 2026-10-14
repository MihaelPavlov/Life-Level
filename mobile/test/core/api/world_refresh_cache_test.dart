import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/core/api/api_client.dart';
import 'package:life_level/core/services/world_zone_refresh_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _cacheKey(String path) =>
    'lifelevel.response_cache.v1.anonymous.${base64Url.encode(utf8.encode('$path?'))}';

String _cached(String area) => jsonEncode({
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'data': {'value': 'old'},
      'changedArea': area,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      _cacheKey('/world/full'): _cached('world'),
      _cacheKey('/map/world'): _cached('world'),
      _cacheKey('/boss'): _cached('bosses'),
    });
  });

  test('world refresh clears persistent map snapshots before listeners reload',
      () async {
    final signaled = WorldZoneRefreshNotifier.stream.first;
    WorldZoneRefreshNotifier.notify();
    await signaled.timeout(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(_cacheKey('/world/full')), isFalse);
    expect(prefs.containsKey(_cacheKey('/map/world')), isFalse);
    expect(prefs.containsKey(_cacheKey('/boss')), isTrue);
  });

  test('several local hints coalesce into one world refresh', () async {
    var signals = 0;
    final sub = WorldZoneRefreshNotifier.stream.listen((_) => signals++);
    WorldZoneRefreshNotifier.notify();
    WorldZoneRefreshNotifier.notify();
    WorldZoneRefreshNotifier.notify();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(signals, 1);
    await sub.cancel();
  });

  test('an older GET cannot restore a snapshot after invalidation', () async {
    final started = Completer<void>();
    final releaseOld = Completer<void>();
    var calls = 0;
    final interceptor =
        InterceptorsWrapper(onRequest: (options, handler) async {
      if (options.path != '/world/full') {
        handler.next(options);
        return;
      }
      calls++;
      if (calls == 1) {
        started.complete();
        await releaseOld.future;
      }
      handler.resolve(Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: {'value': calls == 1 ? 'old' : 'fresh'},
      ));
    });
    final previousSetting = ApiClient.persistentCacheEnabled;
    ApiClient.persistentCacheEnabled = true;
    ApiClient.instance.interceptors.insert(0, interceptor);
    try {
      await ApiClient.invalidateCacheAreas(const ['world']);
      final pending = ApiClient.cachedGet('/world/full', changedArea: 'world');
      await started.future.timeout(const Duration(seconds: 2));
      await ApiClient.invalidateCacheAreas(const ['world']);
      releaseOld.complete();

      final response = await pending.timeout(const Duration(seconds: 2));
      expect(response.data, {'value': 'fresh'});
      expect(calls, 2);
      final prefs = await SharedPreferences.getInstance();
      final saved = jsonDecode(prefs.getString(_cacheKey('/world/full'))!)
          as Map<String, dynamic>;
      expect(saved['data'], {'value': 'fresh'});
    } finally {
      ApiClient.instance.interceptors.remove(interceptor);
      ApiClient.persistentCacheEnabled = previousSetting;
      if (!releaseOld.isCompleted) releaseOld.complete();
    }
  });
}
