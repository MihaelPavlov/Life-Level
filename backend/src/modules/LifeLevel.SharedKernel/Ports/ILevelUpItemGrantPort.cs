using LifeLevel.SharedKernel.DTOs;

namespace LifeLevel.SharedKernel.Ports;

public interface ILevelUpItemGrantPort
{
    Task<IReadOnlyList<GrantedItemInfo>> EvaluateAndGrantAsync(
        Guid userId, int previousLevel, int newLevel, CancellationToken ct = default);
}
