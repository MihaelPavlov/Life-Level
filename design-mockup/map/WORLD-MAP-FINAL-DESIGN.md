# World Map — Final Design Spec

> **Approved direction:** hybrid of three v3 mockups — World hub (`world-map-v3-world.html`), Region drill-down (`world-map-v3-region.html`), and Vertical path (`world-map-v3-path.html`). The vertical path lives *inside* the Region screen; it no longer spans the whole world. This document is the single source of truth for the Flutter port.

---

## 1. Vision

The World Map is a **two-level navigation**:

1. **World screen** — a scrollable list of region hero cards. Users see the whole world at a glance: what's active, what's locked, and how far they've come in each region.
2. **Region screen** — a scoped **vertical node path** (Duolingo-style) showing zones *inside* one region. Tap a zone node → a simplified bottom sheet opens.

A third surface — the **Zone Detail Sheet** — is shared by both screens and replaces the current 617-line multi-branch sheet with one adaptive layout.

**Metaphor:** chapters in a book. Each region is a chapter; each zone is a page. You flip through regions at the world level and read each chapter node-by-node.

**What this replaces:** the current `WorldMapScreen` canvas (`mobile/lib/features/map/world_map_screen.dart`, `world_map_painter.dart`) and the 3-branch `world_map_detail_sheet.dart`. The mental model of "one big 2D painted map with tiers" is retired.

---

## 2. Information Architecture

```
┌────────────────────────────────────────────────┐
│ Nav bar: Map tab                               │
└────────────────────────────────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────────┐
│ SCREEN 1 · World Map                           │
│  • Header (World Map · Lv 12)                  │
│  • Active journey strip (clickable)            │
│  • Section: REGIONS · N UNLOCKED               │
│  • Region hero cards:                          │
│     - Forest of Endurance (ACTIVE)             │
│     - Ocean of Balance (COMPLETED)             │
│     - Mountains of Strength (LOCKED, Lv 15+)   │
│     - Ashen Caldera (LOCKED, Lv 25+)           │
└────────────────────────────────────────────────┘
                      │ tap region card
                      ▼
┌────────────────────────────────────────────────┐
│ SCREEN 2 · Region Detail                       │
│  • Banner (back · emoji · name · lore)         │
│  • Summary tiles (zones · XP · boss)           │
│  • Section: YOUR PATH THROUGH [REGION]         │
│  • Vertical node trail (path):                 │
│     - Zone nodes (completed/active/next/locked)│
│     - Crossroads nodes (fork)                  │
│     - Boss node (end of region)                │
│  • Journey progress footer (if traveling)      │
└────────────────────────────────────────────────┘
                      │ tap node
                      ▼
┌────────────────────────────────────────────────┐
│ COMPONENT · Zone Detail Sheet (bottom sheet)   │
│  • Header (emoji · name · region · status pill)│
│  • 3 chips (lv req · distance · xp) OR note    │
│  • Body (desc | travel-to | travel-from)       │
│  • Single primary CTA                          │
└────────────────────────────────────────────────┘
```

**Back navigation:**
- Region screen has a back chevron in the top-left of the banner → returns to World screen.
- Zone sheet has an `✕` close button in the top-right → dismisses the sheet.
- Hardware back (Android): Region → World → closes map tab (to Home).

**Entry from Home screen:** the "View on map →" button in `home_adventure_hero.dart` navigates to the World screen, then auto-drills into the active region (one tap happens automatically if an active journey exists, so the user lands at the node they're traveling between).

---

## 3. Design Tokens

All tokens reuse `design-mockup/home/home-v3.html` exactly. Flutter side maps them to existing `AppColors`/`AppText` constants (or adds equivalents if missing).

| Token | Value | Use |
|---|---|---|
| `--bg-deep` | `#040810` | Body background |
| `--bg-base` | `#080e14` | Phone frame / behind cards |
| `--surface-1` | `#161b22` | Cards, sheet surface |
| `--surface-2` | `#1e2632` | Chips, tile backgrounds, secondary buttons |
| `--border` | `#30363d` | Card borders, chip borders |
| `--border-soft` | `#1e2632` | Quest item dividers |
| `--text-primary` | `#e6edf3` | Primary copy |
| `--text-secondary` | `#8b949e` | Labels, subs |
| `--text-muted` | `#4d5b6b` | Locked / deemphasized |
| `--blue` | `#4f9eff` | Active state, primary actions, progress |
| `--purple` | `#a371f7` | Crossroads, magic, level badge |
| `--orange` | `#f5a623` | Next/destination/warning, travel |
| `--red` | `#f85149` | Boss, danger, errors |
| `--green` | `#3fb950` | Completed, success, arrived |

**Radii:** cards `16px` · sheets `22px` (top corners) · chips/tiles `10–12px` · buttons `12–14px` · bubbles `50%`.

**Spacing rhythm:** cards have `14px 16px` padding and `10px` bottom margin. Section titles sit `10px` above their content with `0.08em` letter-spacing at `10px` UPPERCASE.

**Font:** Inter, -apple-system fallback. Sizes:
- 9px/700 UPPERCASE micro-labels (chip labels, chapter dividers)
- 10px/700 UPPERCASE section titles
- 11px/600 body secondary
- 12px/700 body primary (quest names, chip values)
- 14–16px/800 card titles
- 18–22px/800 screen titles

**Phone frame:** 390 × 844px, 44px radius.

---

## 4. Screen 1 · World Map

### 4.1 Layout (top → bottom)

```
┌────────────────────────────────── 390 ──────────┐
│  Status bar · 44px                              │
├─────────────────────────────────────────────────┤
│  HEADER ROW (16px side padding · 14px tall)    │
│  ┌────────────────────────┬────────┐            │
│  │ EXPLORER KAI           │ Lv 12 │            │
│  │ World Map              │        │            │
│  └────────────────────────┴────────┘            │
├─────────────────────────────────────────────────┤
│  ACTIVE JOURNEY STRIP (conditional)             │
│  ┌───┬───────────────────────────┬──────┐       │
│  │🏰 │ TRAVELING · Forest of End │ 54%  │       │
│  │   │ → Ember Forge · 2.7/5.0km │      │       │
│  └───┴───────────────────────────┴──────┘       │
├─────────────────────────────────────────────────┤
│  SECTION TITLE                                  │
│  REGIONS · 2 UNLOCKED                           │
├─────────────────────────────────────────────────┤
│  REGION HERO CARD · Active                      │
│  ┌──────────────────────────────────┐           │
│  │ [72px banner: gradient + emoji   │           │
│  │   + "Active" badge + pin chips]  │           │
│  │ Forest of Endurance              │           │
│  │ lore 1 line                      │           │
│  │ Progress: 4 / 7 zones            │           │
│  │ ████████████░░░░░░░ 57%          │           │
│  │ meta ··············· [Enter →]   │           │
│  └──────────────────────────────────┘           │
│                                                 │
│  REGION HERO CARD · Completed (Ocean)           │
│  REGION HERO CARD · Locked Lv 15 (Mountains)    │
│  REGION HERO CARD · Locked Lv 25 (Caldera)      │
│  …                                              │
├─────────────────────────────────────────────────┤
│  FAB (boss) · Nav bar                           │
└─────────────────────────────────────────────────┘
```

### 4.2 Components

#### 4.2.1 Header Row

| Field | Data source | Notes |
|---|---|---|
| Chapter label | `profile.characterName` or "Explorer Kai" | 10px UPPERCASE · letter-spacing 0.12em · `--blue` |
| Title | literal `"World Map"` | 20px/800 · `--text-primary` |
| Level chip | `profile.level` | Gradient blue→purple · 10px/800 · 5px 10px padding · glow `rgba(79,158,255,0.3)` |

No notification bell on the World screen (lives on Home). Keep the header lean.

#### 4.2.2 Active Journey Strip (conditional)

**Renders only when `userProgress.hasActiveJourney == true`.**

| Slot | Data | Visual |
|---|---|---|
| Icon tile (34×34) | destination zone emoji | bg `rgba(79,158,255,0.18)` · border `rgba(79,158,255,0.4)` |
| Title | `"TRAVELING · {regionName}"` | 10px UPPERCASE `--blue` |
| Sub | `"→ {destinationName} · {distanceTravelled} / {distanceTotal} km"` | 12px/700 `--text-primary` |
| Percent | `Math.round(distanceTravelled / distanceTotal * 100)%` | 14px/800 right-aligned |

**Tap behavior:** navigates to the Region screen of the region containing the destination, scrolled to the active node.

#### 4.2.3 Region Hero Card

Each region is rendered as one card. Card structure has **two stacked parts**:

**Part A — Banner strip (72px tall)**
- Gradient background keyed to region type (see 4.2.4 table below).
- 44px emoji, drop-shadow `0 4px 12px rgba(0,0,0,0.5)`.
- Status badge (top-right): `Active` / `Completed ✓` / `🔒 Lv N`.
- Pin chips at bottom (up to 2): `"You are here · {zone}"`, `"🏆 N / M zones"`, `"👹 Boss · {name}"`, `"🔒 Unlock at Lv N"`.
- Pin chip variants: `--active` (blue), `--boss` (red), default (transparent).

**Part B — Body (12px top / 14px bottom padding)**
- Region name (16px/800).
- Lore (11px `--text-secondary`, 1 line, max 2 lines truncated).
- Progress row: label `PROGRESS` · value `N / M zones` (or `Lv X / Y` for locked).
- Progress bar (6px tall). Fill color:
  - Active region → `--green` linear fill.
  - Completed region → `--green` 100%.
  - Locked region → `--orange` showing level-up progress (`currentLevel / requiredLevel`).
- CTA row: left-aligned meta (`"+2,840 XP · 2 zones left to boss"`), right-aligned button:
  - Active → green solid `Enter →`
  - Completed → grey ghost `Revisit →`
  - Locked → grey disabled `🔒 Locked`

#### 4.2.4 Region visual theming (6 baked themes)

| Region type | Banner gradient | Accent | Example |
|---|---|---|---|
| `forest` | `linear-gradient(135deg, rgba(63,185,80,0.28), rgba(79,158,255,0.1))` | green | Forest of Endurance |
| `mountain` | `linear-gradient(135deg, rgba(163,113,247,0.22), rgba(79,158,255,0.16))` | purple | Mountains of Strength |
| `ocean` | `linear-gradient(135deg, rgba(79,158,255,0.25), rgba(0,0,0,0.2))` | blue | Ocean of Balance |
| `frost` | `linear-gradient(135deg, rgba(79,158,255,0.14), rgba(230,237,243,0.08))` | ice-blue | Frostlands |
| `volcano` | `linear-gradient(135deg, rgba(248,81,73,0.2), rgba(245,166,35,0.18))` | red-orange | Ashen Caldera |
| `desert` | `linear-gradient(135deg, rgba(245,166,35,0.22), rgba(227,179,65,0.12))` | gold | (future) |

Backend adds `region.theme` enum so the client picks the correct gradient.

### 4.3 Scroll behavior

- Full-screen vertical scroll, `padding: 54px 16px 110px`.
- No scroll indicator; scrollbars hidden.
- Active journey strip scrolls with content (not sticky). Justification: user can always get back to it by scrolling up; keeping it non-sticky avoids visual weight on long scrolls through regions.

---

## 5. Screen 2 · Region Detail

### 5.1 Layout (top → bottom)

```
┌─ 390 ───────────────────────────────────────────┐
│ Status bar                                      │
├─────────────────────────────────────────────────┤
│ BANNER (210px tall, full-bleed)                 │
│ ┌───┐                                           │
│ │ ‹ │     🌲  CHAPTER 2 · ACTIVE               │
│ └───┘         Forest of Endurance              │
│       "Endless woodlands that reward every km"  │
├─────────────────────────────────────────────────┤
│ SUMMARY TILES (3 tiles, 8px gap)                │
│ ┌─ Zones ─┬─ XP ─────┬─ Boss ──┐               │
│ │ 4 / 7   │ 1,240    │ 2 zones │               │
│ └─────────┴──────────┴─────────┘               │
├─────────────────────────────────────────────────┤
│ SECTION: Your path through the forest           │
├─────────────────────────────────────────────────┤
│ VERTICAL NODE TRAIL                             │
│   • Zone 1 (left, completed)                    │
│   • Zone 2 (right, completed)                   │
│   • Zone 3 (left, active / you are here)        │
│   • Zone 4 (right, next/destination)            │
│   • Crossroads (center, purple diamond)         │
│   • Boss (center, red, pulsing)                 │
├─────────────────────────────────────────────────┤
│ JOURNEY PROGRESS FOOTER (conditional)           │
│ TRAVELING · 2.7 / 5.0 km                        │
│ █████████░░░░░░░░ 54%                           │
│ "Arrival bonus: +600 XP · ×1.5 weekend"         │
├─────────────────────────────────────────────────┤
│ FAB · Nav                                       │
└─────────────────────────────────────────────────┘
```

### 5.2 Components

#### 5.2.1 Banner

| Slot | Data | Visual |
|---|---|---|
| Back button (36×36) | navigates pop | `rgba(0,0,0,0.35)` bg · blur backdrop · `‹` chevron |
| Background | region theme gradient (see 4.2.4) faded to `--bg-base` at 70% | radial highlight at 80% 20% |
| Emoji | `region.emoji` (56px, drop-shadow) | |
| Chapter tag | `"CHAPTER {idx} · {status}"` uppercase 10px/800 `--green` if active | |
| Region name | `region.name` (24px/800) | |
| Lore | `region.lore` (11px `--text-secondary`, 2 lines max) | |

Banner background gradient inherits the region's theme color (same mapping as 4.2.4) but blended against `--bg-base` for a faded hero effect.

#### 5.2.2 Summary Tiles (3 tiles, fixed)

Horizontal row, flex 1 each. Each tile:

```
┌──────────────┐
│ 🗝 ZONES     │   <- 9px UPPERCASE · --text-secondary
│ 4 / 7        │   <- 14px/800 · accent color
└──────────────┘
```

| Tile | Label | Value | Accent |
|---|---|---|---|
| Left | `🗝 Zones` | `{completedZones} / {totalZones}` | `--green` |
| Middle | `⭐ XP earned` | `region.totalXpEarned` | `--text-primary` |
| Right | `👹 Boss` | `{zonesToBoss} zones` or `Defeated ✓` | `--red` or `--green` |

#### 5.2.3 Section title

`"YOUR PATH THROUGH THE {REGION_LAST_WORD}"` (e.g. "YOUR PATH THROUGH THE FOREST"). 10px UPPERCASE `--text-secondary`, margin `20px 16px 10px`.

#### 5.2.4 Vertical Node Trail

This is the core mechanic. Reuses the `pathv3-*` pattern from `world-map-v3-path.html`.

**Layout rules:**
- Zones alternate `left → right → left → right …` with occasional `center` for crossroads and bosses.
- Each node row is 86px min-height.
- Left padding 52px (for `left` nodes), right padding 52px (for `right` nodes).
- An SVG `<svg>` behind the nodes renders the curves connecting them (Bezier paths).

**Curve rules:**
- Segment between two `completed` nodes → gradient green (`opacity 0.55 → 0.3`).
- Segment entering an `active` node → gradient green→blue.
- Segment from `active` to `next` → dashed orange (`stroke-dasharray: 8 6`).
- Segment entering a `locked` node → dashed grey (`stroke-dasharray: 6 8`, opacity 0.5).
- Crossroads branch: two outgoing curves fanning left + right to the fork targets.

**Node variants:**

| State | Circle size | Border | Fill | Icon | Sub label |
|---|---|---|---|---|---|
| `completed` | 48px | solid `--green` | `rgba(63,185,80,0.15)` | `✓` | "+N XP" (green) |
| `active` (you are here) | 72px | solid `--blue` 3px | blue gradient + pulse animation `0 0 28→38px glow` | zone emoji | "You are here" + floating `YOU ARE HERE` badge above |
| `next` (destination) | 68px | dashed `--orange` 2px | orange gradient | zone emoji | "N km to go" (orange) |
| `locked` | 48px | solid `--border` | `--surface-2` | `🔒` or zone emoji @ 0.6 opacity | "Lv N · Locked" (muted) |
| `crossroads` | 60px | purple 2px, rotated 45° (diamond) | purple gradient | `✦` rotated back | "Crossroads" (purple) |
| `boss` | 68px | red 2px + pulse animation | red gradient | `👹` | "Boss · Unlocks {nextRegion}" (red) |

**Label rules under each bubble:**
- Line 1: zone name (11px/700, max 130px wide, ellipsis).
- Line 2: `{sub}` 9px UPPERCASE with state-colored text.
- Active state adds floating `YOU ARE HERE` badge (see `pathv3-youarehere` class).

**Crossroads branch rendering:** after the crossroads node, two `locked`/`available` bubbles render side-by-side (flex row justify-around) representing the two paths. Both are tappable → opens zone sheet.

**Tap target:** entire `lv5-node` row (not just the bubble).

#### 5.2.5 Journey Progress Footer (conditional)

Renders **only when user is traveling to a zone in this region**.

```
┌─────────────────────────────────┐
│ TRAVELING · 2.7 / 5.0 km        │
│ ████████████░░░░░░░ 54%         │
│ Arrival bonus: +600 XP · …      │
└─────────────────────────────────┘
```

Styling: `linear-gradient(135deg, rgba(79,158,255,0.15), rgba(163,113,247,0.1))` · border `rgba(79,158,255,0.4)` · 14px radius. Lives below the trail with `margin: 14px 16px 0`.

The bar is 8px tall, gradient blue→orange, rounded.

---

## 6. Component · Zone Detail Sheet

Shared bottom sheet opened on zone-node tap from the Region screen.

### 6.1 Anatomy (single adaptive layout)

```
┌─────────────────────────────────── 390 ────────┐
│ ≡ (grabber)                              [✕]   │
│                                                │
│ ┌──────┐   {Zone Name}                         │
│ │ 🏰    │   {Region} · Tier {N}                │
│ │      │   [status pill]                      │
│ └──────┘                                       │
│                                                │
│ ┌────────┬────────┬────────┐                   │
│ │ LV REQ │ DIST.  │ XP RWD │     (chips row)  │
│ │ Lv 10✓ │ 5.0 km │ +600   │                   │
│ └────────┴────────┴────────┘                   │
│                                                │
│ {body} ─ description | journey | you-are-here  │
│                                                │
│ [ ── Primary CTA ── ]                          │
└────────────────────────────────────────────────┘
```

### 6.2 Layout states (one component, five data-driven variants)

| State trigger | Header pill | Chips | Body | CTA |
|---|---|---|---|---|
| **Available** (no active journey) | `Available · N km` orange | lv req · distance · xp | 2-line description | `→ Set as destination` orange solid |
| **Traveling-to** (this zone is active destination) | `Traveling · N km to go` orange | lv req · distance · xp | **Journey progress card** with bar & from/arrival rows | `⏳ Traveling · log workout to advance` disabled |
| **Traveling-from** (this zone is active source) | `You are here` blue | nodes · explored · xp pool | Green banner `📍 You're standing here` + `Traveling to …` mini-row | `✕ Cancel trip` disabled-look |
| **Crossroads** (branching point) | `Crossroads` purple | *(no chips)* | Purple dashed note `✦ Branching point · no entry required`. 2-line description. | `⚖ Choose a path` purple solid |
| **Locked** (level gate) | `🔒 Locked` grey | lv req (red ✕) · distance · xp | Description explaining unlock | `🔒 Lv N required` grey disabled |
| **Completed** | `Completed ✓` green | nodes · distance · xp | Description + (optional) codex pages line | `→ Revisit zone` green solid |

Exact CSS/HTML for each state already exists in `design-mockup/map/zone-sheet-v3.html` (States 1–5). Completed state is a new 6th variant that mirrors State 1 with a green pill and green CTA.

### 6.3 Sheet behavior

- **Open** via zone-node tap; animates from bottom. Max height 82%.
- **Dismiss** via: ✕ button · swipe-down · tap backdrop.
- **Grabber** bar at top for draggability cue.
- **Backdrop** `rgba(4,8,16,0.66) + backdrop-filter: blur(2px)`.
- **Scroll-lock** body scroll while sheet is open.

### 6.4 Data contract

```ts
ZoneSheetData {
  zone: {
    id: int
    name: string
    emoji: string
    regionName: string
    tier: int
    description: string
    levelRequirement: int
    distanceKm: float
    xpReward: int
    isCrossroads: bool
    status: 'completed' | 'active' | 'available' | 'locked'
    loreCollected?: int   // optional, for completed
    loreTotal?: int
    nodesCompleted?: int
    nodesTotal?: int
  }
  journey?: {
    mode: 'to' | 'from'
    destinationZoneName: string
    destinationZoneEmoji: string
    distanceTravelledKm: float
    distanceTotalKm: float
    etaKm: float             // remaining
  }
  userLevel: int
}
```

Client derives the six display states from `zone.status`, `zone.isCrossroads`, `journey.mode`, and `userLevel >= zone.levelRequirement`.

---

## 7. Path Trail — rendering rules (implementation reference)

For the Flutter port, the path is **not** a CustomPainter across the entire screen. It's a vertical Column of `_NodeRow` widgets where each row renders:
- Its bubble (left/right/center).
- The curve *above* it (connecting to the previous node) rendered as a short SVG or custom `CustomPaint`.

Pseudo-tree:

```dart
Column(
  children: [
    RegionBanner(region),
    SummaryTiles(region.stats),
    SectionTitle('YOUR PATH THROUGH THE FOREST'),
    for (final (i, node) in region.nodes.indexed)
      _NodeRow(
        node: node,
        align: _alignFor(i, node),      // left / right / center
        previousAlign: i == 0 ? null : _alignFor(i - 1, region.nodes[i - 1]),
        curveState: _curveState(region.nodes[i - 1]?.status, node.status),
      ),
    if (region.activeJourneyInThisRegion)
      JourneyProgressFooter(journey),
  ],
)
```

**`_alignFor(index, node)`** rules:
- `node.isCrossroads` → `center`.
- `node.isBoss` → `center`.
- Otherwise alternate by index parity: even → `left`, odd → `right`.

**Curve rendering:** each `_NodeRow` paints the single incoming curve segment in its own `CustomPaint`. Segments are S-curves (`cubicTo`) with control points at the half-Y of the row.

**No scroll-wide SVG.** Each segment is local to its row — simpler to implement, re-renders only when that row changes.

---

## 8. Journey Strip — shared component (both World + Region screens)

Same widget, different context:

- **On World screen**: renders above the region cards list. Tap → navigates to the destination's region screen and scrolls to the active node.
- **On Region screen**: renders as a **footer card below the trail** (not sticky) — called "Journey Progress Footer" in §5.2.5. Same styling, different layout purpose.

Both variants share the data model:

```ts
ActiveJourney {
  destinationZoneName: string
  destinationZoneEmoji: string
  regionName: string
  distanceTravelledKm: float
  distanceTotalKm: float
  arrivalXpReward: int
  arrivalBonusLabel?: string   // "×1.5 weekend" etc
}
```

If `ActiveJourney == null`, both strips are hidden.

---

## 9. State Machine · Zone lifecycle

```
     [locked] ──userLevel ≥ req──→ [available]
                                        │
                                        │ tap "Set as destination"
                                        ▼
                                   [traveling-to]   ←── active journey, not yet arrived
                                        │
                                        │ distanceTravelled = distanceTotal
                                        ▼
                                    [arrived]        ←── transient; offers "Enter zone"
                                        │
                                        │ tap "Enter zone"
                                        ▼
                                   [completed]       ←── green pill; can revisit

 [crossroads] ──cross at fork──→ [crossroads-cleared] (acts like completed but no xp)
```

A zone is the **active** node on the path when it is the *source* of a current journey (or standing point if no journey). Exactly one active node per user.

---

## 10. Edge Cases & Empty States

| Case | Behavior |
|---|---|
| No regions unlocked at all (brand-new user) | World screen shows one region card (Forest, default first region) in "Active" state; no journey strip. |
| User is at a region boundary (just unlocked a new region) | Previous region's boss card → `Defeated ✓` with green badge; new region card → `Active` state. Notification banner recommended (outside map scope). |
| Active journey → user enters a different region's screen | Journey strip still renders at the world level; on the *other* region's detail screen, no journey progress footer (because the journey isn't in that region). |
| Crossroads path has expired | Path UI: crossroads node dimmed + message "Path expired · cross again". No auto-retry. |
| Locked zone inside an unlocked region | Renders as `locked` bubble; tapping shows the Locked sheet variant with the specific level requirement. |
| Region has 0 completed zones | Summary tile "Zones" shows `0 / 7`. Trail renders with the first node as `next` (not yet cleared). No journey footer. |
| User taps the active zone | Opens zone sheet in **Traveling-from** mode if there's a journey, otherwise in the normal (completed/available) variant. |
| Data loading | Show shimmer skeleton for the region cards on World, and for the trail on Region. No spinner overlay. |
| Network failure | Banner at top `⚠ Couldn't sync map · Retry` with an inline retry button. Cached map still shows. |

---

## 11. Interactions · Gestures

| Target | Gesture | Action |
|---|---|---|
| Region card | tap | push Region screen |
| Region card (locked) | tap | open a small "unlock hint" sheet showing `Lv N+ required · N XP to next level` |
| World journey strip | tap | push Region screen + scroll to active node |
| Region banner back button | tap | pop to World |
| Zone node | tap | open Zone sheet |
| Zone node (locked) | tap | open Zone sheet (Locked variant) |
| Zone sheet | swipe down / tap backdrop / tap ✕ | dismiss |
| Zone sheet primary CTA | tap | state-dependent (see §6.2) |
| "Enter zone" (arrived state) | tap | navigate to zone content screen (outside this spec) |
| "Set as destination" | tap | call `setDestinationZone`, dismiss sheet, refresh Region screen |
| "Cancel trip" | tap | confirmation sub-sheet, then `cancelActiveJourney` |
| "Choose a path" (crossroads) | tap | open Path Choice modal (separate spec — see `design-mockup/crossroads-flow.html` for current design) |

No long-press, no drag-to-reorder, no pinch-zoom. The spec is deliberately gesture-minimal to reduce implementation surface.

---

## 12. Data Contract (backend → client)

Client fetches from one endpoint on Map tab open:

```
GET /api/map/world
```

Response:

```ts
WorldMapDto {
  user: {
    level: int
    characterName: string
  }
  activeJourney: ActiveJourney | null   // see §8
  regions: RegionSummaryDto[]           // 1 per region, ordered chapter-ascending
}

RegionSummaryDto {
  id: int
  name: string
  emoji: string
  theme: 'forest'|'mountain'|'ocean'|'frost'|'volcano'|'desert'
  lore: string
  chapterIndex: int
  status: 'active'|'completed'|'locked'
  levelRequirement: int
  completedZones: int
  totalZones: int
  totalXpEarned: int
  zonesUntilBoss: int | null
  bossName: string
  bossStatus: 'locked'|'available'|'defeated'
  pins: RegionPinDto[]       // up to 2 chips to show on banner
}
```

On Region screen tap:

```
GET /api/map/region/{id}
```

```ts
RegionDetailDto extends RegionSummaryDto {
  nodes: ZoneNodeDto[]                 // ordered along the path
  edges: { fromId: int, toId: int }[]  // path connections, includes crossroads branches
}

ZoneNodeDto {
  id: int
  name: string
  emoji: string
  tier: int
  status: 'completed'|'active'|'next'|'available'|'locked'
  isCrossroads: bool
  isBoss: bool
  description: string
  levelRequirement: int
  distanceKm: float
  xpReward: int
  nodesCompleted: int?
  nodesTotal: int?
  loreCollected: int?
  loreTotal: int?
}
```

Zone sheet is a client-side composition of `ZoneNodeDto + activeJourney + user.level`. No additional endpoint needed for tapping a zone.

---

## 13. Flutter File Plan (follow-up task)

Replaces existing files under `mobile/lib/features/map/`.

| New file | Role | Replaces |
|---|---|---|
| `world_map_screen.dart` (rewritten) | World-level scaffold | current `world_map_screen.dart` |
| `region_detail_screen.dart` (new) | Region drill-down | — |
| `widgets/region_card.dart` | Region hero card | — |
| `widgets/active_journey_strip.dart` | Shared journey strip | portion of `world_map_screen.dart` |
| `widgets/node_trail.dart` | Vertical path column | `world_map_painter.dart` |
| `widgets/node_bubble.dart` | Single node circle/diamond | from painter |
| `widgets/curve_connector.dart` | Per-row SVG curve | from painter |
| `widgets/journey_progress_footer.dart` | Under-trail footer | — |
| `zone_sheet.dart` (rewritten) | Single adaptive sheet | `world_map_detail_sheet.dart` (617 lines → target ~200) |
| `models/region_model.dart` | `RegionSummaryDto`, `RegionDetailDto` | — |
| `models/zone_node_model.dart` | `ZoneNodeDto` | existing `world_map_models.dart` fields carried over |
| `services/world_map_service.dart` | API client | existing `WorldZoneService` rewritten |

Painter (`world_map_painter.dart`) is deleted. All drawing moves to small `CustomPaint` widgets scoped to single rows.

---

## 14. Out of Scope (documented, deliberately deferred)

- **Gamification layers** (ticker, live event banners, avatar walking on trail, chests between nodes, reward ladder, world-boss card) — see `world-map-v4-living.html` and `world-map-v5-flow.html` as reference for later iterations.
- **Path choice flow** (crossroads decision modal) — existing design at `design-mockup/crossroads-flow.html`.
- **Boss fight screen** — existing design at `design-mockup/boss-fight-flow.html`.
- **Guild raid co-op UI** — phased under Phase 4 of `CLAUDE.md` roadmap.
- **Seasonal event overlay / skin** — Phase 7.

---

## 15. Acceptance Checklist (for implementation)

- [ ] World screen renders all unlocked + locked regions in one scroll.
- [ ] Active journey strip appears iff `activeJourney != null`, tap routes to destination region.
- [ ] Each region card uses the correct theme gradient and banner pins.
- [ ] Region screen renders banner, 3 summary tiles, and a vertical node trail with correct node states.
- [ ] Trail curves connect nodes with the state-based color rules in §5.2.4.
- [ ] Crossroads nodes render as diamond (rotated 45°) and show two outgoing branches.
- [ ] Boss nodes render at the bottom of the region with pulsing red glow.
- [ ] Journey progress footer appears only when the active journey's destination is in the current region.
- [ ] Zone sheet opens on node tap, renders the correct state (Available / Traveling-to / Traveling-from / Crossroads / Locked / Completed).
- [ ] Sheet has single primary CTA; no branching layouts.
- [ ] Back button on Region banner pops to World.
- [ ] All tokens match `design-mockup/home/home-v3.html`.

---

## 16. Reference Mockups

- `design-mockup/map/world-map-v3-world.html` — World screen reference (Screen 1)
- `design-mockup/map/world-map-v3-region.html` — Region screen reference (Screen 2)
- `design-mockup/map/world-map-v3-path.html` — Vertical path pattern reference (embedded inside Region screen)
- `design-mockup/map/zone-sheet-v3.html` — Zone sheet states reference (component)
- `design-mockup/home/home-v3.html` — Shared design tokens + header/card conventions

This spec supersedes all earlier map mockups (`adventure-map.html`, `adventure-map-detailed.html`, `world-map.html`, `world-map-nested-travel.html`, etc.) as the source of truth for the Flutter port.
