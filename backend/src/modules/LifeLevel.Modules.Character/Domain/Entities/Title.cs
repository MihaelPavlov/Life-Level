namespace LifeLevel.Modules.Character.Domain.Entities;

public class Title
{
    public Guid Id { get; set; }
    public string Emoji { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string UnlockCondition { get; set; } = string.Empty;
    public string UnlockCriteria { get; set; } = string.Empty;
    public int SortOrder { get; set; }
}
