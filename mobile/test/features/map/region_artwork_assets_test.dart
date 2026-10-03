import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/map/widgets/world_map_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all region trail backgrounds and banners are bundled', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest.listAssets().toSet();
    const regions = [
      'Forest of Endurance',
      'Ocean of Balance',
      'Mountains of Strength',
      'Ashen Caldera',
      'Frostspire Tundra',
      'Sunscorch Dunes',
      'Shadewood Deep',
      'Moonlit Reef',
      'Thunderpeak Range',
      'Emberfall Crater',
      'Glacier Abyss',
      'Mirage Wastes',
      'Verdant Spine',
      'Abyssal Trench',
      'Apex Caldera',
    ];

    for (final region in regions) {
      expect(bundled, contains(RegionArtwork.backgroundFor(region)),
          reason: '$region trail background is missing');
      expect(bundled, contains(RegionArtwork.bannerFor(region)),
          reason: '$region banner is missing');
    }
  });
}
