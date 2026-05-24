using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Items.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace LifeLevel.Api.Controllers.Admin;

[ApiController]
[Route("api/admin/level-unlocks")]
[Authorize(Policy = "Admin")]
public class AdminLevelUnlocksController(AppDbContext db) : ControllerBase
{
    private const int MaxLevel = 50;

    // GET /api/admin/level-unlocks
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var zones = await db.WorldZones
            .Include(z => z.Region)
            .Select(z => new { z.Id, z.Name, z.LevelRequirement, RegionName = z.Region.Name })
            .OrderBy(z => z.Name)
            .ToListAsync();

        var rules = await db.ItemDropRules
            .Where(r => r.TriggerType == AcquisitionTrigger.LevelReached)
            .Include(r => r.Item)
            .Select(r => new { r.Id, r.ItemId, ItemName = r.Item.Name, ItemIcon = r.Item.Icon, r.DropChancePct, r.IsEnabled, r.TriggerParameters })
            .ToListAsync();

        var allItems = await db.Items
            .Select(i => new { i.Id, i.Name, i.Icon, Rarity = i.Rarity.ToString() })
            .OrderBy(i => i.Name)
            .ToListAsync();

        var parsedRules = rules.Select(r =>
        {
            int level = 1;
            try
            {
                var doc = JsonDocument.Parse(r.TriggerParameters ?? "{}");
                if (doc.RootElement.TryGetProperty("level", out var lv))
                    level = lv.GetInt32();
            }
            catch { }
            return new { r.Id, r.ItemId, r.ItemName, r.ItemIcon, r.DropChancePct, r.IsEnabled, Level = level };
        }).ToList();

        var levels = Enumerable.Range(1, MaxLevel).ToDictionary(
            l => l,
            l => (object)new
            {
                zones = zones.Where(z => z.LevelRequirement == l).Select(z => new { z.Id, z.Name, z.RegionName }).ToList(),
                items = parsedRules.Where(r => r.Level == l).Select(r => new { r.Id, r.ItemId, r.ItemName, r.ItemIcon, r.DropChancePct, r.IsEnabled }).ToList(),
            });

        return Ok(new { maxLevel = MaxLevel, levels, allItems, allZones = zones });
    }

    // PATCH /api/admin/level-unlocks/zones/{zoneId}
    [HttpPatch("zones/{zoneId:guid}")]
    public async Task<IActionResult> SetZoneLevelRequirement(Guid zoneId, [FromBody] SetZoneLevelRequest req)
    {
        if (req.LevelRequirement < 1 || req.LevelRequirement > MaxLevel)
            return BadRequest($"Level must be between 1 and {MaxLevel}.");
        var zone = await db.WorldZones.FindAsync(zoneId);
        if (zone == null) return NotFound();
        zone.LevelRequirement = req.LevelRequirement;
        await db.SaveChangesAsync();
        return Ok();
    }

    // POST /api/admin/level-unlocks/item-rewards
    [HttpPost("item-rewards")]
    public async Task<IActionResult> AddItemReward([FromBody] AddItemRewardRequest req)
    {
        if (req.Level < 1 || req.Level > MaxLevel)
            return BadRequest($"Level must be between 1 and {MaxLevel}.");
        if (!await db.Items.AnyAsync(i => i.Id == req.ItemId))
            return NotFound("Item not found.");
        var rule = new ItemDropRule
        {
            Id = Guid.NewGuid(),
            ItemId = req.ItemId,
            TriggerType = AcquisitionTrigger.LevelReached,
            TriggerParameters = $"{{\"level\":{req.Level}}}",
            DropChancePct = 100,
            IsEnabled = true
        };
        db.ItemDropRules.Add(rule);
        await db.SaveChangesAsync();
        return Ok(new { rule.Id });
    }

    // DELETE /api/admin/level-unlocks/item-rewards/{ruleId}
    [HttpDelete("item-rewards/{ruleId:guid}")]
    public async Task<IActionResult> RemoveItemReward(Guid ruleId)
    {
        var rule = await db.ItemDropRules.FindAsync(ruleId);
        if (rule == null) return NotFound();
        if (rule.TriggerType != AcquisitionTrigger.LevelReached)
            return BadRequest("Rule is not a level reward.");
        db.ItemDropRules.Remove(rule);
        await db.SaveChangesAsync();
        return Ok();
    }
}

public record SetZoneLevelRequest(int LevelRequirement);
public record AddItemRewardRequest(Guid ItemId, int Level);
