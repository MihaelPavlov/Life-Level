import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/character/models/character_profile.dart';
import 'package:life_level/features/character/providers/character_provider.dart';
import 'package:life_level/features/home/providers/world_progress_provider.dart';
import 'package:life_level/features/map/models/world_map_models.dart';
import 'package:life_level/features/map/providers/world_zone_service_provider.dart';
import 'package:life_level/features/map/screens/region_detail_screen.dart';
import 'package:life_level/features/map/services/world_zone_service.dart';

class _PendingCharacter extends CharacterNotifier {
  @override
  Future<CharacterProfile> build() => Completer<CharacterProfile>().future;
}

class _RegionService extends WorldZoneService {
  _RegionService({this.failRegion = false});
  final bool failRegion;

  @override
  Future<RegionDetail> getRegionDetail(String regionId) async {
    if (failRegion) {
      throw DioException(
        requestOptions: RequestOptions(path: '/map/region/$regionId'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/map/region/$regionId'),
          statusCode: 404,
        ),
      );
    }
    return RegionDetail.fromJson({
      'id': regionId,
      'name': 'Forest of Endurance',
      'emoji': '🌲',
      'theme': 'forest',
      'status': 'active',
      'nodes': <Map<String, dynamic>>[],
      'edges': <Map<String, dynamic>>[],
    });
  }

  @override
  Future<WorldMapData> getWorldMap() async => throw DioException(
        requestOptions: RequestOptions(path: '/map/world'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/map/world'),
          statusCode: 404,
        ),
      );
}

void main() {
  testWidgets('a failed overview does not hide a loaded region',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        worldZoneServiceProvider.overrideWithValue(_RegionService()),
        characterProfileProvider.overrideWith(_PendingCharacter.new),
      ],
      child: const MaterialApp(
        home: RegionDetailScreen(regionId: 'region-1'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Failed to load region'), findsNothing);
    expect(find.text('Forest of Endurance'), findsWidgets);
  });

  testWidgets('a failed required region read shows Retry', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        worldZoneServiceProvider
            .overrideWithValue(_RegionService(failRegion: true)),
        characterProfileProvider.overrideWith(_PendingCharacter.new),
      ],
      child: const MaterialApp(
        home: RegionDetailScreen(regionId: 'region-1'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Failed to load region'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a confirmed region stays visible when its refresh fails',
      (tester) async {
    final cached = await _RegionService().getRegionDetail('region-1');
    final container = ProviderContainer(overrides: [
      worldZoneServiceProvider
          .overrideWithValue(_RegionService(failRegion: true)),
      currentRegionDetailProvider.overrideWith((ref) async => cached),
      characterProfileProvider.overrideWith(_PendingCharacter.new),
    ]);
    await container.read(currentRegionDetailProvider.future);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: RegionDetailScreen(regionId: 'region-1'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Forest of Endurance'), findsWidgets);
    expect(find.text('Failed to load region'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
  });
}
