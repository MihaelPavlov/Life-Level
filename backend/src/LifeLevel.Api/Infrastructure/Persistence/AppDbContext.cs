using LifeLevel.Modules.Activity.Domain.Entities;
using LifeLevel.Modules.Activity.Infrastructure;
using LifeLevel.Modules.Adventure.Dungeons.Domain.Entities;
using LifeLevel.Modules.Adventure.Dungeons.Infrastructure;
using LifeLevel.Modules.Adventure.Encounters.Domain.Entities;
using LifeLevel.Modules.Adventure.Encounters.Infrastructure;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Character.Infrastructure;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.Identity.Infrastructure;
using LifeLevel.Modules.LoginReward.Domain.Entities;
using LifeLevel.Modules.LoginReward.Infrastructure;
using LifeLevel.Modules.Map.Domain.Entities;
using LifeLevel.Modules.Map.Infrastructure;
using LifeLevel.Modules.Quest.Domain.Entities;
using LifeLevel.Modules.Quest.Infrastructure;
using LifeLevel.Modules.Streak.Domain.Entities;
using LifeLevel.Modules.Streak.Infrastructure;
using LifeLevel.Modules.WorldZone.Domain.Entities;
using LifeLevel.Modules.WorldZone.Infrastructure;
using LifeLevel.Modules.Items.Domain.Entities;
using LifeLevel.Modules.Items.Infrastructure;
using LifeLevel.Modules.Integrations.Domain.Entities;
using LifeLevel.Modules.Integrations.Infrastructure;
using LifeLevel.Modules.Achievements.Domain.Entities;
using LifeLevel.Modules.Achievements.Infrastructure;
using LifeLevel.Modules.Notifications;
using LifeLevel.Modules.Notifications.Domain.Entities;
using Microsoft.EntityFrameworkCore;

// Type aliases needed to avoid name conflicts between entity types and their module namespace segments
using WorldZoneEntity = LifeLevel.Modules.WorldZone.Domain.Entities.WorldZone;
using CrossroadsEntity = LifeLevel.Modules.Adventure.Dungeons.Domain.Entities.Crossroads;

namespace LifeLevel.Api.Infrastructure.Persistence;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    // Identity
    public DbSet<User> Users => Set<User>();
    public DbSet<UserRingItem> UserRingItems => Set<UserRingItem>();

    // Character
    public DbSet<Character> Characters => Set<Character>();
    public DbSet<CharacterClass> CharacterClasses => Set<CharacterClass>();
    public DbSet<XpHistoryEntry> XpHistoryEntries => Set<XpHistoryEntry>();
    public DbSet<Title> Titles => Set<Title>();
    public DbSet<CharacterTitle> CharacterTitles => Set<CharacterTitle>();

    // Activity
    public DbSet<Activity> Activities => Set<Activity>();

    // Quest
    public DbSet<Quest> Quests => Set<Quest>();
    public DbSet<UserQuestProgress> UserQuestProgress => Set<UserQuestProgress>();

    // Streak
    public DbSet<Streak> Streaks => Set<Streak>();

    // LoginReward
    public DbSet<LoginReward> LoginRewards => Set<LoginReward>();

    // WorldZone (overworld)
    public DbSet<World> Worlds => Set<World>();
    public DbSet<Region> Regions => Set<Region>();
    public DbSet<WorldZoneEntity> WorldZones => Set<WorldZoneEntity>();
    public DbSet<WorldZoneEdge> WorldZoneEdges => Set<WorldZoneEdge>();
    public DbSet<UserWorldProgress> UserWorldProgresses => Set<UserWorldProgress>();
    public DbSet<UserZoneUnlock> UserZoneUnlocks => Set<UserZoneUnlock>();
    public DbSet<UserPathChoice> UserPathChoices => Set<UserPathChoice>();

    // WorldZone — Chest + Dungeon (v3 inline on WorldZone)
    public DbSet<UserWorldChestState> UserWorldChestStates => Set<UserWorldChestState>();
    public DbSet<WorldZoneDungeonFloor> WorldZoneDungeonFloors => Set<WorldZoneDungeonFloor>();
    public DbSet<UserWorldDungeonState> UserWorldDungeonStates => Set<UserWorldDungeonState>();
    public DbSet<UserWorldDungeonFloorState> UserWorldDungeonFloorStates => Set<UserWorldDungeonFloorState>();

    // Map
    public DbSet<MapNode> MapNodes => Set<MapNode>();
    public DbSet<MapEdge> MapEdges => Set<MapEdge>();
    public DbSet<UserMapProgress> UserMapProgresses => Set<UserMapProgress>();
    public DbSet<UserNodeUnlock> UserNodeUnlocks => Set<UserNodeUnlock>();

    // Adventure.Encounters
    public DbSet<Boss> Bosses => Set<Boss>();
    public DbSet<Chest> Chests => Set<Chest>();
    public DbSet<UserBossState> UserBossStates => Set<UserBossState>();
    public DbSet<UserChestState> UserChestStates => Set<UserChestState>();

    // Adventure.Dungeons
    public DbSet<DungeonPortal> DungeonPortals => Set<DungeonPortal>();
    public DbSet<DungeonFloor> DungeonFloors => Set<DungeonFloor>();
    public DbSet<CrossroadsEntity> Crossroads => Set<CrossroadsEntity>();
    public DbSet<CrossroadsPath> CrossroadsPaths => Set<CrossroadsPath>();
    public DbSet<UserDungeonState> UserDungeonStates => Set<UserDungeonState>();
    public DbSet<UserCrossroadsState> UserCrossroadsStates => Set<UserCrossroadsState>();

    // Items
    public DbSet<Item> Items => Set<Item>();
    public DbSet<CharacterItem> CharacterItems => Set<CharacterItem>();
    public DbSet<EquipmentSlot> EquipmentSlots => Set<EquipmentSlot>();
    public DbSet<ItemDropRule> ItemDropRules => Set<ItemDropRule>();

    // Integrations
    public DbSet<ExternalActivityRecord> ExternalActivityRecords => Set<ExternalActivityRecord>();
    public DbSet<StravaConnection> StravaConnections => Set<StravaConnection>();
    public DbSet<GarminConnection> GarminConnections => Set<GarminConnection>();

    // Achievements
    public DbSet<Achievement> Achievements => Set<Achievement>();
    public DbSet<UserAchievement> UserAchievements => Set<UserAchievement>();

    // Notifications
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<NotificationLog> NotificationLogs => Set<NotificationLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // ── Per-module EF configurations ──────────────────────────────────────────
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(IdentityModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(CharacterModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(StreakModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(QuestModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ActivityModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(LoginRewardModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(WorldZoneModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(MapModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(EncountersModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(DungeonsModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ItemsModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(IntegrationsModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AchievementsModule).Assembly);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(NotificationsModule).Assembly);

        // ── Cross-module FK relationships ─────────────────────────────────────────

        // Character → User (Identity)
        modelBuilder.Entity<Character>()
            .HasOne<User>()
            .WithOne()
            .HasForeignKey<Character>(c => c.UserId);

        // Activity → Character
        modelBuilder.Entity<Activity>()
            .HasOne<Character>()
            .WithMany()
            .HasForeignKey(a => a.CharacterId);

        // Activity: partial unique index on (CharacterId, ExternalId) for deduplication
        modelBuilder.Entity<Activity>()
            .HasIndex(a => new { a.CharacterId, a.ExternalId })
            .IsUnique()
            .HasFilter("\"ExternalId\" IS NOT NULL");

        // Streak → User
        modelBuilder.Entity<Streak>()
            .HasOne<User>()
            .WithOne()
            .HasForeignKey<Streak>(s => s.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // LoginReward → User
        modelBuilder.Entity<LoginReward>()
            .HasOne<User>()
            .WithOne()
            .HasForeignKey<LoginReward>(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // UserQuestProgress → User
        modelBuilder.Entity<UserQuestProgress>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // WorldZone module cross-module: UserWorldProgress/UserZoneUnlock → User
        modelBuilder.Entity<UserWorldProgress>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(p => p.UserId);

        modelBuilder.Entity<UserZoneUnlock>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(u => u.UserId);

        // Map module cross-module: MapNode → WorldZone, UserMapProgress/UserNodeUnlock → User
        modelBuilder.Entity<MapNode>()
            .HasOne<WorldZoneEntity>()
            .WithMany()
            .HasForeignKey(n => n.WorldZoneId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<UserMapProgress>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(p => p.UserId);

        modelBuilder.Entity<UserNodeUnlock>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(u => u.UserId);

        // Adventure.Encounters cross-module: Boss/Chest → MapNode; UserBossState/UserChestState → User/UserMapProgress
        // Boss.NodeId is nullable — world-zone bosses are bridged via Boss.WorldZoneId
        // and carry no local-map node. Legacy local-map bosses still populate NodeId.
        modelBuilder.Entity<Boss>()
            .HasOne<MapNode>()
            .WithOne()
            .HasForeignKey<Boss>(b => b.NodeId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Chest>()
            .HasOne<MapNode>()
            .WithOne()
            .HasForeignKey<Chest>(c => c.NodeId);

        modelBuilder.Entity<UserBossState>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(s => s.UserId);

        modelBuilder.Entity<UserBossState>()
            .HasOne<UserMapProgress>()
            .WithMany()
            .HasForeignKey(s => s.UserMapProgressId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<UserChestState>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(s => s.UserId);

        modelBuilder.Entity<UserChestState>()
            .HasOne<UserMapProgress>()
            .WithMany()
            .HasForeignKey(s => s.UserMapProgressId);

        // Adventure.Dungeons cross-module: DungeonPortal/Crossroads → MapNode; states → User/UserMapProgress
        modelBuilder.Entity<DungeonPortal>()
            .HasOne<MapNode>()
            .WithOne()
            .HasForeignKey<DungeonPortal>(d => d.NodeId);

        modelBuilder.Entity<CrossroadsEntity>()
            .HasOne<MapNode>()
            .WithOne()
            .HasForeignKey<CrossroadsEntity>(c => c.NodeId);

        modelBuilder.Entity<CrossroadsPath>()
            .HasOne<MapNode>()
            .WithMany()
            .HasForeignKey(p => p.LeadsToNodeId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<UserDungeonState>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(s => s.UserId);

        modelBuilder.Entity<UserDungeonState>()
            .HasOne<UserMapProgress>()
            .WithMany()
            .HasForeignKey(s => s.UserMapProgressId);

        modelBuilder.Entity<UserCrossroadsState>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(s => s.UserId);

        modelBuilder.Entity<UserCrossroadsState>()
            .HasOne<UserMapProgress>()
            .WithMany()
            .HasForeignKey(s => s.UserMapProgressId);

        // Items cross-module: CharacterItem/EquipmentSlot → Character
        modelBuilder.Entity<CharacterItem>()
            .HasOne<Character>()
            .WithMany()
            .HasForeignKey(ci => ci.CharacterId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<EquipmentSlot>()
            .HasOne<Character>()
            .WithMany()
            .HasForeignKey(s => s.CharacterId)
            .OnDelete(DeleteBehavior.Cascade);

        // Integrations cross-module: ExternalActivityRecord → Character
        modelBuilder.Entity<ExternalActivityRecord>()
            .HasOne<Character>()
            .WithMany()
            .HasForeignKey(r => r.CharacterId)
            .OnDelete(DeleteBehavior.Cascade);

        // Integrations cross-module: StravaConnection → User
        modelBuilder.Entity<StravaConnection>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(s => s.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Integrations cross-module: GarminConnection → User
        modelBuilder.Entity<GarminConnection>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(g => g.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Achievements cross-module: UserAchievement → User
        modelBuilder.Entity<UserAchievement>()
            .HasOne<LifeLevel.Modules.Identity.Domain.Entities.User>()
            .WithMany()
            .HasForeignKey(a => a.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Notifications cross-module: DeviceToken → User
        modelBuilder.Entity<DeviceToken>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(t => t.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        // Notifications cross-module: NotificationLog → User
        modelBuilder.Entity<NotificationLog>()
            .HasOne<User>()
            .WithMany()
            .HasForeignKey(l => l.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
