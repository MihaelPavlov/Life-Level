using LifeLevel.Modules.Quest.Domain.Enums;

namespace LifeLevel.Modules.Quest.Domain.Entities;

public class TaskRewardMilestoneClaim
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public QuestType PeriodType { get; set; }
    public DateTime PeriodStartUtc { get; set; }
    public int Threshold { get; set; }
    public DateTime ClaimedAtUtc { get; set; } = DateTime.UtcNow;
}
