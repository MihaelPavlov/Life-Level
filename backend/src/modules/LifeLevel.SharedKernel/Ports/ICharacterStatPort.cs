namespace LifeLevel.SharedKernel.Ports;

public record StatGains(int Str, int End, int Agi, int Flx, int Sta);

public interface ICharacterStatPort
{
    Task ApplyStatGainsAsync(Guid userId, StatGains gains, CancellationToken ct = default);
}
