namespace LifeLevel.Modules.Guild.Domain.Entities;

public class GuildRaidVictoryAcknowledgement
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid GuildRaidId { get; set; }
    public Guid UserId { get; set; }
    public DateTime AcknowledgedAt { get; set; } = DateTime.UtcNow;

    public GuildRaid GuildRaid { get; set; } = null!;
}
