using LifeLevel.Modules.Character.Application.DTOs;
using LifeLevel.Modules.Character.Domain;
using LifeLevel.Modules.Character.Domain.Data;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

// Aliases to resolve the namespace vs type conflict
using CharacterEntity = LifeLevel.Modules.Character.Domain.Entities.Character;
using CharacterClassEntity = LifeLevel.Modules.Character.Domain.Entities.CharacterClass;
using XpHistoryEntryEntity = LifeLevel.Modules.Character.Domain.Entities.XpHistoryEntry;

namespace LifeLevel.Modules.Character.Application.UseCases;

public class CharacterService(
    DbContext db,
    IEventPublisher events,
    ITitleUnlockPort titleUnlock)
    : ICharacterXpPort, ICharacterStatPort, ICharacterLevelReadPort, ICharacterInfoPort, ICharacterIdReadPort, IInventorySlotReadPort, ICharacterTutorialPort
{
    private const int StarterXpReward = 500;

    // LL-035: final step of the 7-step onboarding tutorial. Steps are 0..7 inclusive
    // (0 = not started, 7 = finished). -1 = user skipped.
    private const int TutorialFinalStep = 7;

    public async Task<IReadOnlyList<CharacterClassResponse>> GetAllClassesAsync()
    {
        return await db.Set<CharacterClassEntity>()
            .Where(c => c.IsActive)
            .OrderBy(c => c.Name)
            .Select(c => new CharacterClassResponse(
                c.Id, c.Name, c.Emoji, c.Description, c.Tagline,
                c.StrMultiplier, c.EndMultiplier, c.AgiMultiplier, c.FlxMultiplier, c.StaMultiplier))
            .ToListAsync();
    }

    public async Task<CharacterSetupResponse> SetupAsync(Guid userId, CharacterSetupRequest req)
    {
        var character = await db.Set<CharacterEntity>().FirstOrDefaultAsync(c => c.UserId == userId)
            ?? throw new InvalidOperationException("Character not found.");

        if (character.IsSetupComplete)
            throw new InvalidOperationException("Character setup is already complete.");

        var characterClass = await db.Set<CharacterClassEntity>().FirstOrDefaultAsync(c => c.Id == req.ClassId && c.IsActive)
            ?? throw new InvalidOperationException("Invalid class selected.");

        character.ClassId = req.ClassId;
        character.AvatarEmoji = req.AvatarEmoji;
        character.IsSetupComplete = true;
        character.Xp += StarterXpReward;
        character.UpdatedAt = DateTime.UtcNow;

        await db.SaveChangesAsync();
        await AwardXpAsync(userId, "CharacterSetup", "✨", "Character created · Starter bonus", StarterXpReward);

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

    public async Task<CharacterProfileResponse> GetProfileAsync(Guid userId, CharacterProfileContext ctx)
    {
        var character = await db.Set<CharacterEntity>()
            .Include(c => c.Class)
            .FirstOrDefaultAsync(c => c.UserId == userId)
            ?? throw new InvalidOperationException("Character not found.");

        return new CharacterProfileResponse(
            Username: ctx.Username,
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
            WeeklyRuns: ctx.WeeklyStats.WeeklyRuns,
            WeeklyDistanceKm: ctx.WeeklyStats.WeeklyDistanceKm,
            WeeklyXpEarned: ctx.WeeklyStats.WeeklyXpEarned,
            CurrentStreak: ctx.Streak?.Current ?? 0,
            AvailableStatPoints: character.AvailableStatPoints,
            LongestStreak: ctx.Streak?.Longest ?? 0,
            ShieldsAvailable: ctx.Streak?.ShieldsAvailable ?? 0,
            DailyQuestsCompleted: ctx.DailyQuestsCompleted,
            LoginRewardAvailable: !ctx.HasClaimedLoginRewardToday,
            TutorialStep: character.TutorialStep,
            TutorialTopicsSeen: character.TutorialTopicsSeen
        );
    }

    /// <summary>Implements ICharacterXpPort</summary>
    public async Task<XpAwardResult> AwardXpAsync(Guid userId, string source, string sourceEmoji, string description, long xp, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>().FirstOrDefaultAsync(c => c.UserId == userId, ct);
        if (character == null) return XpAwardResult.None;

        character.Xp += xp;
        character.UpdatedAt = DateTime.UtcNow;

        var entry = new XpHistoryEntryEntity
        {
            CharacterId = character.Id,
            Source = source,
            SourceEmoji = sourceEmoji,
            Description = description,
            Xp = xp,
            EarnedAt = DateTime.UtcNow,
        };
        db.Set<XpHistoryEntryEntity>().Add(entry);
        await db.SaveChangesAsync(ct);
        var (leveled, previousLevel, newLevel) = await CheckAndApplyLevelUpsAsync(character.Id, ct);
        return new XpAwardResult(leveled, previousLevel, newLevel);
    }

    /// <summary>Implements ICharacterStatPort</summary>
    public async Task ApplyStatGainsAsync(Guid userId, StatGains gains, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>().FirstOrDefaultAsync(c => c.UserId == userId, ct);
        if (character == null) return;

        character.Strength    = Math.Min(100, character.Strength    + gains.Str);
        character.Endurance   = Math.Min(100, character.Endurance   + gains.End);
        character.Agility     = Math.Min(100, character.Agility     + gains.Agi);
        character.Flexibility = Math.Min(100, character.Flexibility + gains.Flx);
        character.Stamina     = Math.Min(100, character.Stamina     + gains.Sta);
        character.UpdatedAt   = DateTime.UtcNow;

        await db.SaveChangesAsync(ct);
    }

    /// <summary>Implements ICharacterLevelReadPort</summary>
    public async Task<int> GetLevelAsync(Guid userId, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>().FirstOrDefaultAsync(c => c.UserId == userId, ct);
        return character?.Level ?? 1;
    }


    public async Task<(bool LeveledUp, int PreviousLevel, int NewLevel)> CheckAndApplyLevelUpsAsync(Guid characterId, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>().FindAsync([characterId], ct);
        if (character == null) return (false, 0, 0);

        bool leveled = false;
        int previousLevel = character.Level;
        while (character.Xp >= XpAtLevelStart(character.Level + 1))
        {
            character.Level++;
            character.AvailableStatPoints++;
            character.MaxInventorySlots = character.Level switch
            {
                >= 50 => 100,
                >= 35 => 75,
                >= 25 => 60,
                >= 15 => 50,
                >= 10 => 40,
                >= 5  => 30,
                _     => 20,
            };
            character.UpdatedAt = DateTime.UtcNow;
            leveled = true;
        }

        if (leveled)
        {
            await db.SaveChangesAsync(ct);
            await events.PublishAsync(new CharacterLeveledUpEvent(character.UserId, previousLevel, character.Level), ct);
        }

        return (leveled, previousLevel, character.Level);
    }

    public async Task SpendStatPointAsync(Guid userId, string stat)
    {
        var character = await db.Set<CharacterEntity>().FirstOrDefaultAsync(c => c.UserId == userId)
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
        var character = await db.Set<CharacterEntity>()
            .FirstOrDefaultAsync(c => c.UserId == userId);

        if (character == null)
            return [];

        return await db.Set<XpHistoryEntryEntity>()
            .Where(e => e.CharacterId == character.Id)
            .OrderByDescending(e => e.EarnedAt)
            .Take(50)
            .Select(e => new XpHistoryEntryResponse(
                e.Id, e.Source, e.SourceEmoji, e.Description, e.Xp, e.EarnedAt))
            .ToListAsync();
    }

    /// <summary>Implements ICharacterInfoPort</summary>
    public async Task<CharacterInfoDto?> GetByUserIdAsync(Guid userId, CancellationToken ct = default)
    {
        var c = await db.Set<CharacterEntity>().FirstOrDefaultAsync(x => x.UserId == userId, ct);
        return c == null ? null : new CharacterInfoDto(c.Id, c.IsSetupComplete);
    }

    // ICharacterIdReadPort
    public async Task<Guid?> GetCharacterIdAsync(Guid userId, CancellationToken ct = default)
    {
        return await db.Set<CharacterEntity>()
            .Where(c => c.UserId == userId)
            .Select(c => (Guid?)c.Id)
            .FirstOrDefaultAsync(ct);
    }

    // IInventorySlotReadPort
    public async Task<int> GetMaxInventorySlotsAsync(Guid userId, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>().FirstOrDefaultAsync(c => c.UserId == userId, ct);
        return character?.MaxInventorySlots ?? 20;
    }

    // ───────────────────────────────────────────────────────────────────────
    // LL-035 Tutorial use cases
    // ───────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Advances the tutorial when the user acknowledges a coach mark.
    /// Rejects step 4 → 5 (that transition is port-only, triggered by a real activity log).
    /// No-op if the character is not on the expected prior step, or if the tutorial is
    /// already finished (step 7) or skipped (-1).
    /// </summary>
    public async Task<(int NewStep, int XpAwarded)> AdvanceTutorialAsync(Guid userId, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>().FirstOrDefaultAsync(c => c.UserId == userId, ct)
            ?? throw new InvalidOperationException("Character not found.");

        // Step 4 → 5 transition is port-only (must be triggered by an actual activity log).
        if (character.TutorialStep == 4)
            throw new InvalidOperationException("Step 4 advances only after logging a real activity.");

        return await AdvanceFromStepInternalAsync(character, character.TutorialStep, ct);
    }

    /// <summary>
    /// Skips the tutorial permanently. Sets TutorialStep = -1. Idempotent.
    /// Does not award XP and does not touch TutorialRewardsClaimed / TutorialTopicsSeen.
    /// </summary>
    public async Task SkipTutorialAsync(Guid userId, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>().FirstOrDefaultAsync(c => c.UserId == userId, ct)
            ?? throw new InvalidOperationException("Character not found.");

        if (character.TutorialStep == -1) return; // already skipped — idempotent

        character.TutorialStep = -1;
        character.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    /// <summary>
    /// Resets the tutorial so the user can replay it from the beginning.
    /// Does NOT reset TutorialRewardsClaimed — rewards are one-shot.
    /// Does NOT reset TutorialTopicsSeen.
    /// </summary>
    public async Task ReplayAllAsync(Guid userId, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>().FirstOrDefaultAsync(c => c.UserId == userId, ct)
            ?? throw new InvalidOperationException("Character not found.");

        character.TutorialStep = 0;
        character.TutorialCompletedAt = null;
        character.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    /// <summary>
    /// Marks a single topic as seen (sets its bit in TutorialTopicsSeen).
    /// Does not change TutorialStep. Throws when topic is unknown — the controller
    /// translates that to a 400 response.
    /// </summary>
    public async Task ReplayTopicAsync(Guid userId, string topic, CancellationToken ct = default)
    {
        var bit = TutorialTopic.BitForTopic(topic)
            ?? throw new InvalidOperationException($"Unknown tutorial topic '{topic}'.");

        var character = await db.Set<CharacterEntity>().FirstOrDefaultAsync(c => c.UserId == userId, ct)
            ?? throw new InvalidOperationException("Character not found.");

        var updated = character.TutorialTopicsSeen | bit;
        if (updated == character.TutorialTopicsSeen) return; // bit already set — no write

        character.TutorialTopicsSeen = updated;
        character.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
    }

    /// <summary>Implements ICharacterTutorialPort — called by ActivityService after a successful log.</summary>
    public async Task<int> AdvanceIfOnStepAsync(Guid characterId, int expectedStep, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>().FindAsync([characterId], ct);
        if (character == null) return 0; // missing character — treat as no-op

        if (character.TutorialStep != expectedStep)
            return character.TutorialStep; // wrong step — no-op

        var (newStep, _) = await AdvanceFromStepInternalAsync(character, expectedStep, ct);
        return newStep;
    }

    /// <summary>
    /// Shared advance logic used by both the controller-driven path (AdvanceTutorialAsync)
    /// and the port-driven path (AdvanceIfOnStepAsync). Caller MUST have already verified
    /// the character is on <paramref name="fromStep"/>.
    /// </summary>
    private async Task<(int NewStep, int XpAwarded)> AdvanceFromStepInternalAsync(
        CharacterEntity character, int fromStep, CancellationToken ct)
    {
        // No-op when outside the advancing window (already finished or skipped).
        if (fromStep < 0 || fromStep >= TutorialFinalStep)
            return (character.TutorialStep, 0);

        var newStep = fromStep + 1;
        character.TutorialStep = newStep;

        // Mark the topic bit for this step.
        var topicBit = TutorialTopic.TopicBitForStepAdvance(fromStep);
        if (topicBit != 0)
            character.TutorialTopicsSeen |= topicBit;

        // Award the step XP only on the first-ever pass through the tutorial.
        bool firstTime = !character.TutorialRewardsClaimed;
        int xpAwarded = firstTime ? TutorialStepRewards.GetXp(newStep) : 0;

        // Finishing the tutorial: stamp completion + flip the one-shot reward flag
        // so future replays never re-award XP or the Novice title.
        if (newStep == TutorialFinalStep)
        {
            if (character.TutorialCompletedAt == null)
                character.TutorialCompletedAt = DateTime.UtcNow;
            if (firstTime)
                character.TutorialRewardsClaimed = true;
        }

        character.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        // Award XP via the standard AwardXpAsync pipeline so XpHistory + level-up
        // events fire naturally. Only when firstTime (reward is one-shot).
        if (xpAwarded > 0)
            await AwardXpAsync(character.UserId, "Tutorial", "🎓", $"Tutorial step {newStep}", xpAwarded, ct);

        // Step-7 title hook (Novice Adventurer). Idempotent by port contract —
        // safe to call on any step-7 pass; the adapter no-ops if already owned.
        if (firstTime)
        {
            var titleKey = TutorialStepRewards.GetTitleKey(newStep);
            if (titleKey != null)
                await titleUnlock.UnlockAsync(character.Id, titleKey, ct);
        }

        return (newStep, xpAwarded);
    }

    /// <summary>
    /// Lightweight read used by the tutorial controller after mutations so the client
    /// can refresh without a full <c>/api/character/me</c> round-trip.
    /// </summary>
    public async Task<(int TutorialStep, int TutorialTopicsSeen)> GetTutorialStateAsync(
        Guid userId, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>().FirstOrDefaultAsync(c => c.UserId == userId, ct)
            ?? throw new InvalidOperationException("Character not found.");
        return (character.TutorialStep, character.TutorialTopicsSeen);
    }

    private static long XpAtLevelStart(int level) =>
        (long)level * (level - 1) / 2 * 300;
}
