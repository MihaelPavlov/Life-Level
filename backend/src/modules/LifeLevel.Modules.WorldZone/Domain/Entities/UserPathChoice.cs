namespace LifeLevel.Modules.WorldZone.Domain.Entities;

/// <summary>
/// Records a user's one-time choice at a Crossroads zone. Unique per
/// (UserId, CrossroadsZoneId). Once a branch is chosen, the sibling branch is
/// permanently locked for that user at that crossroads.
/// </summary>
public class UserPathChoice
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid CrossroadsZoneId { get; set; }
    public Guid ChosenBranchZoneId { get; set; }
    public DateTime ChosenAt { get; set; } = DateTime.UtcNow;
}
