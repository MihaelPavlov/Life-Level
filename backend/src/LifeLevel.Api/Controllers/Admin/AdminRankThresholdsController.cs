using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Controllers.Admin;

[ApiController]
[Route("api/admin/rank-thresholds")]
[Authorize(Policy = "Admin")]
public class AdminRankThresholdsController(AppDbContext db) : ControllerBase
{
    private static readonly string[] ValidRanks = ["Novice", "Warrior", "Veteran", "Champion", "Legend"];

    // GET /api/admin/rank-thresholds
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var thresholds = await db.RankThresholds
            .OrderBy(r => r.BossesRequired)
            .Select(r => new { r.Id, r.Rank, r.BossesRequired })
            .ToListAsync();
        return Ok(thresholds);
    }

    // PUT /api/admin/rank-thresholds/{rank}
    [HttpPut("{rank}")]
    public async Task<IActionResult> Update(string rank, [FromBody] UpdateRankThresholdRequest req)
    {
        if (!ValidRanks.Contains(rank, StringComparer.OrdinalIgnoreCase))
            return BadRequest($"Unknown rank '{rank}'. Valid ranks: {string.Join(", ", ValidRanks)}.");
        if (req.BossesRequired < 0)
            return BadRequest("BossesRequired must be >= 0.");

        var threshold = await db.RankThresholds.FirstOrDefaultAsync(r => r.Rank == rank);
        if (threshold == null) return NotFound();
        threshold.BossesRequired = req.BossesRequired;
        await db.SaveChangesAsync();
        return Ok();
    }
}

public record UpdateRankThresholdRequest(int BossesRequired);
