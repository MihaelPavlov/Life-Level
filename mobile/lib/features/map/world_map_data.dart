import 'world_map_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────────────────────

const int kMockUserLevel = 7;

const List<ZoneData> kZones = [
  ZoneData(
    id: 'ashfield',
    name: 'Ashfield Plains',
    icon: '🌾',
    status: ZoneStatus.completed,
    tier: 0,
    relativeX: 0.5,
    region: 'Lowlands',
    nodeCount: 12,
    totalXp: 2500,
    distanceKm: 8,
    levelRequirement: 1,
    isCrossroads: false,
    description: 'A gentle, open plain where adventurers begin their journey.',
  ),
  ZoneData(
    id: 'first_fork',
    name: 'First Fork',
    icon: '⚔️',
    status: ZoneStatus.available,
    tier: 1,
    relativeX: 0.5,
    region: 'Lowlands',
    levelRequirement: 1,
    isCrossroads: true,
    description: 'A crossroads where two great paths diverge.',
  ),
  ZoneData(
    id: 'thornwood',
    name: 'Thornwood Forest',
    icon: '🌲',
    status: ZoneStatus.active,
    tier: 2,
    relativeX: 0.3,
    region: 'Verdant Reach',
    nodeCount: 9,
    totalXp: 3200,
    distanceKm: 12,
    levelRequirement: 5,
    isCrossroads: false,
    description: 'Dense woodland filled with ancient ruins and hidden trails.',
  ),
  ZoneData(
    id: 'iron_peaks',
    name: 'Iron Peaks',
    icon: '⛰️',
    status: ZoneStatus.available,
    tier: 2,
    relativeX: 0.7,
    region: 'Stonereach',
    nodeCount: 11,
    totalXp: 4100,
    distanceKm: 15,
    levelRequirement: 5,
    isCrossroads: false,
    description: 'Towering mountains forged from iron ore, home to powerful beasts.',
  ),
  ZoneData(
    id: 'convergence',
    name: 'The Convergence',
    icon: '🔀',
    status: ZoneStatus.locked,
    tier: 3,
    relativeX: 0.5,
    region: 'Nexus',
    levelRequirement: 8,
    isCrossroads: true,
    description: 'A mysterious junction where the paths of fate cross.',
  ),
  ZoneData(
    id: 'coral',
    name: 'Coral Coast',
    icon: '🌊',
    status: ZoneStatus.locked,
    tier: 4,
    relativeX: 0.3,
    region: 'Azure Shore',
    nodeCount: 10,
    totalXp: 5000,
    distanceKm: 18,
    levelRequirement: 10,
    isCrossroads: false,
    description: 'A sunken coastal zone teeming with sea beasts and lost treasure.',
  ),
  ZoneData(
    id: 'frostbound',
    name: 'Frostbound Peaks',
    icon: '❄️',
    status: ZoneStatus.locked,
    tier: 4,
    relativeX: 0.7,
    region: 'Glacial Expanse',
    nodeCount: 13,
    totalXp: 6200,
    distanceKm: 22,
    levelRequirement: 10,
    isCrossroads: false,
    description: 'A frozen mountain range where only the strongest endure.',
  ),
  ZoneData(
    id: 'final_approach',
    name: 'Final Approach',
    icon: '🔱',
    status: ZoneStatus.locked,
    tier: 5,
    relativeX: 0.5,
    region: 'Apex',
    levelRequirement: 12,
    isCrossroads: true,
    description: 'The last checkpoint before the ultimate trial.',
  ),
  ZoneData(
    id: 'desert',
    name: 'Desert of Trials',
    icon: '🏜️',
    status: ZoneStatus.locked,
    tier: 6,
    relativeX: 0.5,
    region: 'Ashen Wastes',
    nodeCount: 14,
    totalXp: 8000,
    distanceKm: 30,
    levelRequirement: 15,
    isCrossroads: false,
    description: 'An endless scorching desert that tests the limits of every hero.',
  ),
];

// id → list of connected ids (directed: from → to, drawn from lower tier to higher)
const Map<String, List<String>> kEdges = {
  'ashfield':       ['first_fork'],
  'first_fork':     ['thornwood', 'iron_peaks'],
  'thornwood':      ['convergence'],
  'iron_peaks':     ['convergence'],
  'convergence':    ['coral', 'frostbound'],
  'coral':          ['final_approach'],
  'frostbound':     ['final_approach'],
  'final_approach': ['desert'],
};

// ─────────────────────────────────────────────────────────────────────────────
// Layout constants
// ─────────────────────────────────────────────────────────────────────────────

const double kCanvasWidth   = 390.0;
const double kCanvasHeight  = 1200.0;
const double kTierHeight    = 160.0;
const double kTopPadding    = 80.0;
const double kZoneRadius    = 26.0;
const double kDiamondHalf   = 22.0;
const double kFogStartFrac  = 0.42; // fraction of canvas height where fog begins
