using LifeLevel.SharedKernel.DTOs;

namespace LifeLevel.SharedKernel.Ports;

public interface ILevelUpReceiptPort
{
    Task AddCoinsAsync(Guid receiptId, int coins, CancellationToken ct = default);
    Task AddItemsAsync(Guid receiptId, IReadOnlyList<GrantedItemInfo> granted,
        IReadOnlyList<LevelUpBlockedItemInfo> blocked, CancellationToken ct = default);
    Task AddRegionsAsync(Guid receiptId, IReadOnlyList<LevelUpRegionInfo> regions,
        CancellationToken ct = default);
}
