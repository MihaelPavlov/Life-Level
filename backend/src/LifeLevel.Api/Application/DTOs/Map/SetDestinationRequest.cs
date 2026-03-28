namespace LifeLevel.Api.Application.DTOs.Map;

public class SetDestinationRequest
{
    public Guid DestinationNodeId { get; set; }
}

public class DebugAddDistanceRequest
{
    public double Km { get; set; }
}

public class DebugAdjustLevelRequest
{
    public int Delta { get; set; } // +1 or -1
}

public record DebugSetXpRequest(long Xp);
