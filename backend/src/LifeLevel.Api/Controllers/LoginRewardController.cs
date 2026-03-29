using LifeLevel.Api.Application;
using LifeLevel.Api.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/login-reward")]
[Authorize]
public class LoginRewardController(LoginRewardService loginRewardService, IUserContext userContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetStatus()
    {
        var userId = userContext.UserId;
        var status = await loginRewardService.GetStatusAsync(userId);
        return Ok(status);
    }

    [HttpPost("claim")]
    public async Task<IActionResult> Claim()
    {
        var userId = userContext.UserId;
        try
        {
            var result = await loginRewardService.ClaimDailyRewardAsync(userId);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
    }
}
