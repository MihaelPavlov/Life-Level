using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.SharedKernel.Ports;

public record CompletedQuestInfo(Guid QuestId, string Title, int RewardXp);

public record QuestActivityResult(
    IReadOnlyList<CompletedQuestInfo> CompletedQuests,
    bool AllDailyCompleted,
    int BonusXp);

public interface IQuestProgressPort
{
    Task<QuestActivityResult> UpdateProgressFromActivityAsync(
        Guid userId,
        ActivityType activityType,
        int durationMinutes,
        double? distanceKm,
        int? calories,
        CancellationToken ct = default);
}
