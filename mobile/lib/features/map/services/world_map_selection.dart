/// Process-lifetime holder for the region the user is currently viewing
/// inside the world hub. Lets the hub survive tab switches — if the user
/// drills into Forest, taps Profile, then taps Map again, the hub remounts
/// and restores Forest automatically.
///
/// Cleared when the user explicitly backs out to the hub list.
class WorldMapSelection {
  static String? openRegionId;
}
