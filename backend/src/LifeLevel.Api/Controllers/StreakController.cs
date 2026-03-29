using LifeLevel.Api.Application;
using LifeLevel.Api.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/streak")]
[Authorize]
public class StreakController(StreakService streakService, IUserContext userContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var userId = userContext.UserId;
        var dto = await streakService.GetDtoAsync(userId);
        return Ok(dto);
    }

    [HttpPost("use-shield")]
    public async Task<IActionResult> UseShield()
    {
        var userId = userContext.UserId;
        var result = await streakService.UseShieldAsync(userId);
        if (!result.Success)
            return BadRequest(new { error = result.Message });
        return Ok(result);
    }
}
