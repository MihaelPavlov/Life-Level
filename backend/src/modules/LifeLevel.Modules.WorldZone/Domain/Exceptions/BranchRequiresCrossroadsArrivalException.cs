namespace LifeLevel.Modules.WorldZone.Domain.Exceptions;

/// <summary>
/// Thrown by <c>WorldZoneService.SetDestinationAsync</c> when the client
/// asks to set destination to a branch zone (<c>WorldZone.BranchOfId</c>
/// is set) while the user is not currently standing at the parent
/// crossroads. Branches are pickable only once the fork has been reached —
/// this keeps the "distance to destination" UX readable and reinforces the
/// physical "choose your path" moment.
/// </summary>
public class BranchRequiresCrossroadsArrivalException : Exception
{
    public string CrossroadsName { get; }
    public Guid CrossroadsZoneId { get; }

    public BranchRequiresCrossroadsArrivalException(
        string crossroadsName, Guid crossroadsZoneId)
        : base($"You must reach {crossroadsName} before picking a branch.")
    {
        CrossroadsName = crossroadsName;
        CrossroadsZoneId = crossroadsZoneId;
    }
}
