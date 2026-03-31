using LifeLevel.Modules.Items.Domain.Enums;

namespace LifeLevel.Modules.Items.Domain.Entities;

public class ItemDropRule
{
    public Guid Id { get; set; }
    public Guid ItemId { get; set; }
    public Item Item { get; set; } = null!;
    public AcquisitionTrigger TriggerType { get; set; }
    public string TriggerParameters { get; set; } = "{}";
    public int DropChancePct { get; set; } = 100;
    public bool IsEnabled { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
