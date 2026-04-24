using LifeLevel.Api.Application;
using LifeLevel.SharedKernel.Contracts;
using LifeLevel.Modules.WorldZone.Application.DTOs;
using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.Modules.WorldZone.Domain.Exceptions;
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
        catch (PathAlreadyChosenException ex)
        {
            return Conflict(new
            {
                error = "PATH_ALREADY_CHOSEN",
                message = ex.Message
            });
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

    /// <summary>
    /// Teleport the authenticated user into the entry zone of the target region.
    /// Returns 204 on success, 409 with <c>error=REGION_LOCKED</c> when the
    /// character level is below the region's requirement, and 409 with
    /// <c>error=CROSS_REGION_SWITCH</c> when the user is already in a different
    /// region and <c>force</c> is not set — clients prompt and retry with
    /// <c>?force=true</c>.
    /// </summary>
    [HttpPost("region/{regionId:guid}/enter")]
    public async Task<IActionResult> EnterRegion(Guid regionId, [FromQuery] bool force = false, CancellationToken ct = default)
    {
        var userId = userContext.UserId;
        try
        {
            await worldZoneService.EnterRegionAsync(userId, regionId, force, ct);
            return NoContent();
        }
        catch (RegionLockedException ex)
        {
            return Conflict(new
            {
                error = "REGION_LOCKED",
                regionName = ex.RegionName,
                levelRequirement = ex.LevelRequirement
            });
        }
        catch (CrossRegionSwitchRequiresConfirmationException ex)
        {
            return Conflict(new
            {
                error = "CROSS_REGION_SWITCH",
                currentRegionName = ex.CurrentRegionName,
                destRegionName = ex.DestinationRegionName
            });
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }
}
