using LifeLevel.SharedKernel.Enums;

namespace LifeLevel.Modules.Activity.Domain.Entities;

public class Activity
{
    public Guid Id { get; set; }
    public Guid CharacterId { get; set; }

    public ActivityType Type { get; set; }
    public int DurationMinutes { get; set; }
    public double DistanceKm { get; set; }
    public int Calories { get; set; }
    public int? HeartRateAvg { get; set; }

    public string? ExternalId { get; set; }

    public long XpGained { get; set; }
    public int StrGained { get; set; }
    public int EndGained { get; set; }
    public int AgiGained { get; set; }
    public int FlxGained { get; set; }
    public int StaGained { get; set; }

    public int Steps { get; set; } = 0;

    public DateTime LoggedAt { get; set; } = DateTime.UtcNow;
}
