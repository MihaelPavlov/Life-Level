using LifeLevel.Modules.Notifications.Application.DTOs;
using LifeLevel.Modules.Notifications.Application.Ports.In;
using LifeLevel.Modules.Notifications.Domain.Enums;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/notifications")]
[Authorize]
public class NotificationsController(
    INotificationService notifications,
    IUserContext userContext) : ControllerBase
{
    [HttpPost("register-token")]
    public async Task<IActionResult> RegisterToken([FromBody] RegisterTokenRequest req, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(req.Token))
            return BadRequest(new { error = "Token is required." });

        if (!Enum.TryParse<DevicePlatform>(req.Platform, ignoreCase: true, out var platform))
            return BadRequest(new { error = $"Invalid platform '{req.Platform}'. Expected: android, ios, web." });

        await notifications.RegisterTokenAsync(userContext.UserId, req.Token, platform, ct);
        return NoContent();
    }

    [HttpPost("unregister-token")]
    public async Task<IActionResult> UnregisterToken([FromBody] UnregisterTokenRequest req, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(req.Token))
            return BadRequest(new { error = "Token is required." });

        await notifications.UnregisterTokenAsync(req.Token, ct);
        return NoContent();
    }
}
