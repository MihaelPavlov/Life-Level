using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Character.Domain.Entities;
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
            .ToListAsync();

        var rules = await db.ItemDropRules
            .Where(r => r.TriggerType == AcquisitionTrigger.LevelReached)
            .Include(r => r.Item)
            .Select(r => new { r.Id, r.ItemId, ItemName = r.Item.Name, ItemIcon = r.Item.Icon, r.DropChancePct, r.IsEnabled, r.TriggerParameters })
            .ToListAsync();

        var titleGrants = await db.LevelTitleGrants
            .Include(g => g.Title)
            .Select(g => new { g.Id, g.Level, g.TitleId, TitleName = g.Title.Name, TitleEmoji = g.Title.Emoji })
            .ToListAsync();

        var statBonuses = await db.LevelStatBonuses
            .Select(b => new { b.Level, b.BonusPoints })
            .ToListAsync();

        var allItems = await db.Items
            .Select(i => new { i.Id, i.Name, i.Icon, Rarity = i.Rarity.ToString() })
            .OrderBy(i => i.Name)
            .ToListAsync();

        var allTitles = await db.Titles
            .OrderBy(t => t.SortOrder)
            .Select(t => new { t.Id, t.Emoji, t.Name })
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

        var statBonusLookup = statBonuses.ToDictionary(b => b.Level, b => b.BonusPoints);

        var levels = Enumerable.Range(1, MaxLevel).ToDictionary(
            l => l,
            l => (object)new
            {
                zones    = zones.Where(z => z.LevelRequirement == l).Select(z => new { z.Id, z.Name, z.RegionName }).ToList(),
                items    = parsedRules.Where(r => r.Level == l).Select(r => new { r.Id, r.ItemId, r.ItemName, r.ItemIcon, r.DropChancePct, r.IsEnabled }).ToList(),
                titles   = titleGrants.Where(g => g.Level == l).Select(g => new { g.Id, g.TitleId, g.TitleName, g.TitleEmoji }).ToList(),
                statBonus = statBonusLookup.GetValueOrDefault(l, 0),
            });

        return Ok(new { maxLevel = MaxLevel, levels, allItems, allTitles });
    }

    // ── Item rewards ─────────────────────────────────────────────────────────

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

    // ── Title grants ─────────────────────────────────────────────────────────

    // POST /api/admin/level-unlocks/title-grants
    [HttpPost("title-grants")]
    public async Task<IActionResult> AddTitleGrant([FromBody] AddTitleGrantRequest req)
    {
        if (req.Level < 1 || req.Level > MaxLevel)
            return BadRequest($"Level must be between 1 and {MaxLevel}.");
        if (!await db.Titles.AnyAsync(t => t.Id == req.TitleId))
            return NotFound("Title not found.");
        if (await db.LevelTitleGrants.AnyAsync(g => g.Level == req.Level && g.TitleId == req.TitleId))
            return Conflict("This title is already granted at that level.");
        var grant = new LevelTitleGrant { Id = Guid.NewGuid(), Level = req.Level, TitleId = req.TitleId };
        db.LevelTitleGrants.Add(grant);
        await db.SaveChangesAsync();
        return Ok(new { grant.Id });
    }

    // DELETE /api/admin/level-unlocks/title-grants/{id}
    [HttpDelete("title-grants/{id:guid}")]
    public async Task<IActionResult> RemoveTitleGrant(Guid id)
    {
        var grant = await db.LevelTitleGrants.FindAsync(id);
        if (grant == null) return NotFound();
        db.LevelTitleGrants.Remove(grant);
        await db.SaveChangesAsync();
        return Ok();
    }

    // ── Stat bonuses ─────────────────────────────────────────────────────────

    // PUT /api/admin/level-unlocks/stat-bonuses/{level}
    [HttpPut("stat-bonuses/{level:int}")]
    public async Task<IActionResult> UpsertStatBonus(int level, [FromBody] UpsertStatBonusRequest req)
    {
        if (level < 1 || level > MaxLevel)
            return BadRequest($"Level must be between 1 and {MaxLevel}.");

        var existing = await db.LevelStatBonuses.FirstOrDefaultAsync(b => b.Level == level);
        if (req.BonusPoints <= 0)
        {
            if (existing != null) { db.LevelStatBonuses.Remove(existing); await db.SaveChangesAsync(); }
            return Ok();
        }
        if (existing != null)
            existing.BonusPoints = req.BonusPoints;
        else
            db.LevelStatBonuses.Add(new LevelStatBonus { Id = Guid.NewGuid(), Level = level, BonusPoints = req.BonusPoints });
        await db.SaveChangesAsync();
        return Ok();
    }
}

public record AddItemRewardRequest(Guid ItemId, int Level);
public record AddTitleGrantRequest(Guid TitleId, int Level);
public record UpsertStatBonusRequest(int BonusPoints);
