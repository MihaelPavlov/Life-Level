using LifeLevel.Api.Application.Services;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/seen")]
public sealed class SeenStateController(SeenStateService seen, IUserContext user) : ControllerBase
{
    public sealed record IdsRequest(List<Guid> Ids);
    public sealed record TurnRequest(Guid TurnId);

    [HttpPost("achievements")]
    public async Task<IActionResult> Achievements(IdsRequest request, CancellationToken ct)
    {
        if (request.Ids.Count > 500) return BadRequest();
        await seen.MarkAchievementsAsync(user.UserId, request.Ids.Distinct().ToArray(), ct);
        return NoContent();
    }

    [HttpPost("titles")]
    public async Task<IActionResult> Titles(IdsRequest request, CancellationToken ct)
    {
        if (request.Ids.Count > 500) return BadRequest();
        await seen.MarkTitlesAsync(user.UserId, request.Ids.Distinct().ToArray(), ct);
        return NoContent();
    }

    [HttpGet("bosses")]
    public Task<List<BossSeenView>> Bosses(CancellationToken ct) => seen.GetBossesAsync(user.UserId, ct);

    [HttpPost("bosses/{bossId:guid}")]
    public async Task<IActionResult> Boss(Guid bossId, TurnRequest request, CancellationToken ct)
    {
        var result = await seen.MarkBossTurnAsync(user.UserId, bossId, request.TurnId, ct);
        return result is null ? NotFound() : Ok(result);
    }
}
