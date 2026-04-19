namespace LifeLevel.SharedKernel.Contracts;

/// <summary>
/// Abstraction over DateTime.UtcNow for testability. Inject this instead of calling
/// DateTime.UtcNow directly when business logic depends on the current time.
/// </summary>
public interface ICurrentClock
{
    DateTime UtcNow { get; }
}

/// <summary>
/// Default implementation that returns the real system UTC time.
/// </summary>
public sealed class SystemClock : ICurrentClock
{
    public DateTime UtcNow => DateTime.UtcNow;
}
