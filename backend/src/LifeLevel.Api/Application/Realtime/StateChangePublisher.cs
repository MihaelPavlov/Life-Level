using Microsoft.AspNetCore.SignalR;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Api.Application.Realtime;

/// <summary>Hints only. PostgreSQL remains authoritative when a message is missed.</summary>
public sealed class StateChangePublisher(
    IHubContext<GuildRaidHub> hub,
    IHttpContextAccessor httpContext,
    ILogger<StateChangePublisher> logger) : IUserStateChangePort
{
    public const string Header = "X-LifeLevel-Changed-Areas";

    public Task PublishUserAsync(Guid userId, IReadOnlyCollection<string> areas,
        CancellationToken ct = default) => PublishAsync(
            new Dictionary<Guid, HashSet<string>> { [userId] = new(areas, StringComparer.Ordinal) },
            new Dictionary<Guid, HashSet<string>>(), new(StringComparer.Ordinal), ct);

    public async Task PublishAsync(
        IReadOnlyDictionary<Guid, HashSet<string>> users,
        IReadOnlyDictionary<Guid, HashSet<string>> guilds,
        HashSet<string> global,
        CancellationToken ct)
    {
        var response = httpContext.HttpContext?.Response;
        var requestUser = httpContext.HttpContext?.User.FindFirst(
            System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (response is { HasStarted: false })
        {
            var existing = response.Headers[Header].ToString();
            var areas = existing.Split(',', StringSplitOptions.RemoveEmptyEntries)
                .Concat(global).ToHashSet(StringComparer.Ordinal);
            if (Guid.TryParse(requestUser, out var currentId)
                && users.TryGetValue(currentId, out var ownAreas)) areas.UnionWith(ownAreas);
            if (areas.Count > 0) response.Headers[Header] = string.Join(',', areas.Order(StringComparer.Ordinal));
        }

        try
        {
            foreach (var (userId, areas) in users)
                await hub.Clients.User(userId.ToString()).SendAsync(
                    "StateChanged", new { areas = areas.Order(StringComparer.Ordinal).ToArray() }, ct);
            foreach (var (guildId, areas) in guilds)
                await hub.Clients.Group(GuildRaidRealtimePublisher.GroupName(guildId)).SendAsync(
                    "StateChanged", new { areas = areas.Order(StringComparer.Ordinal).ToArray() }, ct);
            if (global.Count > 0)
                await hub.Clients.All.SendAsync("StateChanged",
                    new { areas = global.Order(StringComparer.Ordinal).ToArray() }, ct);
        }
        catch (Exception ex)
        {
            // Redis pub/sub is transient. The next client reconciliation reads the database.
            logger.LogWarning(ex, "Could not publish state change hints.");
        }
    }
}
