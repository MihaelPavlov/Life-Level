using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Seasons.Domain;
using LifeLevel.Modules.Seasons.Domain.Entities;
using LifeLevel.Modules.Seasons.Domain.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Controllers.Admin;

[ApiController]
[Route("api/admin/seasons")]
[Authorize(Policy = "Admin")]
public class AdminSeasonsController(AppDbContext db, ISeasonRolloverPort rollover) : ControllerBase
{
    // GET /api/admin/seasons
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var seasons = await db.Set<Season>().OrderBy(s => s.Number).ToListAsync();
        var tiers = await db.Set<SeasonRewardTier>().ToListAsync();

        return Ok(seasons.Select(s => new
        {
            s.Id, s.Number, s.Name, s.Theme,
            State = s.State.ToString(),
            s.StartsAt, s.EndsAt, s.XpPerTier, s.TierCount, s.MilestoneTier,
            Tiers = tiers.Where(t => t.SeasonId == s.Id)
                .OrderBy(t => t.Tier).ThenBy(t => t.Track)
                .Select(t => new
                {
                    t.Id, t.Tier,
                    Track = t.Track.ToString(),
                    RewardType = t.RewardType.ToString(),
                    t.RewardRefId, t.RewardKey, t.Amount, t.Label, t.IconKey, t.Rarity,
                })
        }));
    }

    // POST /api/admin/seasons
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] UpsertSeasonRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Name)) return BadRequest("Name is required.");
        if (req.EndsAt <= req.StartsAt) return BadRequest("EndsAt must be after StartsAt.");

        var season = new Season
        {
            Id = Guid.NewGuid(),
            Number = req.Number,
            Name = req.Name.Trim(),
            Theme = string.IsNullOrWhiteSpace(req.Theme) ? "ember" : req.Theme.Trim(),
            StartsAt = req.StartsAt,
            EndsAt = req.EndsAt,
            State = SeasonState.Scheduled,
            XpPerTier = req.XpPerTier > 0 ? req.XpPerTier : 600,
            TierCount = req.TierCount > 0 ? req.TierCount : 25,
            MilestoneTier = req.MilestoneTier > 0 ? req.MilestoneTier : req.TierCount,
        };
        db.Add(season);
        await db.SaveChangesAsync();
        return Ok(new { season.Id, season.Number, season.Name });
    }

    // PUT /api/admin/seasons/{id}
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpsertSeasonRequest req)
    {
        var season = await db.Set<Season>().FindAsync(id);
        if (season == null) return NotFound();

        season.Number = req.Number;
        season.Name = string.IsNullOrWhiteSpace(req.Name) ? season.Name : req.Name.Trim();
        season.Theme = string.IsNullOrWhiteSpace(req.Theme) ? season.Theme : req.Theme.Trim();
        season.StartsAt = req.StartsAt;
        season.EndsAt = req.EndsAt;
        if (req.XpPerTier > 0) season.XpPerTier = req.XpPerTier;
        if (req.TierCount > 0) season.TierCount = req.TierCount;
        if (req.MilestoneTier > 0) season.MilestoneTier = req.MilestoneTier;
        await db.SaveChangesAsync();
        return Ok();
    }

    // PUT /api/admin/seasons/{id}/tiers/{tier}/{track}
    [HttpPut("{id:guid}/tiers/{tier:int}/{track}")]
    public async Task<IActionResult> UpsertTier(Guid id, int tier, string track, [FromBody] UpsertTierRequest req)
    {
        if (!Enum.TryParse<SeasonTrack>(track, ignoreCase: true, out var lane))
            return BadRequest("Track must be 'Free' or 'Founder'.");
        if (!Enum.TryParse<SeasonRewardType>(req.RewardType, ignoreCase: true, out var type))
            return BadRequest("Invalid RewardType.");

        var season = await db.Set<Season>().FindAsync(id);
        if (season == null) return NotFound();

        var row = await db.Set<SeasonRewardTier>()
            .FirstOrDefaultAsync(t => t.SeasonId == id && t.Tier == tier && t.Track == lane);
        if (row == null)
        {
            row = new SeasonRewardTier { Id = Guid.NewGuid(), SeasonId = id, Tier = tier, Track = lane };
            db.Add(row);
        }

        row.RewardType = type;
        row.RewardRefId = req.RewardRefId;
        row.RewardKey = string.IsNullOrWhiteSpace(req.RewardKey) ? null : req.RewardKey.Trim();
        row.Amount = req.Amount;
        row.Label = req.Label?.Trim() ?? string.Empty;
        row.IconKey = req.IconKey?.Trim() ?? string.Empty;
        row.Rarity = string.IsNullOrWhiteSpace(req.Rarity) ? null : req.Rarity.Trim();
        await db.SaveChangesAsync();
        return Ok(new { row.Id });
    }

    // POST /api/admin/seasons/{id}/activate
    [HttpPost("{id:guid}/activate")]
    public async Task<IActionResult> Activate(Guid id)
    {
        var season = await db.Set<Season>().FindAsync(id);
        if (season == null) return NotFound();

        var others = await db.Set<Season>().Where(s => s.Id != id && s.State == SeasonState.Active).ToListAsync();
        foreach (var s in others) s.State = SeasonState.Ended;
        season.State = SeasonState.Active;
        await db.SaveChangesAsync();
        return Ok();
    }

    // POST /api/admin/seasons/{id}/restart  — hard reset for closed testing
    [HttpPost("{id:guid}/restart")]
    public async Task<IActionResult> Restart(Guid id)
    {
        var season = await db.Set<Season>().FindAsync(id);
        if (season == null) return NotFound();

        var duration = season.EndsAt - season.StartsAt;
        if (duration <= TimeSpan.Zero) duration = TimeSpan.FromDays(SeasonOneCatalog.DurationDays);

        season.StartsAt = DateTime.UtcNow;
        season.EndsAt = DateTime.UtcNow + duration;

        var others = await db.Set<Season>().Where(s => s.Id != id && s.State == SeasonState.Active).ToListAsync();
        foreach (var s in others) s.State = SeasonState.Ended;
        season.State = SeasonState.Active;

        await db.Set<UserSeasonClaim>().Where(c => c.SeasonId == id).ExecuteDeleteAsync();
        await db.Set<UserSeasonProgress>().Where(p => p.SeasonId == id).ExecuteDeleteAsync();
        await db.Set<UserFounderPass>().Where(p => p.SeasonId == id).ExecuteDeleteAsync();
        await db.SaveChangesAsync();
        return Ok(new { season.Id, season.StartsAt, season.EndsAt });
    }

    // POST /api/admin/seasons/rollover  — force the rollover job to run now
    [HttpPost("rollover")]
    public async Task<IActionResult> RunRollover()
        => Ok(new { closed = await rollover.RolloverDueSeasonsAsync() });

    // POST /api/admin/seasons/pass/grant
    [HttpPost("pass/grant")]
    public async Task<IActionResult> GrantPass([FromBody] PassGrantRequest req)
    {
        var (userId, season, err) = await ResolveAsync(req.UserIdOrEmail);
        if (err != null) return BadRequest(err);

        var exists = await db.Set<UserFounderPass>().AnyAsync(p => p.UserId == userId && p.SeasonId == season!.Id);
        if (!exists)
        {
            db.Add(new UserFounderPass
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                SeasonId = season!.Id,
                AcquiredAt = DateTime.UtcNow,
                Source = FounderPassSource.AdminGrant,
            });
            await db.SaveChangesAsync();
        }
        return Ok(new { userId, seasonId = season!.Id });
    }

    // POST /api/admin/seasons/pass/revoke
    [HttpPost("pass/revoke")]
    public async Task<IActionResult> RevokePass([FromBody] PassGrantRequest req)
    {
        var (userId, season, err) = await ResolveAsync(req.UserIdOrEmail);
        if (err != null) return BadRequest(err);

        await db.Set<UserFounderPass>()
            .Where(p => p.UserId == userId && p.SeasonId == season!.Id)
            .ExecuteDeleteAsync();
        return Ok(new { userId, seasonId = season!.Id });
    }

    private async Task<(Guid userId, Season? season, string? err)> ResolveAsync(string? userIdOrEmail)
    {
        if (string.IsNullOrWhiteSpace(userIdOrEmail))
            return (default, null, "userIdOrEmail is required.");

        Guid userId;
        if (Guid.TryParse(userIdOrEmail, out var parsed))
            userId = parsed;
        else
        {
            var email = userIdOrEmail.Trim();
            var match = await db.Users
                .Where(u => u.Email == email || u.Username == email)
                .Select(u => (Guid?)u.Id)
                .FirstOrDefaultAsync();
            if (match == null) return (default, null, $"No user for '{userIdOrEmail}'.");
            userId = match.Value;
        }

        var season = await db.Set<Season>().FirstOrDefaultAsync(s => s.State == SeasonState.Active);
        if (season == null) return (userId, null, "No active season.");
        return (userId, season, null);
    }
}

public record UpsertSeasonRequest(
    int Number, string Name, string? Theme,
    DateTime StartsAt, DateTime EndsAt,
    int XpPerTier, int TierCount, int MilestoneTier);

public record UpsertTierRequest(
    string RewardType, Guid? RewardRefId, string? RewardKey,
    int Amount, string? Label, string? IconKey, string? Rarity);

public record PassGrantRequest(string? UserIdOrEmail);
