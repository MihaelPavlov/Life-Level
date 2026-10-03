namespace LifeLevel.SharedKernel.Ports;

/// <summary>Publishes data-free refresh hints after a committed user mutation.</summary>
public interface IUserStateChangePort
{
    Task PublishUserAsync(Guid userId, IReadOnlyCollection<string> areas, CancellationToken ct = default);
}
