using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Talents.Domain.Entities;
using LifeLevel.Modules.Talents.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Controllers.Admin;

[ApiController]
[Route("api/admin/talents")]
[Authorize(Policy = "Admin")]
public class AdminTalentsController(AppDbContext db) : ControllerBase
{
    // GET /api/admin/talents
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var talents = await db.Set<Talent>().OrderBy(t => t.SortOrder).ToListAsync();
        var holders = await db.Set<UserTalent>()
            .GroupBy(x => x.TalentId)
            .Select(g => new { TalentId = g.Key, Owners = g.Count(), Levels = g.Sum(x => x.Level) })
            .ToListAsync();

        return Ok(talents.Select(t => new
        {
            t.Id, t.Key, t.Name, t.Description, t.IconKey,
            Rarity = t.Rarity.ToString(),
            EffectType = t.EffectType.ToString(),
            t.PerLevelValue, t.MaxLevel, t.DrawWeight, t.SortOrder, t.IsActive,
            Owners = holders.FirstOrDefault(h => h.TalentId == t.Id)?.Owners ?? 0,
            LevelsOwned = holders.FirstOrDefault(h => h.TalentId == t.Id)?.Levels ?? 0,
        }));
    }

    // POST /api/admin/talents
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] UpsertTalentRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Key)) return BadRequest("Key is required.");
        if (!Enum.TryParse<TalentRarity>(req.Rarity, true, out var rarity))
            return BadRequest("Invalid Rarity.");
        if (!Enum.TryParse<TalentEffectType>(req.EffectType, true, out var effect))
            return BadRequest("Invalid EffectType.");
        if (await db.Set<Talent>().AnyAsync(t => t.Key == req.Key.Trim()))
            return Conflict("A talent with that key already exists.");

        var talent = new Talent
        {
            Id = Guid.NewGuid(),
            Key = req.Key.Trim(),
            Name = req.Name?.Trim() ?? req.Key.Trim(),
            Description = req.Description?.Trim() ?? string.Empty,
            IconKey = req.IconKey?.Trim() ?? string.Empty,
            Rarity = rarity,
            EffectType = effect,
            PerLevelValue = req.PerLevelValue,
            MaxLevel = req.MaxLevel > 0 ? req.MaxLevel : 10,
            DrawWeight = req.DrawWeight > 0 ? req.DrawWeight : 100,
            SortOrder = req.SortOrder,
            IsActive = req.IsActive,
        };
        db.Add(talent);
        await db.SaveChangesAsync();
        return Ok(new { talent.Id, talent.Key });
    }

    // PUT /api/admin/talents/{id}
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpsertTalentRequest req)
    {
        var talent = await db.Set<Talent>().FindAsync(id);
        if (talent == null) return NotFound();

        if (!string.IsNullOrWhiteSpace(req.Rarity) &&
            Enum.TryParse<TalentRarity>(req.Rarity, true, out var rarity))
            talent.Rarity = rarity;
        if (!string.IsNullOrWhiteSpace(req.EffectType) &&
            Enum.TryParse<TalentEffectType>(req.EffectType, true, out var effect))
            talent.EffectType = effect;

        if (!string.IsNullOrWhiteSpace(req.Name)) talent.Name = req.Name.Trim();
        if (req.Description != null) talent.Description = req.Description.Trim();
        if (req.IconKey != null) talent.IconKey = req.IconKey.Trim();
        if (req.PerLevelValue != 0) talent.PerLevelValue = req.PerLevelValue;
        if (req.MaxLevel > 0) talent.MaxLevel = req.MaxLevel;
        if (req.DrawWeight > 0) talent.DrawWeight = req.DrawWeight;
        talent.SortOrder = req.SortOrder;
        talent.IsActive = req.IsActive;
        await db.SaveChangesAsync();
        return Ok();
    }

    // DELETE /api/admin/talents/{id}
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var talent = await db.Set<Talent>().FindAsync(id);
        if (talent == null) return NotFound();
        await db.Set<UserTalent>().Where(x => x.TalentId == id).ExecuteDeleteAsync();
        db.Remove(talent);
        await db.SaveChangesAsync();
        return Ok();
    }

    // POST /api/admin/talents/grant  — top up a tester
    [HttpPost("grant")]
    public async Task<IActionResult> Grant([FromBody] TalentGrantRequest req)
    {
        var userId = await ResolveUserAsync(req.UserIdOrEmail);
        if (userId == null) return BadRequest($"No user for '{req.UserIdOrEmail}'.");

        var wallet = await db.Set<UserTalentWallet>().FirstOrDefaultAsync(w => w.UserId == userId);
        if (wallet == null)
        {
            wallet = new UserTalentWallet { Id = Guid.NewGuid(), UserId = userId.Value };
            db.Add(wallet);
        }
        wallet.Coins += Math.Max(0, req.Coins);
        wallet.Crystals += Math.Max(0, req.Crystals);
        wallet.UpdatedAt = DateTime.UtcNow;

        if (!string.IsNullOrWhiteSpace(req.TalentKey))
        {
            var talent = await db.Set<Talent>().FirstOrDefaultAsync(t => t.Key == req.TalentKey!.Trim());
            if (talent == null) return BadRequest($"Unknown talent key '{req.TalentKey}'.");
            var ut = await db.Set<UserTalent>()
                .FirstOrDefaultAsync(x => x.UserId == userId && x.TalentId == talent.Id);
            if (ut == null)
            {
                ut = new UserTalent
                {
                    Id = Guid.NewGuid(),
                    UserId = userId.Value,
                    TalentId = talent.Id,
                    Level = 1,
                    UnlockedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                };
                db.Add(ut);
            }
            ut.UpdatedAt = DateTime.UtcNow;
        }

        await db.SaveChangesAsync();
        return Ok(new { userId, wallet.Coins, wallet.Crystals });
    }

    // POST /api/admin/talents/reset  — wipe a tester's talents + wallet
    [HttpPost("reset")]
    public async Task<IActionResult> Reset([FromBody] TalentGrantRequest req)
    {
        var userId = await ResolveUserAsync(req.UserIdOrEmail);
        if (userId == null) return BadRequest($"No user for '{req.UserIdOrEmail}'.");

        await db.Set<UserTalent>().Where(x => x.UserId == userId).ExecuteDeleteAsync();
        await db.Set<UserTalentWallet>().Where(w => w.UserId == userId).ExecuteDeleteAsync();
        await db.Set<TalentDrawEntry>().Where(e => e.UserId == userId).ExecuteDeleteAsync();
        return Ok(new { userId });
    }

    private async Task<Guid?> ResolveUserAsync(string? userIdOrEmail)
    {
        if (string.IsNullOrWhiteSpace(userIdOrEmail)) return null;
        if (Guid.TryParse(userIdOrEmail, out var parsed)) return parsed;

        var key = userIdOrEmail.Trim();
        return await db.Users
            .Where(u => u.Email == key || u.Username == key)
            .Select(u => (Guid?)u.Id)
            .FirstOrDefaultAsync();
    }
}

public record UpsertTalentRequest(
    string Key, string? Name, string? Description, string? IconKey,
    string Rarity, string EffectType, double PerLevelValue,
    int MaxLevel, int DrawWeight, int SortOrder, bool IsActive);

public record TalentGrantRequest(string? UserIdOrEmail, int Coins, int Crystals, string? TalentKey);
