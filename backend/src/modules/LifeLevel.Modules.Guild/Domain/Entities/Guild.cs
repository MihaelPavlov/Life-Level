namespace LifeLevel.Modules.Guild.Domain.Entities;

public class Guild
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Icon { get; set; } = "shield";
    public Guid OwnerUserId { get; set; }
    public int MaxMembers { get; set; } = 5;
    public bool IsOpen { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<GuildMember> Members { get; set; } = [];
    public ICollection<GuildRaid> Raids { get; set; } = [];
}
