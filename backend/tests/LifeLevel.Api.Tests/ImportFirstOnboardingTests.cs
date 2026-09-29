using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Activity.Application.UseCases;
using LifeLevel.Modules.Character.Application.DTOs;
using LifeLevel.Modules.Character.Application.UseCases;
using LifeLevel.Modules.Character.Domain;
using LifeLevel.Modules.Character.Domain.Data;
using LifeLevel.Modules.Integrations.Application;
using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.Modules.Integrations.Application.Mappers;
using LifeLevel.Modules.Integrations.Application.UseCases;
using LifeLevel.SharedKernel.DTOs;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using ActivityEntity = LifeLevel.Modules.Activity.Domain.Entities.Activity;
using CharacterEntity = LifeLevel.Modules.Character.Domain.Entities.Character;

namespace LifeLevel.Api.Tests;

public class ImportFirstOnboardingTests
{
    // ── Class detection ──────────────────────────────────────────────────────

    private static ActivityMixEntry Mix(ActivityType t, int workouts, int minutes) => new(t, workouts, minutes);

    [Fact]
    public void Detect_FewerThanThreeWorkouts_IsInsufficient()
    {
        var r = ClassDetector.Detect([Mix(ActivityType.Running, 1, 30), Mix(ActivityType.Yoga, 1, 25)]);
        Assert.Equal(ClassDetectionState.Insufficient, r.State);
        Assert.Null(r.RecommendedClass);
    }

    [Fact]
    public void Detect_OneSportAboveThreeQuarters_IsDevotedWithTrait()
    {
        var r = ClassDetector.Detect([Mix(ActivityType.Running, 18, 864), Mix(ActivityType.Yoga, 1, 35)]);
        Assert.Equal(ClassDetectionState.Devoted, r.State);
        Assert.Equal("Ranger", r.RecommendedClass);
        Assert.Equal("devoted:Running", r.TraitKey);
    }

    [Fact]
    public void Detect_SwimBikeRunEachAboveFifteenPercent_IsStormrunner()
    {
        var r = ClassDetector.Detect([
            Mix(ActivityType.Running, 6, 270), Mix(ActivityType.Cycling, 4, 300), Mix(ActivityType.Swimming, 5, 200)]);
        Assert.Equal(ClassDetectionState.Multisport, r.State);
        Assert.Equal("Stormrunner", r.RecommendedClass);
    }

    [Fact]
    public void Detect_GymAndYogaNearlyEven_IsSpellbladeHybrid()
    {
        var r = ClassDetector.Detect([Mix(ActivityType.Gym, 4, 220), Mix(ActivityType.Yoga, 6, 210)]);
        Assert.Equal(ClassDetectionState.Hybrid, r.State);
        Assert.Equal("Spellblade", r.RecommendedClass);
        Assert.Equal(["Warrior", "Mystic"], r.Alternatives.OrderByDescending(a => a == "Warrior").ToList());
    }

    [Fact]
    public void Detect_NothingAboveFortyPercent_IsBalancedSentinel()
    {
        var r = ClassDetector.Detect([
            Mix(ActivityType.Running, 3, 135), Mix(ActivityType.Cycling, 1, 75), Mix(ActivityType.Gym, 3, 165),
            Mix(ActivityType.Yoga, 4, 140), Mix(ActivityType.Hiking, 1, 150), Mix(ActivityType.Swimming, 3, 120)]);
        Assert.Equal(ClassDetectionState.Balanced, r.State);
        Assert.Equal("Sentinel", r.RecommendedClass);
    }

    [Fact]
    public void Detect_CloseWithoutHybridPair_IsCloseCall()
    {
        // Swimming vs climbing: 50/50 but no hybrid exists for Tidecaller+Cragborn.
        var r = ClassDetector.Detect([Mix(ActivityType.Swimming, 3, 150), Mix(ActivityType.Climbing, 3, 150)]);
        Assert.Equal(ClassDetectionState.Close, r.State);
        Assert.Contains(r.RecommendedClass, new[] { "Tidecaller", "Cragborn" });
        Assert.Single(r.Alternatives);
    }

    [Fact]
    public void Detect_OneGroupLeads_IsClearWithRunnerUp()
    {
        var r = ClassDetector.Detect([
            Mix(ActivityType.Running, 10, 450), Mix(ActivityType.Cycling, 4, 300), Mix(ActivityType.Gym, 4, 220),
            Mix(ActivityType.Hiking, 1, 150), Mix(ActivityType.Yoga, 3, 105)]);
        Assert.Equal(ClassDetectionState.Clear, r.State);
        Assert.Equal("Ranger", r.RecommendedClass);
        Assert.Equal("Warrior", r.Alternatives[0]);
    }

    // ── History import (ActivityService) ─────────────────────────────────────

    [Fact]
    public async Task ImportHistorical_HalvesXp_AppliesStats_BanksDistance_SkipsLiveSideEffects()
    {
        var ports = new Ports();
        await using var db = NewDb();
        var service = NewActivityService(db, ports);

        var result = await service.ImportHistoricalActivityAsync(
            Guid.NewGuid(), ActivityType.Running, 30, 5, null, null, "strava:1", DateTime.UtcNow.AddDays(-3));

        // Live XP for 30 min / 5 km running = 30*3*1.2 + 5*10 = 158 → history = 79.
        Assert.Equal(79, result.XpGained);
        Assert.Equal(0, ports.Xp.Calls);
        Assert.Equal(1, ports.Stats.Calls);
        Assert.Equal(5, ports.Distance.Km);
        Assert.Equal(0, ports.Quests.Calls);
        Assert.Equal(0, ports.Events.Calls);
        var stored = await db.Set<ActivityEntity>().SingleAsync();
        Assert.Equal(79, stored.XpGained);
        Assert.Equal("strava:1", stored.ExternalId);
    }

    [Fact]
    public async Task LiveActivity_AppliesClassMultipliersToStatGains()
    {
        var ports = new Ports { ClassBonus = new ClassBonusSnapshot(1f, 1.3f, 1.2f, 1f, 1f, null) };
        await using var db = NewDb();
        var service = NewActivityService(db, ports);

        await service.LogExternalActivityAsync(Guid.NewGuid(), ActivityType.Running, 30, 5, null, null, "ext-1", DateTime.UtcNow);

        // Running gives END +2, AGI +1 → Ranger ×1.3 / ×1.2 → END 3, AGI 1.
        Assert.Equal(3, ports.Stats.Last!.End);
        Assert.Equal(1, ports.Stats.Last!.Agi);
    }

    [Fact]
    public async Task LiveActivity_DevotedTrait_AddsTenPercentXpOnlyWhileSportDominates()
    {
        var characterId = Guid.NewGuid();
        await using var db = NewDb();
        for (var i = 0; i < 4; i++)
            db.Set<ActivityEntity>().Add(new ActivityEntity
            {
                Id = Guid.NewGuid(), CharacterId = characterId, Type = ActivityType.Running,
                DurationMinutes = 40, LoggedAt = DateTime.UtcNow.AddDays(-i - 1),
            });
        await db.SaveChangesAsync();

        var devoted = new Ports { CharacterId = characterId, ClassBonus = new ClassBonusSnapshot(1, 1, 1, 1, 1, "devoted:Running") };
        var plain = new Ports { CharacterId = characterId, ClassBonus = ClassBonusSnapshot.Neutral };

        var withTrait = await NewActivityService(db, devoted)
            .LogExternalActivityAsync(Guid.NewGuid(), ActivityType.Running, 30, 5, null, null, "a", DateTime.UtcNow);
        var without = await NewActivityService(db, plain)
            .LogExternalActivityAsync(Guid.NewGuid(), ActivityType.Running, 30, 5, null, null, "b", DateTime.UtcNow);

        Assert.Equal((long)Math.Round(without.XpGained * 1.1), withTrait.XpGained);
        Assert.False(ActivityService.IsDevotionActive("devoted:Running", ActivityType.Running,
            [new(ActivityType.Running, 2, 60), new(ActivityType.Gym, 3, 120)]));
    }

    // ── Onboarding import (Integrations) ─────────────────────────────────────

    [Fact]
    public async Task OnboardingImport_AwardsXpOnce_SkipsStepWalks_AndDedupes()
    {
        await using var db = NewDb();
        var (userId, _) = await SeedCharacter(db, setupComplete: false);
        var xp = new CapturingXp();
        var service = NewOnboardingImport(db, xp);

        var request = new OnboardingImportRequest
        {
            Source = "health",
            Activities =
            [
                Dto("healthconnect:a", "Running", daysAgo: 2),
                Dto("healthconnect:b", "Yoga", daysAgo: 5),
                Dto("healthconnect:steps:2026-09-20", "Walking", daysAgo: 6),
                Dto("healthconnect:old", "Running", daysAgo: 45),
            ],
        };

        var first = await service.ImportAsync(userId, request);
        var second = await service.ImportAsync(userId, request);

        Assert.Equal(2, first.Imported);
        Assert.Equal(100, first.TotalXp); // stub history XP is 50 per workout
        Assert.Equal(0, second.Imported);
        Assert.Equal(1, xp.Calls); // second run had nothing new, so no award
    }

    [Fact]
    public async Task OnboardingImport_AfterSetup_IsRejected()
    {
        await using var db = NewDb();
        var (userId, _) = await SeedCharacter(db, setupComplete: true);
        var service = NewOnboardingImport(db, new CapturingXp());

        await Assert.ThrowsAsync<OnboardingImportService.SetupAlreadyCompleteException>(() =>
            service.ImportAsync(userId, new OnboardingImportRequest { Source = "health" }));
    }

    // ── Setup (Character) ────────────────────────────────────────────────────

    [Fact]
    public async Task Setup_HybridClass_RequiresDetection()
    {
        await using var db = NewDb();
        db.CharacterClasses.AddRange(CharacterClasses.SeedData);
        var (userId, _) = await SeedCharacter(db, setupComplete: false);
        var service = new CharacterService(db, new NoopEvents(), new NoopTitles());

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            service.SetupAsync(userId, new CharacterSetupRequest(CharacterClasses.Spellblade.Id, "🥷"), detection: null));
    }

    [Fact]
    public async Task Setup_KeepingDevotedClass_GrantsTrait_AndStarterXpOnce()
    {
        await using var db = NewDb();
        db.CharacterClasses.AddRange(CharacterClasses.SeedData);
        var (userId, characterId) = await SeedCharacter(db, setupComplete: false);
        var service = new CharacterService(db, new NoopEvents(), new NoopTitles());
        var detection = ClassDetector.Detect([new(ActivityType.Running, 18, 864), new(ActivityType.Yoga, 1, 35)]);

        await service.SetupAsync(userId, new CharacterSetupRequest(CharacterClasses.Ranger.Id, "🏹", "detected"), detection);

        var character = await db.Characters.SingleAsync(c => c.Id == characterId);
        Assert.Equal("devoted:Running", character.TraitKey);
        Assert.Equal(500, character.Xp);
    }

    [Fact]
    public async Task Setup_ChangingAwayFromDetectedClass_DropsTrait()
    {
        await using var db = NewDb();
        db.CharacterClasses.AddRange(CharacterClasses.SeedData);
        var (userId, characterId) = await SeedCharacter(db, setupComplete: false);
        var service = new CharacterService(db, new NoopEvents(), new NoopTitles());
        var detection = ClassDetector.Detect([new(ActivityType.Running, 18, 864), new(ActivityType.Yoga, 1, 35)]);

        await service.SetupAsync(userId, new CharacterSetupRequest(CharacterClasses.Mystic.Id, "🧘", "changed"), detection);

        Assert.Null((await db.Characters.SingleAsync(c => c.Id == characterId)).TraitKey);
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private static AppDbContext NewDb() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static async Task<(Guid UserId, Guid CharacterId)> SeedCharacter(AppDbContext db, bool setupComplete)
    {
        var userId = Guid.NewGuid();
        var characterId = Guid.NewGuid();
        db.Characters.Add(new CharacterEntity { Id = characterId, UserId = userId, IsSetupComplete = setupComplete });
        await db.SaveChangesAsync();
        return (userId, characterId);
    }

    private static ExternalActivityDto Dto(string id, string type, int daysAgo) => new()
    {
        Provider = IntegrationProviders.HealthConnect,
        ExternalId = id,
        ActivityType = type,
        DurationMinutes = 30,
        DistanceKm = type == "Running" ? 5 : null,
        PerformedAt = DateTime.UtcNow.AddDays(-daysAgo),
    };

    private static OnboardingImportService NewOnboardingImport(AppDbContext db, CapturingXp xp)
    {
        var health = new HealthSyncService(db, new DbCharacterIdReadPort(db), new StubActivityLogPort(), new StubActivityExternalIdReadPort());
        var options = Options.Create(new StravaOptions());
        var http = new HttpClient();
        var pending = new PendingActivityService(db, new DbCharacterIdReadPort(db), health,
            new StubActivityGainPreviewPort(), new LifeLevel.SharedKernel.Ports.NoOpNotificationPort());
        var strava = new StravaWebhookService(db, http, new StravaOAuthService(db, http, options), health, pending, options);
        return new OnboardingImportService(health, strava, new DbCharacterInfo(db), xp);
    }

    private static ActivityService NewActivityService(AppDbContext db, Ports p) => new(
        db, p.Xp, p.Stats, new StubCharacterIdReadPort(p.CharacterId), p.Events, new NullStreak(), p.Quests,
        p.Distance, new NoGear(), new NoItems(), new NoZones(), new NoTutorial(),
        NullLogger<ActivityService>.Instance, classBonus: new FixedClassBonus(p.ClassBonus));

    private sealed class Ports
    {
        public Guid CharacterId { get; init; } = Guid.NewGuid();
        public ClassBonusSnapshot ClassBonus { get; init; } = ClassBonusSnapshot.Neutral;
        public CapturingXp Xp { get; } = new();
        public CapturingStats Stats { get; } = new();
        public CapturingEvents Events { get; } = new();
        public CapturingQuests Quests { get; } = new();
        public CapturingDistance Distance { get; } = new();
    }

    private sealed class CapturingXp : ICharacterXpPort
    {
        public int Calls { get; private set; }
        public Task<XpAwardResult> AwardXpAsync(Guid userId, string source, string sourceEmoji, string description, long xp, CancellationToken ct = default)
        {
            Calls++;
            return Task.FromResult(new XpAwardResult(false, 1, 1));
        }
    }

    private sealed class CapturingStats : ICharacterStatPort
    {
        public int Calls { get; private set; }
        public StatGains? Last { get; private set; }
        public Task ApplyStatGainsAsync(Guid userId, StatGains gains, CancellationToken ct = default)
        {
            Calls++;
            Last = gains;
            return Task.CompletedTask;
        }
    }

    private sealed class CapturingEvents : IEventPublisher
    {
        public int Calls { get; private set; }
        public Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default) where TEvent : IDomainEvent
        {
            Calls++;
            return Task.CompletedTask;
        }
    }

    private sealed class CapturingQuests : IQuestProgressPort
    {
        public int Calls { get; private set; }
        public Task<QuestActivityResult> UpdateProgressFromActivityAsync(Guid userId, ActivityType activityType,
            int durationMinutes, double? distanceKm, int? calories, CancellationToken ct = default)
        {
            Calls++;
            return Task.FromResult(new QuestActivityResult([], false, 0));
        }
    }

    private sealed class CapturingDistance : IWorldZoneDistancePort
    {
        public double Km { get; private set; }
        public Task<ActiveEncounterPortDto?> AddDistanceAsync(Guid userId, double km, CancellationToken ct = default)
        {
            Km += km;
            return Task.FromResult<ActiveEncounterPortDto?>(null);
        }
    }

    private sealed class FixedClassBonus(ClassBonusSnapshot snapshot) : ICharacterClassBonusReadPort
    {
        public Task<ClassBonusSnapshot> GetClassBonusAsync(Guid userId, CancellationToken ct = default) => Task.FromResult(snapshot);
    }

    private sealed class DbCharacterInfo(AppDbContext db) : ICharacterInfoPort
    {
        public async Task<CharacterInfoDto?> GetByUserIdAsync(Guid userId, CancellationToken ct = default)
        {
            var c = await db.Characters.FirstOrDefaultAsync(x => x.UserId == userId, ct);
            return c is null ? null : new CharacterInfoDto(c.Id, c.IsSetupComplete);
        }
    }

    private sealed class NullStreak : IStreakReadPort
    {
        public Task<StreakReadDto?> GetCurrentStreakAsync(Guid userId, CancellationToken ct = default) => Task.FromResult<StreakReadDto?>(null);
    }

    private sealed class NoGear : IGearBonusReadPort
    {
        public Task<GearBonuses> GetEquippedBonusesAsync(Guid userId, CancellationToken ct = default) => Task.FromResult(GearBonuses.Empty);
    }

    private sealed class NoItems : ILevelUpItemGrantPort
    {
        public Task<IReadOnlyList<GrantedItemInfo>> EvaluateAndGrantAsync(Guid userId, int previousLevel, int newLevel, CancellationToken ct = default)
            => Task.FromResult<IReadOnlyList<GrantedItemInfo>>([]);
    }

    private sealed class NoZones : IZoneUnlockReadPort
    {
        public Task<IReadOnlyList<UnlockedZoneInfo>> GetZonesUnlockedInRangeAsync(int previousLevel, int newLevel, CancellationToken ct = default)
            => Task.FromResult<IReadOnlyList<UnlockedZoneInfo>>([]);
    }

    private sealed class NoTutorial : ICharacterTutorialPort
    {
        public Task<int> AdvanceIfOnStepAsync(Guid characterId, int expectedStep, CancellationToken ct = default) => Task.FromResult(expectedStep);
    }

    private sealed class NoopEvents : IEventPublisher
    {
        public Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default) where TEvent : IDomainEvent => Task.CompletedTask;
    }

    private sealed class NoopTitles : ITitleUnlockPort
    {
        public Task<bool> UnlockAsync(Guid characterId, string titleKey, CancellationToken ct = default) => Task.FromResult(false);
    }
}
