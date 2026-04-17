---
tags: [lifelevel, backend]
aliases: [Domain Events, Event Bus, IEventPublisher]
---
# Cross-Module Events

> When direct coupling would create a cycle (or the side effect doesn't matter to the HTTP response), modules communicate via in-process domain events.

## Event contracts (in [[SharedKernel]])

```csharp
public interface IDomainEvent { }

public interface IEventHandler<TEvent> where TEvent : IDomainEvent
{
    Task HandleAsync(TEvent e, CancellationToken ct = default);
}

public interface IEventPublisher
{
    Task PublishAsync<TEvent>(TEvent e, CancellationToken ct = default)
        where TEvent : IDomainEvent;
}
```

## Implementation

`InProcessEventPublisher` (in SharedKernel/Events/):
- Resolves all `IEventHandler<TEvent>` from `IServiceProvider`
- Calls each handler sequentially
- No retries, no persistence, no outbox
- **Runs AFTER the DB save** (caller does `SaveChangesAsync()` then `PublishAsync`)

## Event catalog

| Event | Raised by | Consumed by | Purpose |
|-------|-----------|-------------|---------|
| `UserRegisteredEvent(userId)` | [[Identity]] | `CharacterCreatedHandler` (in [[Character]]) | Create initial Character row after registration |
| `CharacterLeveledUpEvent(userId, prevLevel, newLevel)` | [[Character]] | `TitleGrantHandler` (evaluates title criteria) | Grant level-based titles |
| `ActivityLoggedEvent(userId, activityId, type, duration, distance, calories)` | [[Activity]] | `StreakActivityHandler` (in [[Streak]]) + `QuestActivityHandler` (in [[Quest]]) | Update streak + quest progress |
| `QuestCompletedEvent(userId, questId, rewardXp)` | [[Quest]] | (listeners can hook here for analytics) | Informational |
| `AllDailyQuestsCompletedEvent(userId, bonusXp)` | [[Quest]] | (listeners can hook) | Fires when all 5 dailies done |
| `StreakBrokenEvent(userId, previousStreak)` | [[Streak]] | (listeners can hook, e.g. for motivational notification) | Streak broken |

## Limitation (documented in ARCHITECTURE.txt)

> [!warning] In-process delivery is **not guaranteed**.
> If `ActivityService` saves the activity, then publishes `ActivityLoggedEvent`, and the handler throws — the event is silently lost. The activity is persisted but streak/quest progress is not updated.
>
> **Acceptable at MVP** because handlers are simple DB writes and failures surface in logs.
>
> **Fix when triggered by incident:** transactional outbox pattern:
> 1. Write event as row in `OutboxMessages` table INSIDE the same `SaveChangesAsync`.
> 2. `IHostedService` background worker polls, delivers to handlers, deletes on success.
> 3. `OutboxMessages` columns: `Id, Type, Payload (JSON), CreatedAt, ProcessedAt`.

## When to add MediatR

Only if we need > 10 event types or pipeline behaviors (logging, validation, caching). Not yet.

## Related
- [[Architecture Overview]]
- [[SharedKernel]]
- Each raising module's note documents its events
