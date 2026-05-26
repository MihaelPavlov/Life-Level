using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Character.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Controllers.Admin;

[ApiController]
[Route("api/admin/rank-thresholds")]
[Authorize(Policy = "Admin")]
public class AdminRankThresholdsController(AppDbContext db) : ControllerBase
{
    // GET /api/admin/rank-thresholds
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var rows = await db.RankThresholds
            .OrderBy(r => r.BossesRequired)
            .ToListAsync();
        return Ok(rows.Select(r => new
        {
            r.Id, r.Rank, r.DisplayName, r.Description, r.BossesRequired
        }));
    }

    // PUT /api/admin/rank-thresholds/{id}
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpsertRankRequest req)
    {
        if (req.BossesRequired < 0)
            return BadRequest("BossesRequired must be >= 0.");
        var threshold = await db.RankThresholds.FindAsync(id);
        if (threshold == null) return NotFound();
        threshold.DisplayName = req.DisplayName?.Trim() ?? threshold.DisplayName;
        threshold.Description = req.Description?.Trim() ?? threshold.Description;
        threshold.BossesRequired = req.BossesRequired;
        await db.SaveChangesAsync();
        return Ok();
    }

    // POST /api/admin/rank-thresholds
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] UpsertRankRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.DisplayName))
            return BadRequest("DisplayName is required.");
        if (req.BossesRequired < 0)
            return BadRequest("BossesRequired must be >= 0.");

        var key = "Custom_" + Guid.NewGuid().ToString("N")[..8];
        var threshold = new RankThreshold
        {
            Id = Guid.NewGuid(),
            Rank = key,
            DisplayName = req.DisplayName.Trim(),
            Description = req.Description?.Trim() ?? string.Empty,
            BossesRequired = req.BossesRequired,
        };
        db.RankThresholds.Add(threshold);
        await db.SaveChangesAsync();
        return Ok(new { threshold.Id, threshold.Rank });
    }

    // DELETE /api/admin/rank-thresholds/{id}
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var threshold = await db.RankThresholds.FindAsync(id);
        if (threshold == null) return NotFound();
        db.RankThresholds.Remove(threshold);
        await db.SaveChangesAsync();
        return Ok();
    }
}

public record UpsertRankRequest(string? DisplayName, string? Description, int BossesRequired);
