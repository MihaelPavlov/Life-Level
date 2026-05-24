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

    [HttpGet]
    public async Task<IActionResult> GetNotifications(CancellationToken ct)
    {
        var logs = await notifications.GetNotificationsAsync(userContext.UserId, ct);
        var dtos = logs.Select(l => new NotificationItemDto(
            l.Id,
            l.Title,
            l.Body,
            l.Category,
            null,
            l.SentAt,
            l.IsRead
        )).ToList();
        return Ok(dtos);
    }

    [HttpPost("mark-all-read")]
    public async Task<IActionResult> MarkAllRead(CancellationToken ct)
    {
        await notifications.MarkAllReadAsync(userContext.UserId, ct);
        return NoContent();
    }

    [HttpPost("send-test")]
    public async Task<IActionResult> SendTest(CancellationToken ct)
    {
        var result = await notifications.SendToUserAsync(
            userId: userContext.UserId,
            category: "level-up",
            title: "🔔 Test Notification",
            body: "Push notifications are working!",
            data: new Dictionary<string, string> { ["deeplink"] = "lifelevel://home" },
            isCritical: true,
            ct: ct);
        return Ok(new { result.Sent, result.Reason });
    }
}
