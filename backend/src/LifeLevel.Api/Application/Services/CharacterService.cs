using LifeLevel.Api.Application.DTOs.Character;
using LifeLevel.Api.Application.DTOs.CharacterClass;
using LifeLevel.Api.Domain.Entities;
using LifeLevel.Api.Domain.Enums;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Services;

public class CharacterService(AppDbContext db)
{
    private const int StarterXpReward = 500;

    public async Task<IReadOnlyList<CharacterClassResponse>> GetAllClassesAsync()
    {
        return await db.CharacterClasses
            .Where(c => c.IsActive)
            .OrderBy(c => c.Name)
            .Select(c => new CharacterClassResponse(
                c.Id, c.Name, c.Emoji, c.Description, c.Tagline,
                c.StrMultiplier, c.EndMultiplier, c.AgiMultiplier, c.FlxMultiplier, c.StaMultiplier))
            .ToListAsync();
    }

    public async Task<CharacterSetupResponse> SetupAsync(Guid userId, CharacterSetupRequest req)
    {
        var character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId)
            ?? throw new InvalidOperationException("Character not found.");

        if (character.IsSetupComplete)
            throw new InvalidOperationException("Character setup is already complete.");

        var characterClass = await db.CharacterClasses.FirstOrDefaultAsync(c => c.Id == req.ClassId && c.IsActive)
            ?? throw new InvalidOperationException("Invalid class selected.");

        character.ClassId = req.ClassId;
        character.AvatarEmoji = req.AvatarEmoji;
        character.IsSetupComplete = true;
        character.Xp += StarterXpReward;
        character.UpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();
        await RecordXpAsync(character, "CharacterSetup", "✨", "Character created · Starter bonus", StarterXpReward);

        return new CharacterSetupResponse(
            character.Id,
            characterClass.Name,
            characterClass.Emoji,
            character.AvatarEmoji!,
            character.Xp,
            character.Level,
            character.IsSetupComplete
        );
    }

    public async Task<CharacterProfileResponse> GetProfileAsync(Guid userId)
    {
        var user = await db.Users
            .Include(u => u.Character)
                .ThenInclude(c => c!.Class)
            .Include(u => u.Character)
                .ThenInclude(c => c!.Activities)
            .FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new InvalidOperationException("User not found.");

        var character = user.Character!;

        var weekStart = DateTime.UtcNow.Date.AddDays(-(int)DateTime.UtcNow.DayOfWeek);
        var weeklyActivities = character.Activities
            .Where(a => a.LoggedAt >= weekStart)
            .ToList();

        var weeklyRuns = weeklyActivities.Count(a => a.Type == ActivityType.Running);
        var weeklyDistance = weeklyActivities.Sum(a => a.DistanceKm);
        var weeklyXp = weeklyActivities.Sum(a => a.XpGained);

        return new CharacterProfileResponse(
            Username: user.Username,
            AvatarEmoji: character.AvatarEmoji,
            ClassName: character.Class?.Name,
            ClassEmoji: character.Class?.Emoji,
            Rank: character.Rank.ToString(),
            Level: character.Level,
            Xp: character.Xp,
            XpForCurrentLevel: XpAtLevelStart(character.Level),
            XpForNextLevel: XpAtLevelStart(character.Level + 1),
            Strength: character.Strength,
            Endurance: character.Endurance,
            Agility: character.Agility,
            Flexibility: character.Flexibility,
            Stamina: character.Stamina,
            WeeklyRuns: weeklyRuns,
            WeeklyDistanceKm: weeklyDistance,
            WeeklyXpEarned: weeklyXp,
            CurrentStreak: 0,
            AvailableStatPoints: character.AvailableStatPoints
        );
    }

    public async Task<(bool LeveledUp, int NewLevel)> RecordXpAsync(Character character, string source, string sourceEmoji, string description, long xp)
    {
        var entry = new XpHistoryEntry
        {
            CharacterId = character.Id,
            Source = source,
            SourceEmoji = sourceEmoji,
            Description = description,
            Xp = xp,
            EarnedAt = DateTime.UtcNow,
        };
        db.XpHistoryEntries.Add(entry);
        await db.SaveChangesAsync();
        return await CheckAndApplyLevelUpsAsync(character.Id);
    }

    private async Task<(bool LeveledUp, int NewLevel)> CheckAndApplyLevelUpsAsync(Guid characterId)
    {
        var character = await db.Characters.FindAsync(characterId);
        if (character == null) return (false, 0);

        bool leveled = false;
        while (character.Xp >= XpAtLevelStart(character.Level + 1))
        {
            character.Level++;
            character.AvailableStatPoints++;
            character.UpdatedAt = DateTime.UtcNow;
            leveled = true;
        }

        if (leveled)
            await db.SaveChangesAsync();

        return (leveled, character.Level);
    }

    public async Task SpendStatPointAsync(Guid userId, string stat)
    {
        var character = await db.Characters.FirstOrDefaultAsync(c => c.UserId == userId)
            ?? throw new InvalidOperationException("Character not found.");

        if (character.AvailableStatPoints <= 0)
            throw new InvalidOperationException("No available stat points.");

        switch (stat.ToUpperInvariant())
        {
            case "STR": character.Strength    = Math.Min(100, character.Strength    + 5); break;
            case "END": character.Endurance   = Math.Min(100, character.Endurance   + 5); break;
            case "AGI": character.Agility     = Math.Min(100, character.Agility     + 5); break;
            case "FLX": character.Flexibility = Math.Min(100, character.Flexibility + 5); break;
            case "STA": character.Stamina     = Math.Min(100, character.Stamina     + 5); break;
            default: throw new InvalidOperationException(
                $"Unknown stat '{stat}'. Valid values: STR, END, AGI, FLX, STA.");
        }

        character.AvailableStatPoints--;
        character.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync();
    }

    public async Task<List<XpHistoryEntryResponse>> GetXpHistoryAsync(Guid userId)
    {
        var character = await db.Characters
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (character == null)
            return [];

        var entries = await db.XpHistoryEntries
            .Where(e => e.CharacterId == character.Id)
            .OrderByDescending(e => e.EarnedAt)
            .Take(50)
            .Select(e => new XpHistoryEntryResponse(
                e.Id,
                e.Source,
                e.SourceEmoji,
                e.Description,
                e.Xp,
                e.EarnedAt))
            .ToListAsync();

        return entries;
    }

    /// XP total accumulated at the START of a given level.
    /// Formula: level * (level - 1) / 2 * 300
    /// Level 1 starts at 0, level 2 at 300, level 3 at 900, level 10 at 13500, etc.
    private static long XpAtLevelStart(int level) =>
        (long)level * (level - 1) / 2 * 300;
}
