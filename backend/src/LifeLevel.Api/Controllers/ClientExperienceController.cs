using System.Security.Cryptography;
using System.Text;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/client-experience")]
public sealed class ClientExperienceController(
    IConfiguration configuration,
    IUserContext user,
    ILogger<ClientExperienceController> logger) : ControllerBase
{
    private static readonly string[] Features =
    [
        "stats", "rewards", "streakSeason", "achievementsEquipment",
        "map", "guild", "modes", "shop", "talents", "activity",
        "persistentCache"
    ];

    [HttpGet("config")]
    public IActionResult Config()
    {
        var flags = Features.ToDictionary(name => name, IsEnabled);
        return Ok(new { schemaVersion = 1, flags });
    }

    [HttpPost("events")]
    public IActionResult Events([FromBody] ClientEventBatch batch)
    {
        if (batch.Events.Count > 100) return BadRequest(new { message = "Maximum 100 events per batch." });
        foreach (var item in batch.Events)
        {
            if (string.IsNullOrWhiteSpace(item.Name) || item.Name.Length > 80) continue;
            logger.LogInformation(
                "ClientExperience {EventName} feature={Feature} outcome={Outcome} durationMs={DurationMs} operation={OperationId} user={UserId}",
                item.Name, item.Feature, item.Outcome, item.DurationMs,
                item.OperationId, user.UserId);
        }
        return Accepted();
    }

    private bool IsEnabled(string feature)
    {
        var section = configuration.GetSection($"InstantActions:Features:{feature}");
        if (!section.GetValue("Enabled", false)) return false;
        var allowlist = section.GetSection("UserAllowlist").Get<string[]>() ?? [];
        if (allowlist.Contains(user.UserId.ToString(), StringComparer.OrdinalIgnoreCase)) return true;
        var percentage = Math.Clamp(section.GetValue("Percentage", 0), 0, 100);
        if (percentage == 100) return true;
        if (percentage == 0) return false;
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes($"{feature}:{user.UserId}"));
        var bucket = BitConverter.ToUInt32(bytes, 0) % 100;
        return bucket < percentage;
    }
}

public sealed record ClientEventBatch(IReadOnlyList<ClientExperienceEvent> Events);
public sealed record ClientExperienceEvent(
    string Name,
    string Feature,
    string Outcome,
    long? DurationMs,
    Guid? OperationId);
