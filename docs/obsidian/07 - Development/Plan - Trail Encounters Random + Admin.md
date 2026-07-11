# Plan: Random Trail Encounters + Admin Management

## Context

Phase 1 (done) implemented the Flutter UI for trail encounters — story/merchant/blocker nodes pulsing on the `ZoneTrail`, three bottom sheets, mock data injected in debug mode.

Phase 2 (this plan) replaces the hardcoded mock with **real backend data**: a `TrailEncounterTemplate` table, random selection in `MapReadService`, and a new admin panel page for configuring templates per region.

---

## Architecture

```
Admin creates templates (per region, per type, with spawn chance)
         ↓
RegionDetail API randomly samples templates → includes encounters[] in response
         ↓
Flutter renders whatever encounters the API returns (already supported by TrailEncounterNode.fromJson)
```

---

## Files to Create (3)

| File | Purpose |
|------|---------|
| `backend/src/modules/LifeLevel.Modules.WorldZone/Domain/Entities/TrailEncounterTemplate.cs` | EF entity |
| `backend/src/LifeLevel.Api/Controllers/Admin/AdminEncountersController.cs` | Admin CRUD API |
| `backend/src/LifeLevel.Api/wwwroot/admin/encounters.html` | Web admin page |

## Files to Modify (7)

| File | Change |
|------|--------|
| `backend/src/LifeLevel.Api/Infrastructure/Persistence/AppDbContext.cs` | Add `TrailEncounterTemplates` DbSet |
| `backend/src/modules/LifeLevel.Modules.WorldZone/Application/DTOs/WorldMapDtos.cs` | Add encounter DTOs + add `Encounters` to `RegionDetailDto` |
| `backend/src/modules/LifeLevel.Modules.WorldZone/Application/UseCases/MapReadService.cs` | Load templates, randomly select encounters, include in response |
| `backend/src/LifeLevel.Api/wwwroot/admin/*.html` (map, index, level-unlocks, rank-thresholds) | Add `🎲 Encounters` nav link |
| `mobile/lib/core/api/api_client.dart` | Add `adminEncountersUrl` |
| `mobile/lib/features/profile/tabs/admin_tab.dart` | Add Encounters card |
| `mobile/lib/features/map/screens/region_detail_screen.dart` | Remove `_buildMockEncounters()` + debug injection |

---

## Step 1 — Backend Entity

**`TrailEncounterTemplate.cs`:**
```csharp
public class TrailEncounterTemplate
{
    public Guid Id { get; set; }
    public Guid RegionId { get; set; }
    public Region Region { get; set; } = null!;
    public string Type { get; set; } = "";       // "story" | "merchant" | "blocker"
    public string Name { get; set; } = "";
    public string Emoji { get; set; } = "";
    public double SpawnChance { get; set; } = 0.5;
    public bool IsActive { get; set; } = true;
    public string ConfigJson { get; set; } = "{}";
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
```

**ConfigJson payloads per type:**
```jsonc
// merchant
{ "timeLeftHours": 14, "playerXp": 2450,
  "items": [{"emoji":"🛡","name":"Iron Bulwark","description":"+18 STR","rarity":"rare","xpCost":950}] }

// blocker
{ "maxHp": 5000, "retreatDays": 2,
  "rewards": ["+800 XP", "🛡 Rare Item", "Journey unblocked"] }

// story
{ "npcTitle": "Keeper of the Forest Paths", "portrait": "🧙",
  "dialogue": "Traveller — ...", "loreXp": 50 }
```

EF config: cascade delete on RegionId FK. Run `dotnet ef migrations add AddTrailEncounterTemplates` from `LifeLevel.Api/`.

---

## Step 2 — New DTOs (`WorldMapDtos.cs`)

```csharp
public record TrailEncounterNodeDto(
    string Id, string FromZoneId, string ToZoneId,
    double T, double SideOffset, string Type,
    MerchantEncounterDto? Merchant,
    BlockerEncounterDto? Blocker,
    StoryEncounterDto? Story);

public record MerchantEncounterDto(string Name, int TimeLeftSeconds, int PlayerXp, IReadOnlyList<MerchantItemDto> Items);
public record MerchantItemDto(string Emoji, string Name, string Description, string Rarity, int XpCost);
public record BlockerEncounterDto(string Name, string BlockedZoneName, int MaxHp, int CurrentHp, int PlayerDamageDone, int RetreatsInSeconds, IReadOnlyList<string> Rewards);
public record StoryEncounterDto(string NpcName, string NpcTitle, string Portrait, string Dialogue, int LoreXp);
```

Add `IReadOnlyList<TrailEncounterNodeDto> Encounters` as last param to `RegionDetailDto`.

---

## Step 3 — `MapReadService` Random Selection

At the end of `GetRegionDetailAsync`, before the `return`:

```csharp
var templates = await db.Set<TrailEncounterTemplate>()
    .Where(t => t.RegionId == regionId && t.IsActive)
    .ToListAsync(ct);

var encounters = new List<TrailEncounterNodeDto>();
if (templates.Count > 0 && edgeDtos.Count > 0)
{
    var rng = new Random();
    var usedTypes = new HashSet<string>();
    foreach (var edge in edgeDtos.OrderBy(_ => rng.Next()))
    {
        if (encounters.Count >= 3) break;
        var candidate = templates
            .Where(t => !usedTypes.Contains(t.Type))
            .OrderBy(_ => rng.Next())
            .FirstOrDefault(t => rng.NextDouble() < t.SpawnChance);
        if (candidate == null) continue;
        var t = 0.25 + rng.NextDouble() * 0.50;
        var side = encounters.Count % 2 == 0 ? -80.0 : 80.0;
        encounters.Add(BuildEncounterNode(candidate, edge.FromZoneId, edge.ToZoneId, t, side));
        usedTypes.Add(candidate.Type);
    }
}
```

`BuildEncounterNode` private helper parses `ConfigJson` via `System.Text.Json` and constructs the appropriate sub-DTO. Blocker always starts with `CurrentHp = MaxHp`, `PlayerDamageDone = 0`.

---

## Step 4 — `AdminEncountersController`

Route: `api/admin/encounters` · Auth: `[Authorize(Policy = "Admin")]`

- `GET ?regionId=X` — list templates for region
- `GET {id}` — full detail incl. ConfigJson
- `POST` — create
- `PUT {id}` — update
- `DELETE {id}` — delete

---

## Step 5 — `encounters.html` Admin Page

Same CSS/nav style as `map.html`. Layout:
- **Region dropdown** — loads from `GET /api/admin/worlds`
- **Template table** — Type badge, Emoji, Name, Spawn %, Active, Edit/Delete
- **Add/Edit modal** — Type select, Name, Emoji, SpawnChance (0–100%), IsActive, ConfigJson textarea with placeholder per type

Add `🎲 Encounters` nav link to all 4 existing HTML files.

---

## Step 6 — Flutter Admin

**`api_client.dart`:**
```dart
static Future<String> get adminEncountersUrl async {
  final token = await _storage.read(key: 'jwt_token');
  final base = '$_webBase/admin/encounters.html';
  return token != null ? '$base?token=${Uri.encodeComponent(token)}' : base;
}
```

**`admin_tab.dart`** — add below the Map card:
```dart
const SizedBox(height: 20),
const Text('Encounters', style: TextStyle(fontSize:13, fontWeight:FontWeight.w700, color:_kTextSec)),
const SizedBox(height: 10),
_AdminMenuCard(
  icon: '🎲',
  accentColor: _kPurple,
  title: 'Trail Encounters',
  subtitle: 'Configure random encounter templates per region',
  onTap: () => _openUrl(ApiClient.adminEncountersUrl),
),
```

---

## Step 7 — Flutter Cleanup

In `region_detail_screen.dart`:
- Remove `import 'package:flutter/foundation.dart'` (if only used for kDebugMode)
- Remove `if (kDebugMode && region.encounters.isEmpty)` block
- Remove `_buildMockEncounters()` method

---

## Verification

1. No templates → no encounters on trail ✓
2. Add merchant template (SpawnChance=1.0) → merchant node appears on random edge ✓
3. All 3 types → 3 nodes on different edges each reload ✓
4. SpawnChance=0.0 or IsActive=false → never spawns ✓
5. Admin Flutter card opens encounters.html ✓
6. `flutter analyze` clean ✓
