using LifeLevel.Api.Application.Realtime;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Infrastructure.Persistence;

public partial class AppDbContext
{
    private readonly Dictionary<Guid, HashSet<string>> _pendingUsers = new();
    private readonly Dictionary<Guid, HashSet<string>> _pendingGuilds = new();
    private readonly HashSet<string> _pendingGlobal = new(StringComparer.Ordinal);

    internal async Task FlushStateChangesAsync(CancellationToken ct)
    {
        if (stateChanges is null) return;
        try { await stateChanges.PublishAsync(_pendingUsers, _pendingGuilds, _pendingGlobal, ct); }
        catch (Exception ex)
        {
            stateChangeLogger?.LogWarning(ex, "Could not publish state change hints after commit.");
        }
        finally { ClearStateChanges(); }
    }

    internal void ClearStateChanges()
    {
        _pendingUsers.Clear();
        _pendingGuilds.Clear();
        _pendingGlobal.Clear();
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default) =>
        SaveChangesAsync(true, cancellationToken);

    public override async Task<int> SaveChangesAsync(
        bool acceptAllChangesOnSuccess, CancellationToken cancellationToken = default)
    {
        var changes = stateChanges is null ? [] : ChangeTracker.Entries()
            .Where(e => e.State is EntityState.Added or EntityState.Modified or EntityState.Deleted)
            .Select(e => new ChangedEntity(
                e.Metadata.ClrType.Name,
                GuidProperty(e, "UserId"),
                GuidProperty(e, "CharacterId"),
                GuidProperty(e, "UserBossStateId"),
                GuidProperty(e, "GuildId"),
                GuidProperty(e, "Id")))
            .ToArray();

        var saved = await base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
        if (saved == 0 || stateChanges is null || changes.Length == 0) return saved;

        try
        {
        var characterIds = changes.Where(c => c.CharacterId.HasValue)
            .Select(c => c.CharacterId!.Value).Distinct().ToList();
        var characterOwners = characterIds.Count == 0
            ? new Dictionary<Guid, Guid>()
            : await Characters.AsNoTracking().Where(c => characterIds.Contains(c.Id))
                .ToDictionaryAsync(c => c.Id, c => c.UserId, cancellationToken);
        var bossStateIds = changes.Where(c => c.UserBossStateId.HasValue)
            .Select(c => c.UserBossStateId!.Value).Distinct().ToList();
        var bossOwners = bossStateIds.Count == 0
            ? new Dictionary<Guid, Guid>()
            : await UserBossStates.AsNoTracking().Where(s => bossStateIds.Contains(s.Id))
                .ToDictionaryAsync(s => s.Id, s => s.UserId, cancellationToken);

        var users = new Dictionary<Guid, HashSet<string>>();
        var guilds = new Dictionary<Guid, HashSet<string>>();
        var global = new HashSet<string>(StringComparer.Ordinal);
        foreach (var change in changes)
        {
            var areas = AreasFor(change.Type);
            if (areas.Length == 0) continue;
            var userId = change.UserId;
            if (!userId.HasValue && change.CharacterId.HasValue
                && characterOwners.TryGetValue(change.CharacterId.Value, out var characterOwner))
                userId = characterOwner;
            if (!userId.HasValue && change.UserBossStateId.HasValue
                && bossOwners.TryGetValue(change.UserBossStateId.Value, out var bossOwner))
                userId = bossOwner;
            if (change.Type == "User" && !userId.HasValue) userId = change.Id;
            if (userId.HasValue) Add(users, userId.Value, areas);
            if (change.GuildId.HasValue) Add(guilds, change.GuildId.Value, areas);
            if (change.Type is "Activity" or "XpHistoryEntry" or "BossCombatTurn"
                or "EquipmentSlot" or "UserTalent" or "Streak" or "GuildRaidContribution")
                global.Add("leaderboard");
            if (!userId.HasValue && !change.GuildId.HasValue && !change.CharacterId.HasValue
                && !change.UserBossStateId.HasValue && IsGlobal(change.Type))
                global.UnionWith(areas);
        }
        if (users.Count > 0 || guilds.Count > 0 || global.Count > 0)
        {
            if (Database.CurrentTransaction != null)
            {
                foreach (var (id, areas) in users) Add(_pendingUsers, id, [.. areas]);
                foreach (var (id, areas) in guilds) Add(_pendingGuilds, id, [.. areas]);
                _pendingGlobal.UnionWith(global);
            }
            else await stateChanges.PublishAsync(users, guilds, global, cancellationToken);
        }
        }
        catch (Exception ex)
        {
            // State hints are best effort. A failed hint must not turn a saved reward
            // into an HTTP error that encourages the client to repeat the mutation.
            ClearStateChanges();
            stateChangeLogger?.LogWarning(ex, "Could not prepare state change hints after SaveChanges.");
        }
        return saved;
    }

    private static Guid? GuidProperty(Microsoft.EntityFrameworkCore.ChangeTracking.EntityEntry entry, string name)
    {
        if (entry.Metadata.FindProperty(name) is null) return null;
        return entry.Property(name).CurrentValue is Guid value && value != Guid.Empty ? value : null;
    }

    private static void Add(Dictionary<Guid, HashSet<string>> recipients, Guid id, string[] areas)
    {
        if (!recipients.TryGetValue(id, out var set)) recipients[id] = set = new(StringComparer.Ordinal);
        set.UnionWith(areas);
    }

    private static bool IsGlobal(string type) => type is
        "Achievement" or "Title" or "Talent" or "Season" or "SeasonRewardTier" or
        "Item" or "Boss" or "WorldZone" or "Region" or "Quest" or "TrailEncounterTemplate";

    private static string[] AreasFor(string type) => type switch
    {
        "Character" => ["character", "leaderboard", "achievements", "titles"],
        "XpHistoryEntry" => ["character", "leaderboard", "leaderboardChest", "achievements", "titles"],
        "LevelUpReceipt" => ["levelUps", "character", "inventory", "unlocks"],
        "UserAchievement" or "UserAchievementStageChest" => ["achievements", "rewards"],
        "CharacterTitle" or "CharacterUnlock" => ["titles", "unlocks"],
        "Activity" or "ExternalActivityRecord" => ["activity", "character", "quests", "streak", "achievements", "titles", "world", "bosses", "guild", "leaderboard", "leaderboardChest", "season", "modes"],
        "PendingActivity" => ["pendingWorkouts"],
        "UserQuestProgress" or "TaskRewardMilestoneClaim" => ["quests", "rewards", "titles"],
        "Streak" => ["streak", "achievements", "rewards"],
        "UserBossState" or "BossCombatTurn" => ["bosses", "achievements", "titles", "leaderboard"],
        "CharacterItem" or "EquipmentSlot" or "ShopPurchase" or "UserShopDailyState" => ["inventory", "character", "shop", "leaderboard"],
        "UserWorldProgress" or "UserZoneUnlock" or "UserWorldChestState" or "UserRegionChestClaim" or "UserMapProgress" or "UserNodeUnlock" or "UserPathChoice" or "UserWorldDungeonState" or "UserWorldDungeonFloorState" => ["world", "chests", "bosses"],
        "Guild" or "GuildMember" or "GuildRaid" or "GuildRaidContribution" or "GuildRaidVictoryAcknowledgement" or "GuildRaidExpiryAcknowledgement" => ["guild", "leaderboard"],
        "UserSeasonProgress" or "UserSeasonClaim" or "UserFounderPass" => ["season", "inventory", "character"],
        "UserTalent" or "UserTalentWallet" or "TalentDrawEntry" => ["talents", "character", "leaderboard"],
        "BurnChainRun" or "TreasureDelveRun" or "ModeRewardSettlement" => ["modes", "talents", "character"],
        "NotificationLog" or "NotificationPreference" => ["notifications"],
        "LeaderboardPass" => ["leaderboardChest"],
        "Achievement" => ["achievements", "rewards"],
        "Title" => ["titles"],
        "Talent" => ["talents"],
        "Season" or "SeasonRewardTier" => ["season"],
        "Item" => ["inventory", "shop"],
        "Boss" => ["bosses", "world"],
        "WorldZone" or "Region" or "TrailEncounterTemplate" => ["world"],
        "Quest" => ["quests"],
        _ => []
    };

    private sealed record ChangedEntity(string Type, Guid? UserId, Guid? CharacterId,
        Guid? UserBossStateId, Guid? GuildId, Guid? Id);
}
