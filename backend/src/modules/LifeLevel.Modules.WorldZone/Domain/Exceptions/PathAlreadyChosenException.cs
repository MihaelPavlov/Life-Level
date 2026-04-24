namespace LifeLevel.Modules.WorldZone.Domain.Exceptions;

/// <summary>
/// Thrown when a user attempts to travel to a branch zone after having
/// already committed to the sibling branch at the same crossroads.
/// Controllers should translate this to 409 Conflict.
/// </summary>
public class PathAlreadyChosenException : Exception
{
    public PathAlreadyChosenException(string message) : base(message) { }
}
