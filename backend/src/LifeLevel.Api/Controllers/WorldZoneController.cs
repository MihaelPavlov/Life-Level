using LifeLevel.Api.Application;
using LifeLevel.Api.Application.DTOs.Map;
using LifeLevel.Api.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/world")]
[Authorize]
public class WorldZoneController(WorldZoneService worldZoneService, IUserContext userContext) : ControllerBase
{
    [HttpGet("full")]
    public async Task<ActionResult<WorldFullResponse>> GetFullWorld()
    {
        var userId = userContext.UserId;
        var result = await worldZoneService.GetFullWorldAsync(userId);
        return Ok(result);
    }

    [HttpPut("destination")]
    public async Task<IActionResult> SetDestination([FromBody] SetWorldDestinationRequest request)
    {
        var userId = userContext.UserId;
        try
        {
            await worldZoneService.SetDestinationAsync(userId, request.DestinationZoneId);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("debug/add-distance")]
    public async Task<IActionResult> DebugAddDistance([FromBody] DebugAddWorldDistanceRequest request)
    {
        var userId = userContext.UserId;
        try
        {
            await worldZoneService.AddDistanceAsync(userId, request.Km);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("zone/{zoneId:guid}/complete")]
    public async Task<ActionResult<CompleteZoneResult>> CompleteZone(Guid zoneId)
    {
        var userId = userContext.UserId;
        try
        {
            var result = await worldZoneService.CompleteZoneAsync(userId, zoneId);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
