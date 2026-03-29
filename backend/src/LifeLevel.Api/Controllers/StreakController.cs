using System.Security.Claims;
using LifeLevel.Api.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/streak")]
[Authorize]
public class StreakController(StreakService streakService) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var dto = await streakService.GetDtoAsync(userId);
        return Ok(dto);
    }

    [HttpPost("use-shield")]
    public async Task<IActionResult> UseShield()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var result = await streakService.UseShieldAsync(userId);
        if (!result.Success)
            return BadRequest(new { error = result.Message });
        return Ok(result);
    }
}
