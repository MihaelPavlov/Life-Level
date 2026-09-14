using LifeLevel.Modules.Talents.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using LifeLevel.SharedKernel.Ports;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/talents")]
[Authorize]
public class TalentsController(TalentService talents, IStreakShieldPort streakShield, IUserContext userContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetScreen()
        => Ok(await talents.GetScreenAsync(userContext.UserId));

    [HttpPost("draw")]
    public async Task<IActionResult> Draw()
    {
        try
        {
            var result = await talents.DrawAsync(userContext.UserId);
            await GrantShieldsAsync(result.ShieldsGranted);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
    }

    private async Task GrantShieldsAsync(int count)
    {
        for (var i = 0; i < count; i++)
            await streakShield.AddShieldAsync(userContext.UserId);
    }
}
