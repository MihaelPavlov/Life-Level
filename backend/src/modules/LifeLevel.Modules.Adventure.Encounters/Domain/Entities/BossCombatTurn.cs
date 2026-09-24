namespace LifeLevel.Modules.Adventure.Encounters.Domain.Entities;

/// <summary>An immutable audit record for one workout-driven personal boss turn.</summary>
public class BossCombatTurn
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserBossStateId { get; set; }
    public UserBossState UserBossState { get; set; } = null!;
    public Guid ActivityId { get; set; }
    public string ActivityType { get; set; } = string.Empty;
    public int DurationMinutes { get; set; }
    public double DistanceKm { get; set; }
    public int Calories { get; set; }
    public int RawWorkoutDamage { get; set; }
    public int Attack { get; set; }
    public int Defense { get; set; }
    public int Health { get; set; }
    public int Power { get; set; }
    public double DamageMultiplier { get; set; }
    public double BossActiveDamagePct { get; set; }
    public int BossArmor { get; set; }
    public double BossMitigation { get; set; }
    public int DamageDealt { get; set; }
    public int BossHpAfter { get; set; }
    public int BossCounterattackRaw { get; set; }
    public double PlayerMitigation { get; set; }
    public int DamageTaken { get; set; }
    public int PlayerHpAfter { get; set; }
    public bool BossDefeated { get; set; }
    public bool PlayerDefeated { get; set; }
    public string? SkipReason { get; set; }
    public DateTime OccurredAt { get; set; }
}
