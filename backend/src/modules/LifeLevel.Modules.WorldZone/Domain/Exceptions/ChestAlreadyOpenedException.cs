namespace LifeLevel.Modules.WorldZone.Domain.Exceptions;

/// <summary>
/// Thrown when a user attempts to open a chest zone they've already opened.
/// Controllers translate this to 409 Conflict.
/// </summary>
public class ChestAlreadyOpenedException : Exception
{
    public ChestAlreadyOpenedException(string message) : base(message) { }
}
