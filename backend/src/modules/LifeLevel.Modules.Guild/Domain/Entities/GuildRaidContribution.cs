namespace LifeLevel.Modules.Guild.Domain.Entities;

public class GuildRaidContribution
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid GuildRaidId { get; set; }
    public Guid UserId { get; set; }
    public int DamageDealt { get; set; }
    public Guid? LastActivityId { get; set; }
    public DateTime? LastActivityAt { get; set; }

    public GuildRaid GuildRaid { get; set; } = null!;
}
