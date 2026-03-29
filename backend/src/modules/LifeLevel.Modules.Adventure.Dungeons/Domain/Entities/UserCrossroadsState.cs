namespace LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;

public class UserCrossroadsState
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    // No User nav prop — cross-module
    public Guid CrossroadsId { get; set; }
    public Crossroads Crossroads { get; set; } = null!;
    public Guid UserMapProgressId { get; set; }
    // No UserMapProgress nav prop — cross-module
    public Guid? ChosenPathId { get; set; }
    public CrossroadsPath? ChosenPath { get; set; }
    public DateTime? ChosenAt { get; set; }
}
