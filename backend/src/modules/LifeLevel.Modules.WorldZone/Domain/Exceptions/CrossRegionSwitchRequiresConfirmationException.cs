namespace LifeLevel.Modules.WorldZone.Domain.Exceptions;

public class CrossRegionSwitchRequiresConfirmationException : Exception
{
    public string CurrentRegionName { get; }
    public string DestinationRegionName { get; }

    public CrossRegionSwitchRequiresConfirmationException(string currentRegionName, string destinationRegionName)
        : base($"Switching from '{currentRegionName}' to '{destinationRegionName}' requires explicit confirmation.")
    {
        CurrentRegionName = currentRegionName;
        DestinationRegionName = destinationRegionName;
    }
}
