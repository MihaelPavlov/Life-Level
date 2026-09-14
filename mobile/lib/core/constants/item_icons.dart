import 'app_icons.dart';

String? itemIconAsset({required String id, String? name}) {
  final byId = _itemIconAssetById(id);
  if (byId != null) return byId;
  return _itemIconAssetByName(name);
}

String? _itemIconAssetById(String id) {
  switch (_normalizeId(id)) {
    case '10000000000000000000000000000001':
      return AppIcons.itemApexGpsPro;
    case '10000000000000000000000000000009':
      return AppIcons.itemPulseWristband;
    case '10000000000000000000000000000010':
      return AppIcons.itemBasicStepCounter;
    case '10000000000000000000000000000011':
      return AppIcons.itemStravaSyncBadge;
    case '10000000000000000000000000000003':
      return AppIcons.itemCryoJersey;
    case '10000000000000000000000000000007':
      return AppIcons.itemIronHeadband;
    case '10000000000000000000000000000012':
      return AppIcons.itemStormJacket;
    case '10000000000000000000000000000013':
      return AppIcons.itemCompressionShirt;
    case '10000000000000000000000000000014':
      return AppIcons.itemEliteWindbreaker;
    case '10000000000000000000000000000002':
      return AppIcons.itemAeroRaceCap;
    case '10000000000000000000000000000005':
      return AppIcons.itemCarbonX3;
    case '10000000000000000000000000000008':
      return AppIcons.itemTrailRunnerX5;
    case '10000000000000000000000000000015':
      return AppIcons.itemSpeedSpikes;
    case '10000000000000000000000000000016':
      return AppIcons.itemRecoverySlides;
    case '10000000000000000000000000000017':
      return AppIcons.itemGravityBoots;
    case '10000000000000000000000000000004':
      return AppIcons.itemGripWraps;
    case '10000000000000000000000000000006':
      return AppIcons.itemSportBuds;
    case '10000000000000000000000000000018':
      return AppIcons.itemClimbingChalkBag;
    case '10000000000000000000000000000019':
      return AppIcons.itemResistanceBandSet;
    case '10000000000000000000000000000020':
      return AppIcons.itemChampionGloves;
    case '10000000000000000000000000000021':
      return AppIcons.itemAuraStone;
    case '10000000000000000000000000000022':
      return AppIcons.itemXpBooster;
    case '10000000000000000000000000000023':
      return AppIcons.itemEnergyGel;
    case '10000000000000000000000000000024':
      return AppIcons.itemStreakShield;
    case '10000000000000000000000000000025':
      return AppIcons.itemKtTapeRoll;
    case '10000000000000000000000000000026':
      return AppIcons.itemPhoenixElixir;
    case '10000000000000000000000000000027':
      return AppIcons.itemZoneCompass;
    case '10000000000000000000000000000028':
      return AppIcons.itemBossScroll;
    case '10000000000000000000000000000029':
      return AppIcons.itemShadowJoggers;
    case '10000000000000000000000000000030':
      return AppIcons.itemCrimsonTrailShorts;
    case '10000000000000000000000000000031':
      return AppIcons.itemTacticalRaidHoodie;
    case '10000000000000000000000000000032':
      return AppIcons.itemAlpineCableSweater;
    case '10000000000000000000000000000033':
      return AppIcons.itemWanderersPoncho;
    case '10000000000000000000000000000034':
    case '119c1f6262714e15a1389b2e6b477b47':
      return AppIcons.itemAscendersClimbingRig;
    case '10000000000000000000000000000035':
    case 'ceacca17492d4187a95e59dd8298e103':
      return AppIcons.itemTimberFlannelShirt;
    case '10000000000000000000000000000036':
    case 'bcc2f9d8bacf49629bbeac097fbaf8a6':
      return AppIcons.itemVanguardPufferJacket;
  }

  return null;
}

String? _itemIconAssetByName(String? name) {
  switch (_normalizeName(name ?? '')) {
    case 'apex gps pro':
      return AppIcons.itemApexGpsPro;
    case 'pulse wristband':
      return AppIcons.itemPulseWristband;
    case 'basic step counter':
      return AppIcons.itemBasicStepCounter;
    case 'strava sync badge':
      return AppIcons.itemStravaSyncBadge;
    case 'cryo jersey':
      return AppIcons.itemCryoJersey;
    case 'iron headband':
      return AppIcons.itemIronHeadband;
    case 'storm jacket':
      return AppIcons.itemStormJacket;
    case 'compression shirt':
      return AppIcons.itemCompressionShirt;
    case 'elite windbreaker':
      return AppIcons.itemEliteWindbreaker;
    case 'aero race cap':
      return AppIcons.itemAeroRaceCap;
    case 'carbon x3':
      return AppIcons.itemCarbonX3;
    case 'trail runner x5':
      return AppIcons.itemTrailRunnerX5;
    case 'speed spikes':
      return AppIcons.itemSpeedSpikes;
    case 'recovery slides':
      return AppIcons.itemRecoverySlides;
    case 'gravity boots':
      return AppIcons.itemGravityBoots;
    case 'grip wraps':
      return AppIcons.itemGripWraps;
    case 'sport buds':
      return AppIcons.itemSportBuds;
    case 'climbing chalk bag':
      return AppIcons.itemClimbingChalkBag;
    case 'resistance band set':
      return AppIcons.itemResistanceBandSet;
    case 'champion gloves':
      return AppIcons.itemChampionGloves;
    case 'aura stone':
      return AppIcons.itemAuraStone;
    case 'xp booster':
      return AppIcons.itemXpBooster;
    case 'energy gel':
      return AppIcons.itemEnergyGel;
    case 'streak shield':
      return AppIcons.itemStreakShield;
    case 'kt tape roll':
      return AppIcons.itemKtTapeRoll;
    case 'phoenix elixir':
      return AppIcons.itemPhoenixElixir;
    case 'zone compass':
      return AppIcons.itemZoneCompass;
    case 'boss scroll':
      return AppIcons.itemBossScroll;
    case 'shadow joggers':
      return AppIcons.itemShadowJoggers;
    case 'crimson trail shorts':
      return AppIcons.itemCrimsonTrailShorts;
    case 'tactical raid hoodie':
      return AppIcons.itemTacticalRaidHoodie;
    case 'alpine cable sweater':
      return AppIcons.itemAlpineCableSweater;
    case 'wanderer s poncho':
      return AppIcons.itemWanderersPoncho;
    case 'ascender s climbing rig':
      return AppIcons.itemAscendersClimbingRig;
    case 'timber flannel shirt':
      return AppIcons.itemTimberFlannelShirt;
    case 'vanguard puffer jacket':
      return AppIcons.itemVanguardPufferJacket;
  }

  return null;
}

String _normalizeId(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-f0-9]+'), '');

String _normalizeName(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
