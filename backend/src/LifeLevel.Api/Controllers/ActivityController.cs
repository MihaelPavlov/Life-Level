using System.Security.Claims;
using LifeLevel.Api.Application.DTOs.Activity;
using LifeLevel.Api.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/activity")]
[Authorize]
public class ActivityController(ActivityService activityService) : ControllerBase
{
    [HttpPost("log")]
    public async Task<IActionResult> Log([FromBody] LogActivityRequest req)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        try
        {
            var result = await activityService.LogActivityAsync(userId, req);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("history")]
    public async Task<IActionResult> GetHistory()
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var history = await activityService.GetHistoryAsync(userId);
        return Ok(history);
    }
}
