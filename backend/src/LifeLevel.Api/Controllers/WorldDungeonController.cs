using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/world/dungeon")]
[Authorize]
public class WorldDungeonController(
    WorldDungeonService dungeonService,
    IUserContext userContext) : ControllerBase
{
    /// <summary>
    /// Enter a dungeon. Creates the run state + per-floor state (Floor 1
    /// Active, remaining floors Locked). Idempotent when a run is already
    /// InProgress for the same (user, zone). 400 when the user is not at the
    /// dungeon zone.
    /// </summary>
    [HttpPost("{zoneId:guid}/enter")]
    public async Task<IActionResult> Enter(Guid zoneId, CancellationToken ct)
    {
        var userId = userContext.UserId;
        try
        {
            await dungeonService.EnterAsync(userId, zoneId, ct);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Returns the dungeon's floors + per-floor user progress + run status.
    /// 404 when the zone isn't a dungeon.
    /// </summary>
    [HttpGet("{zoneId:guid}/state")]
    public async Task<IActionResult> GetState(Guid zoneId, CancellationToken ct)
    {
        var userId = userContext.UserId;
        var state = await dungeonService.GetStateAsync(userId, zoneId, ct);
        if (state == null) return NotFound(new { message = "Dungeon not found." });
        return Ok(state);
    }
}
