using LifeLevel.SharedKernel.DTOs;

namespace LifeLevel.SharedKernel.Ports;

public interface IZoneUnlockReadPort
{
    Task<IReadOnlyList<UnlockedZoneInfo>> GetZonesUnlockedInRangeAsync(
        int previousLevel, int newLevel, CancellationToken ct = default);
}
