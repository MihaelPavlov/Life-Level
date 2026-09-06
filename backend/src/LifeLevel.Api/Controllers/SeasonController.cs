using LifeLevel.Modules.Seasons.Application.UseCases;
using LifeLevel.Modules.Seasons.Domain.Enums;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/season")]
[Authorize]
public class SeasonController(SeasonService seasons, IUserContext userContext) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetTrack()
        => Ok(await seasons.GetTrackAsync(userContext.UserId));

    [HttpPost("claim")]
    public async Task<IActionResult> Claim([FromBody] ClaimTierRequest req)
    {
        if (!Enum.TryParse<SeasonTrack>(req.Track, ignoreCase: true, out var track))
            return BadRequest(new { error = "Track must be 'Free' or 'Founder'." });

        try
        {
            var result = await seasons.ClaimTierAsync(userContext.UserId, req.Tier, track);
            return Ok(result);
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(StatusCodes.Status403Forbidden, new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
    }

    [HttpPost("pass/purchase")]
    public async Task<IActionResult> PurchaseFounderPass()
    {
        try
        {
            await seasons.PurchaseFounderPassAsync(userContext.UserId);
            return Ok(await seasons.GetTrackAsync(userContext.UserId));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
    }
}

public record ClaimTierRequest(int Tier, string Track);
