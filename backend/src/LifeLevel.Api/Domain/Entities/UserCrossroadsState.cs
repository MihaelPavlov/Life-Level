namespace LifeLevel.Api.Domain.Entities;

public class UserCrossroadsState
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public Guid CrossroadsId { get; set; }
    public Crossroads Crossroads { get; set; } = null!;
    public Guid UserMapProgressId { get; set; }
    public UserMapProgress UserMapProgress { get; set; } = null!;
    public Guid? ChosenPathId { get; set; }
    public CrossroadsPath? ChosenPath { get; set; }
    public DateTime? ChosenAt { get; set; }
}
