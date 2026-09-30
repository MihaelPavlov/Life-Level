using LifeLevel.Modules.Quest.Domain.Events;
using LifeLevel.Modules.Streak.Domain.Events;
using LifeLevel.Modules.Talents.Application.UseCases;
using LifeLevel.Modules.Talents.Domain;
using LifeLevel.SharedKernel.Events;
using LifeLevel.SharedKernel.Ports;

namespace LifeLevel.Modules.Talents.Application.EventHandlers;

/// <summary>Credits Talent Coins for every logged activity.</summary>
public class TalentCurrencyActivityHandler(TalentService talents) : IEventHandler<ActivityLoggedEvent>
{
    public Task HandleAsync(ActivityLoggedEvent e, CancellationToken ct = default) =>
        talents.AddCoinsAsync(e.UserId, TalentEconomy.CoinsForActivity(e.DurationMinutes), ct);
}

/// <summary>Credits Talent Coins for every completed quest.</summary>
public class TalentCurrencyQuestHandler(TalentService talents) : IEventHandler<QuestCompletedEvent>
{
    public Task HandleAsync(QuestCompletedEvent e, CancellationToken ct = default) =>
        talents.AddCoinsAsync(e.UserId, TalentEconomy.CoinsPerQuestComplete, ct);
}

/// <summary>Credits Coins for every boss defeat.</summary>
public class TalentCurrencyBossHandler(TalentService talents) : IEventHandler<BossDefeatedEvent>
{
    public Task HandleAsync(BossDefeatedEvent e, CancellationToken ct = default) =>
        talents.AddCoinsAsync(e.UserId, TalentEconomy.CoinsPerBossDefeat, ct);
}

/// <summary>Every character level grants Coins and one Talent Crystal.</summary>
public class TalentCurrencyLevelUpHandler(
    TalentService talents,
    ILevelUpReceiptPort receipts) : IEventHandler<CharacterLeveledUpEvent>
{
    public async Task HandleAsync(CharacterLeveledUpEvent e, CancellationToken ct = default)
    {
        var levels = Math.Max(1, e.NewLevel - e.PreviousLevel);
        var coins = TalentEconomy.CoinsPerLevelUp * levels;
        await talents.AddCoinsAsync(e.UserId, coins, ct);
        var talentCrystals = TalentEconomy.TalentCrystalsPerLevel * levels;
        await talents.AddTalentCrystalsAsync(e.UserId, talentCrystals, ct);
        await receipts.AddCoinsAsync(e.ReceiptId, coins, ct);
        await receipts.AddTalentCrystalsAsync(e.ReceiptId, talentCrystals, ct);
    }
}

/// <summary>Gameplay chests grant Talent Crystals according to chest rarity.</summary>
public class TalentCurrencyChestHandler(TalentService talents) : IEventHandler<ChestOpenedEvent>
{
    public Task HandleAsync(ChestOpenedEvent e, CancellationToken ct = default) =>
        talents.AddTalentCrystalsAsync(
            e.UserId, TalentEconomy.TalentCrystalsForChest(e.Rarity), ct);
}

/// <summary>Records when a streak breaks, so "Steel Resolve" can grant comeback XP.</summary>
public class TalentStreakBrokenHandler(TalentService talents) : IEventHandler<StreakBrokenEvent>
{
    public Task HandleAsync(StreakBrokenEvent e, CancellationToken ct = default) =>
        talents.MarkStreakBrokenAsync(e.UserId, ct);
}
