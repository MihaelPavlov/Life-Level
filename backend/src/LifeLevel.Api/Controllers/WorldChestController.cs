using LifeLevel.Modules.WorldZone.Application.UseCases;
using LifeLevel.Modules.WorldZone.Domain.Exceptions;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/world/chest")]
[Authorize]
public class WorldChestController(
    WorldChestService chestService,
    IUserContext userContext) : ControllerBase
{
    /// <summary>
    /// Opens a chest zone. Returns the awarded XP and zone name on first open.
    /// 409 on re-open, 400 when the user is not standing on the chest zone.
    /// </summary>
    [HttpPost("{zoneId:guid}/open")]
    public async Task<IActionResult> Open(Guid zoneId, CancellationToken ct)
    {
        var userId = userContext.UserId;
        try
        {
            var result = await chestService.OpenAsync(userId, zoneId, ct);
            return Ok(result);
        }
        catch (ChestAlreadyOpenedException ex)
        {
            return Conflict(new { error = "CHEST_ALREADY_OPENED", message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
