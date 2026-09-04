using LifeLevel.Modules.Guild.Domain.Enums;

namespace LifeLevel.Modules.Guild.Domain.Entities;

public class GuildMember
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid GuildId { get; set; }
    public Guid UserId { get; set; }
    public GuildMemberRole Role { get; set; } = GuildMemberRole.Member;
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

    public Guild Guild { get; set; } = null!;
}
