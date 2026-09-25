import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/talents/models/talent_models.dart';

void main() {
  test('parses draw-history pricing without pricing progress', () {
    final screen = TalentScreen.fromJson({
      'wallet': {
        'coins': 2000,
        'crystals': 8,
        'ownedCount': 8,
        'catalogCount': 16
      },
      'drawCount': 20,
      'drawCrystalCost': 4,
      'drawCoinCost': 1675,
      'canDraw': true,
      'collectionComplete': false,
      'talents': <dynamic>[],
    });

    expect(screen.drawCount, 20);
    expect(screen.drawCoinCost, 1675);
    expect(screen.drawCrystalCost, 4);
    expect(screen.collectionComplete, isFalse);
  });

  test('recognizes a completed collection from the server', () {
    final screen = TalentScreen.fromJson({
      'wallet': <String, dynamic>{},
      'drawCount': 120,
      'drawCrystalCost': 35,
      'drawCoinCost': 8675,
      'canDraw': false,
      'collectionComplete': true,
      'talents': <dynamic>[],
    });

    expect(screen.collectionComplete, isTrue);
    expect(screen.canDraw, isFalse);
  });
}
