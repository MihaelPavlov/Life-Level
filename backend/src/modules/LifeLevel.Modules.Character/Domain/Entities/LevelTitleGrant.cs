namespace LifeLevel.Modules.Character.Domain.Entities;

public class LevelTitleGrant
{
    public Guid Id { get; set; }
    public int Level { get; set; }
    public Guid TitleId { get; set; }
    public Title Title { get; set; } = null!;
}
