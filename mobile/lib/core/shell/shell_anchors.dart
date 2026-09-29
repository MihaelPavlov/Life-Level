import '../motion/reward_fx.dart';

/// Screen positions that effects travel between across features, e.g. an
/// imported workout flying into the hero and its km landing on the Map
/// button. Registered by [FxAnchorTarget] wrappers; read by RewardFx.
class ShellAnchors {
  ShellAnchors._();

  /// The character on the Home hero stage.
  static final hero = FxAnchor();

  /// The avatar + XP ring in the Home header.
  static final avatar = FxAnchor();

  /// The Map button in the middle of the tab bar.
  static final mapOrb = FxAnchor();
}
