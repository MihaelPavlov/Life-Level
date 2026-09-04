using System.Security.Claims;
using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Guild.Domain.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Realtime;

[Authorize]
public class GuildRaidHub(AppDbContext db) : Hub
{
    public override async Task OnConnectedAsync()
    {
        await JoinCurrentGuild();
        await base.OnConnectedAsync();
    }

    public async Task JoinCurrentGuild()
    {
        var userIdValue = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (Guid.TryParse(userIdValue, out var userId))
        {
            if (Context.Items.TryGetValue("guildGroup", out var existing) &&
                existing is string existingGroup)
            {
                await Groups.RemoveFromGroupAsync(
                    Context.ConnectionId,
                    existingGroup,
                    Context.ConnectionAborted);
                Context.Items.Remove("guildGroup");
            }

            var guildId = await db.Set<GuildMember>()
                .AsNoTracking()
                .Where(m => m.UserId == userId)
                .Select(m => (Guid?)m.GuildId)
                .FirstOrDefaultAsync(Context.ConnectionAborted);

            if (guildId.HasValue)
            {
                var group = GuildRaidRealtimePublisher.GroupName(guildId.Value);
                await Groups.AddToGroupAsync(
                    Context.ConnectionId,
                    group,
                    Context.ConnectionAborted);
                Context.Items["guildGroup"] = group;
            }
        }
    }
}
