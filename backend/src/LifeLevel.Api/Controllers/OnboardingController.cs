using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.Modules.Integrations.Application.UseCases;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

/// <summary>Import-first onboarding: the player's recent history becomes their starting progress.</summary>
[ApiController]
[Route("api/onboarding")]
[Authorize]
public class OnboardingController(OnboardingImportService onboardingImport, IUserContext userContext) : ControllerBase
{
    /// <summary>GET /api/onboarding/preview?source=strava — how many workouts the import will find.</summary>
    [HttpGet("preview")]
    public async Task<IActionResult> Preview([FromQuery] string source, CancellationToken ct)
    {
        var result = await onboardingImport.PreviewAsync(userContext.UserId, source, ct);
        return Ok(result);
    }

    /// <summary>
    /// POST /api/onboarding/import — imports the last 30 days at half XP and
    /// awards it as one batch. 409 once character setup is complete.
    /// </summary>
    [HttpPost("import")]
    public async Task<IActionResult> Import([FromBody] OnboardingImportRequest request, CancellationToken ct)
    {
        try
        {
            var result = await onboardingImport.ImportAsync(userContext.UserId, request, ct);
            return Ok(result);
        }
        catch (OnboardingImportService.SetupAlreadyCompleteException ex)
        {
            return Conflict(new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
