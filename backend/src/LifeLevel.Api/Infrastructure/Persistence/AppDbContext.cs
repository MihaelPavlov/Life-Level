using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Infrastructure.Persistence;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Character> Characters => Set<Character>();
    public DbSet<Activity> Activities => Set<Activity>();
    public DbSet<UserRingItem> UserRingItems => Set<UserRingItem>();
    public DbSet<CharacterClass> CharacterClasses => Set<CharacterClass>();

    // Map
    public DbSet<MapNode> MapNodes => Set<MapNode>();
    public DbSet<MapEdge> MapEdges => Set<MapEdge>();
    public DbSet<Boss> Bosses => Set<Boss>();
    public DbSet<Chest> Chests => Set<Chest>();
    public DbSet<DungeonPortal> DungeonPortals => Set<DungeonPortal>();
    public DbSet<DungeonFloor> DungeonFloors => Set<DungeonFloor>();
    public DbSet<Crossroads> Crossroads => Set<Crossroads>();
    public DbSet<CrossroadsPath> CrossroadsPaths => Set<CrossroadsPath>();
    public DbSet<UserMapProgress> UserMapProgresses => Set<UserMapProgress>();
    public DbSet<UserNodeUnlock> UserNodeUnlocks => Set<UserNodeUnlock>();
    public DbSet<UserBossState> UserBossStates => Set<UserBossState>();
    public DbSet<UserChestState> UserChestStates => Set<UserChestState>();
    public DbSet<UserDungeonState> UserDungeonStates => Set<UserDungeonState>();
    public DbSet<UserCrossroadsState> UserCrossroadsStates => Set<UserCrossroadsState>();
    public DbSet<XpHistoryEntry> XpHistoryEntries => Set<XpHistoryEntry>();
    public DbSet<Streak> Streaks => Set<Streak>();
    public DbSet<LoginReward> LoginRewards => Set<LoginReward>();
    public DbSet<Quest> Quests => Set<Quest>();
    public DbSet<UserQuestProgress> UserQuestProgress => Set<UserQuestProgress>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // --- Existing entities ---
        modelBuilder.Entity<User>(e =>
        {
            e.HasKey(u => u.Id);
            e.HasIndex(u => u.Email).IsUnique();
            e.HasIndex(u => u.Username).IsUnique();
        });

        modelBuilder.Entity<Character>(e =>
        {
            e.HasKey(c => c.Id);
            e.HasOne(c => c.User)
             .WithOne(u => u.Character)
             .HasForeignKey<Character>(c => c.UserId);
            e.HasOne(c => c.Class)
             .WithMany(cc => cc.Characters)
             .HasForeignKey(c => c.ClassId)
             .IsRequired(false);
        });

        modelBuilder.Entity<CharacterClass>(e =>
        {
            e.HasKey(c => c.Id);
            e.HasIndex(c => c.Name).IsUnique();
        });

        modelBuilder.Entity<CharacterClass>().HasData(Domain.Data.CharacterClasses.SeedData);

        modelBuilder.Entity<Activity>(e =>
        {
            e.HasKey(a => a.Id);
            e.HasOne(a => a.Character)
             .WithMany(c => c.Activities)
             .HasForeignKey(a => a.CharacterId);
        });

        modelBuilder.Entity<UserRingItem>(e =>
        {
            e.HasKey(r => r.Id);
            e.HasOne(r => r.User)
             .WithMany(u => u.RingItems)
             .HasForeignKey(r => r.UserId)
             .OnDelete(DeleteBehavior.Cascade);
            e.Property(r => r.ItemType).HasConversion<string>();
        });

        // --- Map entities ---
        modelBuilder.Entity<MapNode>(e =>
        {
            e.HasKey(n => n.Id);
            e.Property(n => n.Type).HasConversion<string>();
            e.Property(n => n.Region).HasConversion<string>();
        });

        modelBuilder.Entity<MapEdge>(e =>
        {
            e.HasKey(me => me.Id);
            e.HasOne(me => me.FromNode)
             .WithMany(n => n.EdgesFrom)
             .HasForeignKey(me => me.FromNodeId)
             .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(me => me.ToNode)
             .WithMany(n => n.EdgesTo)
             .HasForeignKey(me => me.ToNodeId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Boss>(e =>
        {
            e.HasKey(b => b.Id);
            e.HasOne(b => b.Node)
             .WithOne(n => n.Boss)
             .HasForeignKey<Boss>(b => b.NodeId);
        });

        modelBuilder.Entity<Chest>(e =>
        {
            e.HasKey(c => c.Id);
            e.HasOne(c => c.Node)
             .WithOne(n => n.Chest)
             .HasForeignKey<Chest>(c => c.NodeId);
            e.Property(c => c.Rarity).HasConversion<string>();
        });

        modelBuilder.Entity<DungeonPortal>(e =>
        {
            e.HasKey(d => d.Id);
            e.HasOne(d => d.Node)
             .WithOne(n => n.DungeonPortal)
             .HasForeignKey<DungeonPortal>(d => d.NodeId);
        });

        modelBuilder.Entity<DungeonFloor>(e =>
        {
            e.HasKey(f => f.Id);
            e.HasOne(f => f.DungeonPortal)
             .WithMany(d => d.Floors)
             .HasForeignKey(f => f.DungeonPortalId);
            e.Property(f => f.RequiredActivity).HasConversion<string>();
        });

        modelBuilder.Entity<Crossroads>(e =>
        {
            e.HasKey(c => c.Id);
            e.HasOne(c => c.Node)
             .WithOne(n => n.Crossroads)
             .HasForeignKey<Crossroads>(c => c.NodeId);
        });

        modelBuilder.Entity<CrossroadsPath>(e =>
        {
            e.HasKey(p => p.Id);
            e.HasOne(p => p.Crossroads)
             .WithMany(c => c.Paths)
             .HasForeignKey(p => p.CrossroadsId);
            e.HasOne(p => p.LeadsToNode)
             .WithMany()
             .HasForeignKey(p => p.LeadsToNodeId)
             .IsRequired(false)
             .OnDelete(DeleteBehavior.Restrict);
            e.Property(p => p.Difficulty).HasConversion<string>();
        });

        modelBuilder.Entity<UserMapProgress>(e =>
        {
            e.HasKey(p => p.Id);
            e.HasOne(p => p.User)
             .WithMany()
             .HasForeignKey(p => p.UserId);
            e.HasOne(p => p.CurrentNode)
             .WithMany()
             .HasForeignKey(p => p.CurrentNodeId)
             .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(p => p.CurrentEdge)
             .WithMany()
             .HasForeignKey(p => p.CurrentEdgeId)
             .IsRequired(false)
             .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(p => p.DestinationNode)
             .WithMany()
             .HasForeignKey(p => p.DestinationNodeId)
             .IsRequired(false)
             .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<UserNodeUnlock>(e =>
        {
            e.HasKey(u => new { u.UserId, u.MapNodeId });
            e.HasOne(u => u.User)
             .WithMany()
             .HasForeignKey(u => u.UserId);
            e.HasOne(u => u.MapNode)
             .WithMany()
             .HasForeignKey(u => u.MapNodeId)
             .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(u => u.UserMapProgress)
             .WithMany(p => p.UnlockedNodes)
             .HasForeignKey(u => u.UserMapProgressId);
        });

        modelBuilder.Entity<UserBossState>(e =>
        {
            e.HasKey(s => s.Id);
            e.HasOne(s => s.User)
             .WithMany()
             .HasForeignKey(s => s.UserId);
            e.HasOne(s => s.Boss)
             .WithMany(b => b.UserStates)
             .HasForeignKey(s => s.BossId);
            e.HasOne(s => s.UserMapProgress)
             .WithMany(p => p.BossStates)
             .HasForeignKey(s => s.UserMapProgressId);
        });

        modelBuilder.Entity<UserChestState>(e =>
        {
            e.HasKey(s => s.Id);
            e.HasOne(s => s.User)
             .WithMany()
             .HasForeignKey(s => s.UserId);
            e.HasOne(s => s.Chest)
             .WithMany(c => c.UserStates)
             .HasForeignKey(s => s.ChestId);
            e.HasOne(s => s.UserMapProgress)
             .WithMany(p => p.ChestStates)
             .HasForeignKey(s => s.UserMapProgressId);
        });

        modelBuilder.Entity<UserDungeonState>(e =>
        {
            e.HasKey(s => s.Id);
            e.HasOne(s => s.User)
             .WithMany()
             .HasForeignKey(s => s.UserId);
            e.HasOne(s => s.DungeonPortal)
             .WithMany(d => d.UserStates)
             .HasForeignKey(s => s.DungeonPortalId);
            e.HasOne(s => s.UserMapProgress)
             .WithMany(p => p.DungeonStates)
             .HasForeignKey(s => s.UserMapProgressId);
        });

        modelBuilder.Entity<UserCrossroadsState>(e =>
        {
            e.HasKey(s => s.Id);
            e.HasOne(s => s.User)
             .WithMany()
             .HasForeignKey(s => s.UserId);
            e.HasOne(s => s.Crossroads)
             .WithMany(c => c.UserStates)
             .HasForeignKey(s => s.CrossroadsId);
            e.HasOne(s => s.UserMapProgress)
             .WithMany(p => p.CrossroadsStates)
             .HasForeignKey(s => s.UserMapProgressId);
            e.HasOne(s => s.ChosenPath)
             .WithMany()
             .HasForeignKey(s => s.ChosenPathId)
             .IsRequired(false)
             .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<XpHistoryEntry>(e =>
        {
            e.HasKey(x => x.Id);
            e.HasOne(x => x.Character)
             .WithMany()
             .HasForeignKey(x => x.CharacterId)
             .OnDelete(DeleteBehavior.Cascade);
            e.Property(x => x.Source).HasMaxLength(64).IsRequired();
            e.Property(x => x.SourceEmoji).HasMaxLength(16).IsRequired();
            e.Property(x => x.Description).HasMaxLength(256).IsRequired();
        });

        // --- Phase 2: Streak, LoginReward, Quest, UserQuestProgress ---

        modelBuilder.Entity<Streak>(e =>
        {
            e.HasKey(x => x.Id);
            e.HasOne(x => x.User)
             .WithOne(u => u.Streak)
             .HasForeignKey<Streak>(x => x.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<LoginReward>(e =>
        {
            e.HasKey(x => x.Id);
            e.HasOne(x => x.User)
             .WithOne(u => u.LoginReward)
             .HasForeignKey<LoginReward>(x => x.UserId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Quest>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.Type).HasConversion<string>();
            e.Property(x => x.Category).HasConversion<string>();
            e.Property(x => x.RequiredActivity).HasConversion<string?>();
        });

        modelBuilder.Entity<UserQuestProgress>(e =>
        {
            e.HasKey(x => x.Id);
            e.HasOne(x => x.User)
             .WithMany(u => u.QuestProgress)
             .HasForeignKey(x => x.UserId)
             .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Quest)
             .WithMany(q => q.UserProgress)
             .HasForeignKey(x => x.QuestId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        // Quest seed data
        modelBuilder.Entity<Quest>().HasData(Domain.Data.QuestSeedData.All);
    }
}
