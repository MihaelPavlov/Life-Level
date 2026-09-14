using LifeLevel.Modules.Quest.Domain.Events;
using LifeLevel.Modules.Streak.Domain.Events;
using LifeLevel.Modules.Talents.Application.UseCases;
using LifeLevel.Modules.Talents.Domain;
using LifeLevel.SharedKernel.Events;

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

/// <summary>Credits Talent Coins + Crystals for every boss defeat.</summary>
public class TalentCurrencyBossHandler(TalentService talents) : IEventHandler<BossDefeatedEvent>
{
    public async Task HandleAsync(BossDefeatedEvent e, CancellationToken ct = default)
    {
        await talents.AddCoinsAsync(e.UserId, TalentEconomy.CoinsPerBossDefeat, ct);
        await talents.AddCrystalsAsync(e.UserId, TalentEconomy.CrystalsPerBossDefeat, ct);
    }
}

/// <summary>Every character level grants Talent Coins.</summary>
public class TalentCurrencyLevelUpHandler(TalentService talents) : IEventHandler<CharacterLeveledUpEvent>
{
    public async Task HandleAsync(CharacterLeveledUpEvent e, CancellationToken ct = default)
    {
        var levels = Math.Max(1, e.NewLevel - e.PreviousLevel);
        await talents.AddCoinsAsync(e.UserId, TalentEconomy.CoinsPerLevelUp * levels, ct);
    }
}

/// <summary>Credits Talent Crystals for every completed zone/region.</summary>
public class TalentCurrencyZoneHandler(TalentService talents) : IEventHandler<ZoneCompletedEvent>
{
    public Task HandleAsync(ZoneCompletedEvent e, CancellationToken ct = default) =>
        talents.AddCrystalsAsync(e.UserId, TalentEconomy.CrystalsPerZoneCompletion, ct);
}

/// <summary>Credits Talent Crystals for every claimed reward (login reward, chest opens).</summary>
public class TalentCurrencyRewardHandler(TalentService talents) : IEventHandler<RewardClaimedEvent>
{
    public Task HandleAsync(RewardClaimedEvent e, CancellationToken ct = default) =>
        talents.AddCrystalsAsync(e.UserId, TalentEconomy.CrystalsPerRewardClaim, ct);
}

/// <summary>Records when a streak breaks, so "Steel Resolve" can grant comeback XP.</summary>
public class TalentStreakBrokenHandler(TalentService talents) : IEventHandler<StreakBrokenEvent>
{
    public Task HandleAsync(StreakBrokenEvent e, CancellationToken ct = default) =>
        talents.MarkStreakBrokenAsync(e.UserId, ct);
}
