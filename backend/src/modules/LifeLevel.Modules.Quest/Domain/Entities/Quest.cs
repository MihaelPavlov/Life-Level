using LifeLevel.Modules.Quest.Domain.Enums;
using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.Modules.Quest.Domain.Entities;

public class Quest
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public QuestType Type { get; set; }
    public QuestCategory Category { get; set; }
    public ActivityType? RequiredActivity { get; set; }
    public double? TargetValue { get; set; }
    public string TargetUnit { get; set; } = string.Empty;
    public long RewardXp { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public ICollection<UserQuestProgress> UserProgress { get; set; } = [];
}
