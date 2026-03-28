using System.Security.Claims;
using LifeLevel.Api.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CrossroadsController(CrossroadsService crossroadsService) : ControllerBase
{
    /// <summary>Choose a path at the crossroads. Player must be at the crossroads node. One-time only.</summary>
    [HttpPost("{crossroadsId:guid}/choose-path")]
    public async Task<IActionResult> ChoosePath(Guid crossroadsId, [FromBody] ChoosePathRequest request)
    {
        var userId = GetUserId();
        try
        {
            var result = await crossroadsService.ChoosePathAsync(userId, crossroadsId, request.PathId);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>Debug: reset crossroads choice so a new path can be selected.</summary>
    [HttpPost("{crossroadsId:guid}/debug/reset")]
    public async Task<IActionResult> DebugReset(Guid crossroadsId)
    {
        var userId = GetUserId();
        await crossroadsService.DebugResetAsync(userId, crossroadsId);
        return NoContent();
    }

    private Guid GetUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? throw new UnauthorizedAccessException();
        return Guid.Parse(claim);
    }
}

public record ChoosePathRequest(Guid PathId);
