using System.Net;
using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Activity.Domain;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

/// <summary>Returns a character ID by querying the in-memory DB.</summary>
internal sealed class DbCharacterIdReadPort(DbContext db) : ICharacterIdReadPort
{
    public async Task<Guid?> GetCharacterIdAsync(Guid userId, CancellationToken ct = default)
        => await db.Set<Character>()
            .Where(c => c.UserId == userId)
            .Select(c => (Guid?)c.Id)
            .FirstOrDefaultAsync(ct);
}

/// <summary>Returns a fixed character ID regardless of user.</summary>
internal sealed class StubCharacterIdReadPort(Guid? characterId = null) : ICharacterIdReadPort
{
    public Task<Guid?> GetCharacterIdAsync(Guid userId, CancellationToken ct = default)
        => Task.FromResult(characterId);
}

/// <summary>Simulates a successful activity log — returns a new GUID and 100 XP.</summary>
internal sealed class StubActivityLogPort : IActivityLogPort
{
    public Task<ActivityLogPortResult> LogExternalActivityAsync(
        Guid userId, ActivityType type, int durationMinutes, double? distanceKm,
        int? calories, int? heartRateAvg, string externalId, DateTime performedAt,
        int? steps = null, CancellationToken ct = default)
    {
        return Task.FromResult(new ActivityLogPortResult(
            Guid.NewGuid(), 100, AdventureDistanceCalculator.Calculate(type, distanceKm)));
    }

    public Task<HistoricalActivityResult> ImportHistoricalActivityAsync(
        Guid userId, ActivityType type, int durationMinutes, double? distanceKm,
        int? calories, int? heartRateAvg, string externalId, DateTime performedAt,
        int? steps = null, CancellationToken ct = default)
        => Task.FromResult(new HistoricalActivityResult(
            Guid.NewGuid(), type, durationMinutes, distanceKm ?? 0,
            AdventureDistanceCalculator.Calculate(type, distanceKm), 50, performedAt));
}

/// <summary>Always throws — used to test error handling paths.</summary>
internal sealed class FailingActivityLogPort : IActivityLogPort
{
    public Task<ActivityLogPortResult> LogExternalActivityAsync(
        Guid userId, ActivityType type, int durationMinutes, double? distanceKm,
        int? calories, int? heartRateAvg, string externalId, DateTime performedAt,
        int? steps = null, CancellationToken ct = default)
    {
        throw new InvalidOperationException("Simulated activity log failure");
    }

    public Task<HistoricalActivityResult> ImportHistoricalActivityAsync(
        Guid userId, ActivityType type, int durationMinutes, double? distanceKm,
        int? calories, int? heartRateAvg, string externalId, DateTime performedAt,
        int? steps = null, CancellationToken ct = default)
        => throw new InvalidOperationException("Simulated activity log failure");

}

/// <summary>Captures the last call for assertion — returns a new GUID and 100 XP.</summary>
internal sealed class CapturingActivityLogPort : IActivityLogPort
{
    public ActivityType? LastActivityType { get; private set; }
    public int? LastSteps { get; private set; }

    public Task<ActivityLogPortResult> LogExternalActivityAsync(
        Guid userId, ActivityType type, int durationMinutes, double? distanceKm,
        int? calories, int? heartRateAvg, string externalId, DateTime performedAt,
        int? steps = null, CancellationToken ct = default)
    {
        LastActivityType = type;
        LastSteps = steps;
        return Task.FromResult(new ActivityLogPortResult(
            Guid.NewGuid(), 100, AdventureDistanceCalculator.Calculate(type, distanceKm)));
    }

    public Task<HistoricalActivityResult> ImportHistoricalActivityAsync(
        Guid userId, ActivityType type, int durationMinutes, double? distanceKm,
        int? calories, int? heartRateAvg, string externalId, DateTime performedAt,
        int? steps = null, CancellationToken ct = default)
        => Task.FromResult(new HistoricalActivityResult(
            Guid.NewGuid(), type, durationMinutes, distanceKm ?? 0,
            AdventureDistanceCalculator.Calculate(type, distanceKm), 50, performedAt));
}

/// <summary>Returns null by default, or looks up from a provided dictionary.</summary>
internal sealed class StubActivityExternalIdReadPort : IActivityExternalIdReadPort
{
    private readonly Dictionary<string, Guid> _lookup;

    public StubActivityExternalIdReadPort(Dictionary<string, Guid>? lookup = null)
    {
        _lookup = lookup ?? [];
    }

    public Task<Guid?> FindActivityIdByExternalIdAsync(Guid characterId, string externalId, CancellationToken ct = default)
    {
        return Task.FromResult(_lookup.TryGetValue(externalId, out var id) ? (Guid?)id : null);
    }
}

/// <summary>Fake HTTP message handler for testing — returns a fixed status code or throws.</summary>
internal sealed class FakeHttpHandler : HttpMessageHandler
{
    private readonly HttpStatusCode _statusCode;
    private readonly bool _throwException;

    public FakeHttpHandler(HttpStatusCode statusCode = HttpStatusCode.OK, bool throwException = false)
    {
        _statusCode = statusCode;
        _throwException = throwException;
    }

    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
    {
        if (_throwException)
            throw new HttpRequestException("Simulated network failure");

        return Task.FromResult(new HttpResponseMessage(_statusCode));
    }
}

/// <summary>Deterministic gain preview: 3 XP per minute plus 10 per km, END +2 for runs.</summary>
internal sealed class StubActivityGainPreviewPort : IActivityGainPreviewPort
{
    public ActivityGainPreview Preview(ActivityType type, int durationMinutes, double? distanceKm, int? calories) =>
        new((int)Math.Round(durationMinutes * 3 + (distanceKm ?? 0) * 10), 0, type == ActivityType.Running ? 2 : 0, 0, 0, 0);
}
