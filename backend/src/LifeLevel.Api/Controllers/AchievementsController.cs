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
}
