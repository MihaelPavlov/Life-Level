using LifeLevel.Modules.Character.Application.DTOs;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

using CharacterEntity = LifeLevel.Modules.Character.Domain.Entities.Character;

namespace LifeLevel.Modules.Character.Application.UseCases;

public class TitleService(
    DbContext db,
    IBossDefeatedCountReadPort bossPort,
    IStreakReadPort streakPort,
    IDailyQuestReadPort questPort,
    IEventPublisher events)
{

    public async Task<TitlesAndRanksResponse> GetTitlesAndRanksAsync(Guid userId, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>()
            .FirstOrDefaultAsync(c => c.UserId == userId, ct)
            ?? throw new InvalidOperationException("Character not found.");

        var earnedTitleIds = await db.Set<CharacterTitle>()
            .Where(ct2 => ct2.CharacterId == character.Id)
            .Select(ct2 => ct2.TitleId)
            .ToHashSetAsync(ct);

        var allTitles = await db.Set<Title>()
            .OrderBy(t => t.SortOrder)
            .ToListAsync(ct);

        var bossCount = await bossPort.GetDefeatedCountAsync(userId, ct);
        var streak = await streakPort.GetCurrentStreakAsync(userId, ct);
        var questCount = await questPort.CountCompletedDailyQuestsAsync(userId, ct);
        var currentStreakDays = streak?.Current ?? 0;

        var earnedTitles = new List<TitleDto>();
        var lockedTitles = new List<TitleDto>();

        foreach (var title in allTitles)
        {
            var isEarned = earnedTitleIds.Contains(title.Id);
            var isEquipped = character.EquippedTitleId == title.Id;
            var dto = new TitleDto(title.Id, title.Emoji, title.Name, title.UnlockCondition, isEarned, isEquipped);

            if (isEarned)
                earnedTitles.Add(dto);
            else
                lockedTitles.Add(dto);
        }

        var currentRank = await ComputeRankAsync(bossCount, ct);
        var nextRankThreshold = await GetNextRankThresholdAsync(currentRank, ct);

        var rankProgression = new RankProgressionDto(
            CurrentRank: currentRank,
            BossesDefeated: bossCount,
            BossesRequiredForNextRank: nextRankThreshold?.BossesRequired ?? bossCount,
            BossesRemainingForNextRank: nextRankThreshold.HasValue
                ? Math.Max(0, nextRankThreshold.Value.BossesRequired - bossCount)
                : 0,
            NextRank: nextRankThreshold?.Rank
        );

        string activeEmoji = string.Empty;
        string activeName = string.Empty;

        if (character.EquippedTitleId.HasValue)
        {
            var equipped = allTitles.FirstOrDefault(t => t.Id == character.EquippedTitleId.Value);
            if (equipped != null)
            {
                activeEmoji = equipped.Emoji;
                activeName = equipped.Name;
            }
        }

        return new TitlesAndRanksResponse(activeEmoji, activeName, rankProgression, earnedTitles, lockedTitles);
    }

    public async Task<TitleDto> EquipTitleAsync(Guid userId, Guid titleId, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>()
            .FirstOrDefaultAsync(c => c.UserId == userId, ct)
            ?? throw new InvalidOperationException("Character not found.");

        var characterTitle = await db.Set<CharacterTitle>()
            .Include(ct2 => ct2.Title)
            .FirstOrDefaultAsync(ct2 => ct2.CharacterId == character.Id && ct2.TitleId == titleId, ct)
            ?? throw new InvalidOperationException("Title not earned.");

        character.EquippedTitleId = titleId;
        character.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        var title = characterTitle.Title;
        return new TitleDto(title.Id, title.Emoji, title.Name, title.UnlockCondition, IsEarned: true, IsEquipped: true);
    }

    public async Task CheckAndGrantTitlesAsync(Guid userId, CancellationToken ct = default)
    {
        var character = await db.Set<CharacterEntity>()
            .FirstOrDefaultAsync(c => c.UserId == userId, ct);
        if (character == null) return;

        var alreadyEarnedIds = await db.Set<CharacterTitle>()
            .Where(ct2 => ct2.CharacterId == character.Id)
            .Select(ct2 => ct2.TitleId)
            .ToHashSetAsync(ct);

        var allTitles = await db.Set<Title>().ToListAsync(ct);

        var bossCount = await bossPort.GetDefeatedCountAsync(userId, ct);
        var streak = await streakPort.GetCurrentStreakAsync(userId, ct);
        var questCount = await questPort.CountCompletedDailyQuestsAsync(userId, ct);
        var currentStreakDays = streak?.Current ?? 0;

        bool anyGranted = false;
        foreach (var title in allTitles)
        {
            if (alreadyEarnedIds.Contains(title.Id)) continue;

            if (EvaluateCriteria(title.UnlockCriteria, bossCount, currentStreakDays, questCount, character.Rank))
            {
                db.Set<CharacterTitle>().Add(new CharacterTitle
                {
                    Id = Guid.NewGuid(),
                    CharacterId = character.Id,
                    TitleId = title.Id,
                    EarnedAt = DateTime.UtcNow,
                });
                anyGranted = true;
            }
        }

        // Update rank based on boss defeats
        var computedRank = await ComputeRankAsync(bossCount, ct);
        bool rankChanged = character.Rank != computedRank;
        if (rankChanged)
        {
            character.Rank = computedRank;
            character.UpdatedAt = DateTime.UtcNow;
        }

        if (anyGranted || rankChanged)
            await db.SaveChangesAsync(ct);

        if (rankChanged)
            await events.PublishAsync(new CharacterRankChangedEvent(userId, computedRank), ct);
    }

    private static bool EvaluateCriteria(string criteria, int bossCount, int streakDays, int questCount, string rankName)
    {
        if (criteria.StartsWith("BossesDefeated:") &&
            int.TryParse(criteria["BossesDefeated:".Length..], out var bossThreshold))
            return bossCount >= bossThreshold;

        if (criteria.StartsWith("StreakDays:") &&
            int.TryParse(criteria["StreakDays:".Length..], out var streakThreshold))
            return streakDays >= streakThreshold;

        if (criteria.StartsWith("QuestsCompleted:") &&
            int.TryParse(criteria["QuestsCompleted:".Length..], out var questThreshold))
            return questCount >= questThreshold;

        if (criteria.StartsWith("Rank:"))
        {
            var requiredRank = criteria["Rank:".Length..];
            return rankName == requiredRank;
        }

        return false;
    }

    private async Task<string> ComputeRankAsync(int bossCount, CancellationToken ct)
    {
        var thresholds = await db.Set<RankThreshold>()
            .OrderByDescending(r => r.BossesRequired)
            .ToListAsync(ct);
        var match = thresholds.FirstOrDefault(t => bossCount >= t.BossesRequired);
        return match?.Rank ?? "Novice";
    }

    private async Task<(string Rank, int BossesRequired)?> GetNextRankThresholdAsync(string current, CancellationToken ct)
    {
        var thresholds = await db.Set<RankThreshold>()
            .OrderBy(r => r.BossesRequired)
            .ToListAsync(ct);
        var idx = thresholds.FindIndex(t => t.Rank == current);
        if (idx < 0 || idx >= thresholds.Count - 1) return null;
        var next = thresholds[idx + 1];
        return (next.Rank, next.BossesRequired);
    }
}
