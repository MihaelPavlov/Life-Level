using LifeLevel.Api.Application;
using LifeLevel.SharedKernel.Contracts;
using LifeLevel.Modules.Adventure.Dungeons.Application.UseCases;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DungeonController(DungeonService dungeonService, IUserContext userContext) : ControllerBase
{
    /// <summary>Enter (discover) the dungeon. Player must be at the dungeon node.</summary>
    [HttpPost("{dungeonId:guid}/enter")]
    public async Task<IActionResult> Enter(Guid dungeonId)
    {
        var userId = userContext.UserId;
        try
        {
            var state = await dungeonService.DiscoverAsync(userId, dungeonId);
            return Ok(new { discovered = state.IsDiscovered, currentFloor = state.CurrentFloor });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Complete the next floor. Player must be at the dungeon node.</summary>
    [HttpPost("{dungeonId:guid}/complete-floor")]
    public async Task<IActionResult> CompleteFloor(Guid dungeonId, [FromBody] CompleteFloorRequest request)
    {
        var userId = userContext.UserId;
        try
        {
            var result = await dungeonService.CompleteFloorAsync(userId, dungeonId, request.FloorNumber);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Debug: set current floor directly. No zone check.</summary>
    [HttpPost("{dungeonId:guid}/debug/set-floor")]
    public async Task<IActionResult> DebugSetFloor(Guid dungeonId, [FromBody] DebugSetFloorRequest request)
    {
        var userId = userContext.UserId;
        try
        {
            await dungeonService.DebugSetFloorAsync(userId, dungeonId, request.Floor);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Debug: reset dungeon state.</summary>
    [HttpPost("{dungeonId:guid}/debug/reset")]
    public async Task<IActionResult> DebugReset(Guid dungeonId)
    {
        var userId = userContext.UserId;
        await dungeonService.DebugResetAsync(userId, dungeonId);
        return NoContent();
    }
}

public record CompleteFloorRequest(int FloorNumber);
public record DebugSetFloorRequest(int Floor);
