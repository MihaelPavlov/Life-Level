using LifeLevel.Modules.Achievements.Application.DTOs;
using LifeLevel.Modules.Achievements.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/achievements")]
[Authorize]
public class AchievementsController(
    AchievementService achievementService,
    IUserContext userContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? category, CancellationToken ct)
    {
        var userId = userContext.UserId;
        var result = await achievementService.GetAchievementsAsync(userId, category, ct);
        return Ok(result);
    }

    [HttpPost("check-unlocks")]
    public async Task<IActionResult> CheckUnlocks(CancellationToken ct)
    {
        var userId = userContext.UserId;
        var result = await achievementService.CheckUnlocksAsync(userId, ct);
        return Ok(result);
    }

    /// <summary>Reward Roads: every category as a road of tier stages, plus the wallet.</summary>
    [HttpGet("roads")]
    public async Task<IActionResult> GetRoads(CancellationToken ct) =>
        Ok(await achievementService.GetRoadsAsync(userContext.UserId, ct));

    [HttpPost("{id:guid}/claim")]
    public async Task<IActionResult> Claim(Guid id, CancellationToken ct) =>
        Ok(await achievementService.ClaimAsync(userContext.UserId, [id], ct));

    [HttpPost("claim-all")]
    public async Task<IActionResult> ClaimAll([FromQuery] string? category, CancellationToken ct)
    {
        try { return Ok(await achievementService.ClaimAllAsync(userContext.UserId, category, ct)); }
        catch (AchievementException ex) { return BadRequest(new { code = ex.Code, message = ex.Message }); }
    }

    [HttpPost("stages/{category}/{tier}/open")]
    public async Task<IActionResult> OpenStageChest(string category, string tier, CancellationToken ct)
    {
        try { return Ok(await achievementService.OpenStageChestAsync(userContext.UserId, category, tier, ct)); }
        catch (AchievementException ex) { return Conflict(new { code = ex.Code, message = ex.Message }); }
    }
}
