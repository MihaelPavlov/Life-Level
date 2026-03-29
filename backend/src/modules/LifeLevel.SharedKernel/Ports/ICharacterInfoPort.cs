namespace LifeLevel.SharedKernel.Ports;

public record CharacterInfoDto(Guid CharacterId, bool IsSetupComplete);

public interface ICharacterInfoPort
{
    Task<CharacterInfoDto?> GetByUserIdAsync(Guid userId, CancellationToken ct = default);
}
