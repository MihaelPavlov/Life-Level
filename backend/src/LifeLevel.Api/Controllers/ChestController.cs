using LifeLevel.Api.Application;
using LifeLevel.SharedKernel.Contracts;
using LifeLevel.Modules.Adventure.Encounters.Application.UseCases;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ChestController(ChestService chestService, IUserContext userContext) : ControllerBase
{
    /// <summary>Collect a chest. Player must be at the chest node.</summary>
    [HttpPost("{chestId:guid}/collect")]
    public async Task<IActionResult> Collect(Guid chestId)
    {
        var userId = userContext.UserId;
        try
        {
            var result = await chestService.CollectAsync(userId, chestId);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Debug: reset chest state so it can be collected again.</summary>
    [HttpPost("{chestId:guid}/debug/reset")]
    public async Task<IActionResult> DebugReset(Guid chestId)
    {
        var userId = userContext.UserId;
        await chestService.DebugResetAsync(userId, chestId);
        return NoContent();
    }
}
