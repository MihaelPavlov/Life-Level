namespace LifeLevel.SharedKernel.Ports;

public interface IUserReadPort
{
    Task<string?> GetUsernameAsync(Guid userId, CancellationToken ct = default);
}
