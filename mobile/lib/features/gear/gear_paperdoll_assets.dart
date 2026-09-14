import '../../core/constants/app_icons.dart';

/// Default icon shown in an empty hex slot, per slot type. `Head` has no
/// supplied art yet, so it falls back to the plain "+" placeholder.
String? gearSlotDefaultIcon(String slotType) {
  switch (slotType) {
    case 'Chest':
      return AppIcons.itemDefaultChest;
    case 'Legs':
      return AppIcons.itemDefaultLegs;
    case 'Feet':
      return AppIcons.itemDefaultFeet;
    case 'Accessory1':
      return AppIcons.itemDefaultAccessory;
    case 'Hands':
      return AppIcons.itemDefaultHands;
    default:
      return null;
  }
}

String? _normalizeName(String? name) =>
    name?.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// Resolves an equipped item to its on-character paper-doll layer asset.
/// Every layer is a full 1024x1536 canvas — the same canvas as
/// `AppIcons.gearBaseRender` — with the garment already drawn in its correct
/// body position (see `design-mockup/generated-icons/paperdoll-layer-spec.md`),
/// so rendering it is just stacking same-size images, no per-item math.
///
/// Only the Legs/Chest test items have layer art today — everything else
/// equips fine but simply has no visual layer on the character yet.
String? gearOverlayAsset({required String id, String? name}) {
  switch (_normalizeName(name)) {
    case 'shadow joggers':
      return AppIcons.gearLayerShadowJoggers;
    case 'crimson trail shorts':
      return AppIcons.gearLayerCrimsonTrailShorts;
    case 'tactical raid hoodie':
      return AppIcons.gearLayerTacticalRaidHoodie;
    case 'alpine cable sweater':
      return AppIcons.gearLayerAlpineCableSweater;
    case 'wanderer s poncho':
      return AppIcons.gearLayerWanderersPoncho;
    case 'ascender s climbing rig':
      return AppIcons.gearLayerAscendersClimbingRig;
    case 'timber flannel shirt':
      return AppIcons.gearLayerTimberFlannelShirt;
    case 'vanguard puffer jacket':
      return AppIcons.gearLayerVanguardPufferJacket;
    default:
      return null;
  }
}

/// Bottom-to-top render order for stacking layers on the base character.
const gearOverlaySlotOrder = <String>['Legs', 'Chest'];
