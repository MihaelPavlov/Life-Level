namespace LifeLevel.SharedKernel.Events;

public record ChestOpenedEvent(Guid UserId, Guid ChestId) : IDomainEvent;
public record BossContributionEvent(Guid UserId, Guid ActivityId) : IDomainEvent;
public record GuildRaidContributionEvent(Guid UserId, Guid RaidId, Guid ActivityId) : IDomainEvent;
public record GuildRaidWonEvent(Guid UserId, Guid RaidId) : IDomainEvent;
public record RegionCompletedEvent(Guid UserId, Guid RegionId) : IDomainEvent;
