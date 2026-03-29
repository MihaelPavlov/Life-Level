namespace LifeLevel.Modules.Adventure.Dungeons.Application.DTOs;

public class CompleteFloorResult
{
    public int CompletedFloor { get; set; }
    public int RewardXp { get; set; }
    public int CurrentFloor { get; set; }
    public int TotalFloors { get; set; }
    public bool IsFullyCleared { get; set; }
}

public class ChoosePathResult
{
    public Guid PathId { get; set; }
    public string PathName { get; set; } = string.Empty;
    public Guid? LeadsToNodeId { get; set; }
    public int RewardXp { get; set; }
    public DateTime ChosenAt { get; set; }
}
