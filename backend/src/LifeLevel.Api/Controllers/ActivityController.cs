using LifeLevel.SharedKernel.Contracts;
using LifeLevel.Modules.Activity.Application.DTOs;
using LifeLevel.Modules.Activity.Application.UseCases;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/activity")]
[Authorize]
public class ActivityController(ActivityService activityService, IUserContext userContext) : ControllerBase
{
    [HttpPost("log")]
    public async Task<IActionResult> Log([FromBody] LogActivityRequest req)
    {
        var userId = userContext.UserId;
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
        var userId = userContext.UserId;
        var history = await activityService.GetHistoryAsync(userId);
        return Ok(history);
    }
}
