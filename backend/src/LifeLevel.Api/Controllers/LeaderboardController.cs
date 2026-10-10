using System.Data;
using LifeLevel.Api.Infrastructure;
using LifeLevel.Modules.Leaderboard.Application.DTOs;
using LifeLevel.Modules.Leaderboard.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using LifeLevel.SharedKernel.Ports;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/leaderboard")]
[Authorize]
public class LeaderboardController(LeaderboardService leaderboard, IUserContext user) : ControllerBase
{
    /// <summary>Ranked players for a scope (global, region, guild) and metric (power, xp, km, boss, streak).</summary>
    [HttpGet]
    public async Task<ActionResult<LeaderboardDto>> Get(
        [FromQuery] string scope = "global", [FromQuery] string metric = "power", CancellationToken ct = default)
    {
        if (!Enum.TryParse<LeaderboardScope>(scope, true, out var s) || !Enum.IsDefined(s))
            return BadRequest(new { error = $"Unknown scope '{scope}'." });
        if (!Enum.TryParse<LeaderboardMetric>(metric, true, out var m) || !Enum.IsDefined(m))
            return BadRequest(new { error = $"Unknown metric '{metric}'." });
        return await leaderboard.GetAsync(user.UserId, s, m, ct);
    }

    [HttpGet("chest")]
    public Task<LeaderboardChestDto> Chest(CancellationToken ct) =>
        leaderboard.GetChestStatusAsync(user.UserId, ct);

    [HttpPost("chest/open")]
    [MutationIsolation(IsolationLevel.Serializable)]
    public Task<LeaderboardChestOpenedDto> OpenChest(CancellationToken ct) =>
        leaderboard.OpenChestAsync(user.UserId, ct);
}
