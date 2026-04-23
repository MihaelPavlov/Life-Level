namespace LifeLevel.Modules.WorldZone.Domain.Exceptions;

public class RegionLockedException : Exception
{
    public string RegionName { get; }
    public int LevelRequirement { get; }

    public RegionLockedException(string regionName, int levelRequirement)
        : base($"Region '{regionName}' requires character level {levelRequirement}.")
    {
        RegionName = regionName;
        LevelRequirement = levelRequirement;
    }
}
