namespace LifeLevel.Modules.Items.Domain.Entities;

public class UserShopDailyState
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public DateTime RotationDateUtc { get; set; }
    public string ItemIdsJson { get; set; } = "[]";
    public DateTime RefreshedAtUtc { get; set; }
}
