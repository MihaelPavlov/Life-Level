using LifeLevel.Modules.Character.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

/// <summary>Guided unlocks: which features are open, and whether their ceremony and tour were seen.</summary>
[ApiController]
[Route("api/unlocks")]
[Authorize]
public class UnlocksController(UnlockService unlocks, IUserContext userContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get(CancellationToken ct) =>
        Ok(await unlocks.GetAsync(userContext.UserId, ct));

    [HttpPost("{key}/seen")]
    public async Task<IActionResult> Seen(string key, CancellationToken ct)
    {
        try
        {
            await unlocks.MarkSeenAsync(userContext.UserId, key, ct);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("{key}/toured")]
    public async Task<IActionResult> Toured(string key, CancellationToken ct)
    {
        try
        {
            return Ok(await unlocks.MarkTouredAsync(userContext.UserId, key, ct));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
