using LifeLevel.Api.Application;
using LifeLevel.Api.Application.DTOs.Map;
using LifeLevel.Api.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class MapController(MapService mapService, IUserContext userContext) : ControllerBase
{
    [HttpGet("full")]
    public async Task<ActionResult<MapFullResponse>> GetFullMap()
    {
        var userId = userContext.UserId;
        var result = await mapService.GetFullMapAsync(userId);
        return Ok(result);
    }

    [HttpPut("destination")]
    public async Task<IActionResult> SetDestination([FromBody] SetDestinationRequest request)
    {
        var userId = userContext.UserId;
        try
        {
            await mapService.SetDestinationAsync(userId, request.DestinationNodeId);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // ── Debug endpoints ────────────────────────────────────────────────────────

    /// <summary>List all map nodes with their IDs, types, and sub-entity IDs for debug reference.</summary>
    [HttpGet("debug/nodes")]
    public async Task<IActionResult> DebugListNodes()
    {
        var nodes = await mapService.DebugListNodesAsync();
        return Ok(nodes);
    }

    /// <summary>Teleport to any node by ID. Also unlocks it.</summary>
    [HttpPost("debug/teleport/{nodeId:guid}")]
    public async Task<IActionResult> DebugTeleport(Guid nodeId)
    {
        var userId = userContext.UserId;
        await mapService.DebugTeleportAsync(userId, nodeId);
        return NoContent();
    }

    /// <summary>Add distance toward current destination. Arrives at node if total >= edge distance.</summary>
    [HttpPost("debug/add-distance")]
    public async Task<IActionResult> DebugAddDistance([FromBody] DebugAddDistanceRequest request)
    {
        var userId = userContext.UserId;
        try
        {
            await mapService.DebugAddDistanceAsync(userId, request.Km);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Adjust character level by delta (positive = up, negative = down). Returns new level.</summary>
    [HttpPost("debug/adjust-level")]
    public async Task<ActionResult<object>> DebugAdjustLevel([FromBody] DebugAdjustLevelRequest request)
    {
        var userId = userContext.UserId;
        var newLevel = await mapService.DebugAdjustLevelAsync(userId, request.Delta);
        return Ok(new { level = newLevel });
    }

    /// <summary>Unlock a specific node without teleporting.</summary>
    [HttpPost("debug/unlock-node/{nodeId:guid}")]
    public async Task<IActionResult> DebugUnlockNode(Guid nodeId)
    {
        var userId = userContext.UserId;
        try
        {
            await mapService.DebugUnlockNodeAsync(userId, nodeId);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Unlock all map nodes at once.</summary>
    [HttpPost("debug/unlock-all")]
    public async Task<IActionResult> DebugUnlockAll()
    {
        var userId = userContext.UserId;
        await mapService.DebugUnlockAllNodesAsync(userId);
        return NoContent();
    }

    /// <summary>Reset all map progress (position, unlocks, boss/chest/dungeon states) for the current user.</summary>
    [HttpPost("debug/reset-progress")]
    public async Task<IActionResult> DebugResetProgress()
    {
        var userId = userContext.UserId;
        await mapService.DebugResetProgressAsync(userId);
        return NoContent();
    }

    /// <summary>Set character XP directly. Returns new XP value.</summary>
    [HttpPost("debug/set-xp")]
    public async Task<ActionResult<object>> DebugSetXp([FromBody] DebugSetXpRequest request)
    {
        var userId = userContext.UserId;
        try
        {
            var newXp = await mapService.DebugSetXpAsync(userId, request.Xp);
            return Ok(new { xp = newXp });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
