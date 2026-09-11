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

/// <summary>Credits Talent Coins for every boss defeat.</summary>
public class TalentCurrencyBossHandler(TalentService talents) : IEventHandler<BossDefeatedEvent>
{
    public Task HandleAsync(BossDefeatedEvent e, CancellationToken ct = default) =>
        talents.AddCoinsAsync(e.UserId, TalentEconomy.CoinsPerBossDefeat, ct);
}

/// <summary>Every character level grants Talent Coins + a Talent Token.</summary>
public class TalentCurrencyLevelUpHandler(TalentService talents) : IEventHandler<CharacterLeveledUpEvent>
{
    public async Task HandleAsync(CharacterLeveledUpEvent e, CancellationToken ct = default)
    {
        var levels = Math.Max(1, e.NewLevel - e.PreviousLevel);
        await talents.AddCoinsAsync(e.UserId, TalentEconomy.CoinsPerLevelUp * levels, ct);
        await talents.AddTokensAsync(e.UserId, TalentEconomy.TokensPerLevelUp * levels, ct);
    }
}

/// <summary>Every rank-up grants Talent Tokens.</summary>
public class TalentCurrencyRankUpHandler(TalentService talents) : IEventHandler<CharacterRankChangedEvent>
{
    public Task HandleAsync(CharacterRankChangedEvent e, CancellationToken ct = default) =>
        talents.AddTokensAsync(e.UserId, TalentEconomy.TokensPerRankUp, ct);
}

/// <summary>Records when a streak breaks, so "Steel Resolve" can grant comeback XP.</summary>
public class TalentStreakBrokenHandler(TalentService talents) : IEventHandler<StreakBrokenEvent>
{
    public Task HandleAsync(StreakBrokenEvent e, CancellationToken ct = default) =>
        talents.MarkStreakBrokenAsync(e.UserId, ct);
}
