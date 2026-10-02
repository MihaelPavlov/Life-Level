import 'package:flutter_test/flutter_test.dart';
import 'package:life_level/features/boss/models/boss_list_item.dart';

BossListItem _boss({
  bool canFight = true,
  bool activated = false,
  bool defeated = false,
  bool expired = false,
}) =>
    BossListItem(
      id: 'boss-1',
      name: 'The Warden',
      icon: 'boss.png',
      maxHp: 1000,
      rewardXp: 250,
      timerDays: 7,
      isMini: false,
      region: 'WhisperingWoods',
      nodeName: 'Warden Gate',
      levelRequirement: 5,
      canFight: canFight,
      activated: activated,
      hpDealt: 0,
      isDefeated: defeated,
      isExpired: expired,
    );

void main() {
  test('newly reached boss needs attention before first battle activation', () {
    final boss = _boss();

    expect(boss.isReadyToFight, isTrue);
    expect(boss.isActive, isFalse);
    expect(boss.needsAttention, isTrue);
  });

  test('started boss remains active and needs attention', () {
    final boss = _boss(activated: true);

    expect(boss.isReadyToFight, isFalse);
    expect(boss.isActive, isTrue);
    expect(boss.needsAttention, isTrue);
  });

  test('expired and defeated bosses remain history, not active alerts', () {
    expect(_boss(activated: true, expired: true).needsAttention, isFalse);
    expect(_boss(activated: true, defeated: true).needsAttention, isFalse);
  });
}
