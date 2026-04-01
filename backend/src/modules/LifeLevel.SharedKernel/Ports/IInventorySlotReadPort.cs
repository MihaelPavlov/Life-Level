namespace LifeLevel.SharedKernel.Ports;

public interface IInventorySlotReadPort
{
    Task<int> GetMaxInventorySlotsAsync(Guid userId, CancellationToken ct = default);
}
