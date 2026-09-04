using LifeLevel.SharedKernel.Ports;
using Microsoft.AspNetCore.SignalR;

namespace LifeLevel.Api.Application.Realtime;

public class GuildRaidRealtimePublisher(IHubContext<GuildRaidHub> hub) : IGuildRaidRealtimePort
{
    public static string GroupName(Guid guildId) => $"guild:{guildId:N}";

    public Task RaidStartedAsync(GuildRaidStartedInfo info, CancellationToken ct = default)
    {
        return hub.Clients
            .Group(GroupName(info.GuildId))
            .SendAsync("RaidStarted", info, ct);
    }

    public Task RaidHpUpdatedAsync(GuildRaidHpUpdatedInfo info, CancellationToken ct = default)
    {
        return hub.Clients
            .Group(GroupName(info.GuildId))
            .SendAsync("RaidHpUpdated", info, ct);
    }

    public Task RaidDefeatedAsync(GuildRaidDefeatedInfo info, CancellationToken ct = default)
    {
        return hub.Clients
            .Group(GroupName(info.GuildId))
            .SendAsync("RaidDefeated", info, ct);
    }

    public Task RaidExpiredAsync(GuildRaidExpiredInfo info, CancellationToken ct = default)
    {
        return hub.Clients
            .Group(GroupName(info.GuildId))
            .SendAsync("RaidExpired", info, ct);
    }
}
