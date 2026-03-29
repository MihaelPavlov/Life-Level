namespace LifeLevel.SharedKernel.Ports;

public interface IDailyQuestReadPort
{
    Task<int> CountCompletedDailyQuestsAsync(Guid userId, CancellationToken ct = default);
}
