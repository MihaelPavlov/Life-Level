using LifeLevel.Modules.Waitlist.Application.DTOs;
using LifeLevel.Modules.Waitlist.Application.UseCases;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace LifeLevel.Api.Controllers;

/// <summary>Public "notify me at launch" form on the landing page.</summary>
[ApiController]
[Route("api/waitlist")]
[AllowAnonymous]
public class WaitlistController(WaitlistService waitlist) : ControllerBase
{
    [HttpPost]
    [EnableRateLimiting("waitlist")]
    public async Task<IActionResult> Join(JoinWaitlistRequest req, CancellationToken ct)
    {
        var outcome = await waitlist.JoinAsync(
            req,
            HttpContext.Connection.RemoteIpAddress?.ToString(),
            Request.Headers.UserAgent.ToString(),
            ct);

        // Same answer for new, repeated and ignored submissions, so the form
        // can't be used to check whether an address is on the list.
        return outcome == JoinWaitlistOutcome.InvalidEmail
            ? BadRequest(new { error = "invalid_email" })
            : Ok(new { ok = true });
    }
}
