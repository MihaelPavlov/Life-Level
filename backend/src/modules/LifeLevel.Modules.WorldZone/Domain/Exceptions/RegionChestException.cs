namespace LifeLevel.Modules.WorldZone.Domain.Exceptions;

public class RegionChestException(string code, string message) : Exception(message)
{
    public string Code { get; } = code;
}
