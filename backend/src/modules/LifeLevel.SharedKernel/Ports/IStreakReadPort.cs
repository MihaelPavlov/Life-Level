namespace LifeLevel.SharedKernel.Ports;

public record StreakReadDto(int Current, int Longest, int ShieldsAvailable);

public interface IStreakReadPort
{
    Task<StreakReadDto?> GetCurrentStreakAsync(Guid userId, CancellationToken ct = default);
}
