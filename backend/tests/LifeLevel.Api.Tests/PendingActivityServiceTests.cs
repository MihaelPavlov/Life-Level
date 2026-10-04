using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Integrations.Application;
using LifeLevel.Modules.Integrations.Application.Mappers;
using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.Modules.Integrations.Application.UseCases;
using LifeLevel.Modules.Integrations.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class PendingActivityServiceTests
{
    private static readonly Guid UserId = Guid.NewGuid();
    private static readonly Guid CharacterId = Guid.NewGuid();

    private static AppDbContext CreateDb(string name) =>
        new(new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(name).Options);

    private static PendingActivityService CreateService(
        AppDbContext db, INotificationPort? notifications = null,
        IActivityExternalIdReadPort? externalIdRead = null)
    {
        var characterId = new StubCharacterIdReadPort(CharacterId);
        externalIdRead ??= new StubActivityExternalIdReadPort();
        var health = new HealthSyncService(db, characterId, new StubActivityLogPort(), externalIdRead);
        return new PendingActivityService(db, characterId, health, new StubActivityGainPreviewPort(),
            notifications ?? new NoOpNotificationPort(), externalIdRead);
    }

    private static ExternalActivityDto Run(string id, DateTime at, string provider = IntegrationProviders.Strava, int minutes = 38) => new()
    {
        Provider = provider,
        ExternalId = id,
        ActivityType = "Running",
        DurationMinutes = minutes,
        DistanceKm = 6.2,
        PerformedAt = at,
    };

    [Fact]
    public async Task Enqueue_AddsPendingWorkout_WithPreview()
    {
        var db = CreateDb(nameof(Enqueue_AddsPendingWorkout_WithPreview));
        var svc = CreateService(db);

        var added = await svc.EnqueueAsync(UserId, Run("strava:1", DateTime.UtcNow.AddHours(-1)));
        var list = await svc.ListAsync(UserId);

        Assert.True(added);
        Assert.Equal(1, list.PendingCount);
        var item = Assert.Single(list.Items);
        Assert.Equal("Pending", item.Status);
        Assert.Equal(38 * 3 + 62, item.PreviewXp);
        Assert.Equal(2, item.PreviewEndurance);
    }

    [Fact]
    public async Task Enqueue_SameWorkoutTwice_KeepsOneRow_AndRefreshesIt()
    {
        var db = CreateDb(nameof(Enqueue_SameWorkoutTwice_KeepsOneRow_AndRefreshesIt));
        var svc = CreateService(db);
        var at = DateTime.UtcNow.AddHours(-1);

        await svc.EnqueueAsync(UserId, Run("strava:1", at, minutes: 30));
        var second = await svc.EnqueueAsync(UserId, Run("strava:1", at, minutes: 40));

        Assert.False(second);
        var row = Assert.Single(await db.Set<PendingActivity>().ToListAsync());
        Assert.Equal(40, row.DurationMinutes);
    }

    [Fact]
    public async Task Enqueue_AlreadyImported_IsIgnored()
    {
        var db = CreateDb(nameof(Enqueue_AlreadyImported_IsIgnored));
        db.Set<ExternalActivityRecord>().Add(new ExternalActivityRecord
        {
            Id = Guid.NewGuid(), CharacterId = CharacterId, Provider = IntegrationProviders.Strava,
            ExternalId = "strava:9", ActivityStartTime = DateTime.UtcNow, WasImported = true, SyncedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync();
        var svc = CreateService(db);

        var added = await svc.EnqueueAsync(UserId, Run("strava:9", DateTime.UtcNow));

        Assert.False(added);
        Assert.Empty(await db.Set<PendingActivity>().ToListAsync());
    }

    [Fact]
    public async Task List_ActivityAlreadySaved_ClearsStalePendingWorkout()
    {
        var db = CreateDb(nameof(List_ActivityAlreadySaved_ClearsStalePendingWorkout));
        var svc = CreateService(db);
        await svc.EnqueueAsync(UserId, Run("strava:saved", DateTime.UtcNow.AddHours(-1)));
        var activityId = Guid.NewGuid();
        svc = CreateService(db, externalIdRead: new StubActivityExternalIdReadPort(
            new() { ["strava:saved"] = activityId }));

        var list = await svc.ListAsync(UserId);

        Assert.Empty(list.Items);
        Assert.Equal(0, list.PendingCount);
        var row = await db.Set<PendingActivity>().SingleAsync();
        Assert.Equal(PendingActivityStatus.Imported, row.Status);
        Assert.Equal(activityId, row.ImportedActivityId);
    }

    [Fact]
    public async Task Import_ActivityAlreadySaved_SkipsAndClearsPendingWorkout()
    {
        var db = CreateDb(nameof(Import_ActivityAlreadySaved_SkipsAndClearsPendingWorkout));
        var svc = CreateService(db);
        await svc.EnqueueAsync(UserId, Run("strava:saved", DateTime.UtcNow.AddHours(-1)));
        var id = (await svc.ListAsync(UserId)).Items.Single().Id;
        svc = CreateService(db, externalIdRead: new StubActivityExternalIdReadPort(
            new() { ["strava:saved"] = Guid.NewGuid() }));

        var result = await svc.ImportAsync(UserId, new ImportPendingRequest { Ids = [id] });

        Assert.Empty(result.Errors);
        Assert.Equal(1, result.Skipped);
        Assert.Equal(0, result.RemainingPending);
        Assert.Equal(PendingActivityStatus.Imported, (await db.Set<PendingActivity>().SingleAsync()).Status);
    }

    [Fact]
    public async Task Enqueue_SameWorkoutFromAnotherProvider_IsMarkedDuplicate()
    {
        var db = CreateDb(nameof(Enqueue_SameWorkoutFromAnotherProvider_IsMarkedDuplicate));
        var svc = CreateService(db);
        var at = DateTime.UtcNow.AddHours(-2);

        await svc.EnqueueAsync(UserId, Run("strava:1", at));
        var added = await svc.EnqueueAsync(UserId, Run("garmin:1", at.AddMinutes(3), IntegrationProviders.Garmin, minutes: 40));
        var list = await svc.ListAsync(UserId);

        Assert.False(added);
        Assert.Equal(1, list.PendingCount);
        var dup = Assert.Single(list.Items, i => i.Status == "Duplicate");
        Assert.Equal(IntegrationProviders.Strava, dup.DuplicateOfProvider);
    }

    [Fact]
    public async Task Enqueue_DifferentWorkoutsCloseTogether_AreNotDuplicates()
    {
        var db = CreateDb(nameof(Enqueue_DifferentWorkoutsCloseTogether_AreNotDuplicates));
        var svc = CreateService(db);
        var at = DateTime.UtcNow.AddHours(-2);

        await svc.EnqueueAsync(UserId, Run("strava:1", at, minutes: 60));
        await svc.EnqueueAsync(UserId, Run("healthconnect:x", at.AddMinutes(5), IntegrationProviders.HealthConnect, minutes: 15));

        Assert.Equal(2, (await svc.ListAsync(UserId)).PendingCount);
    }

    [Fact]
    public async Task Stage_SkipsTodaysStepWalk_ButQueuesFinishedDays()
    {
        var db = CreateDb(nameof(Stage_SkipsTodaysStepWalk_ButQueuesFinishedDays));
        var svc = CreateService(db);
        ExternalActivityDto Steps(string id, DateTime at) => new()
        {
            Provider = IntegrationProviders.HealthConnect, ExternalId = id, ActivityType = "Walking",
            DurationMinutes = 60, DistanceKm = 4, PerformedAt = at,
        };

        var list = await svc.StageAsync(UserId, new StagePendingRequest
        {
            Activities =
            [
                Steps("healthconnect:steps:today", DateTime.UtcNow.Date.AddHours(1)),
                Steps("healthconnect:steps:yesterday", DateTime.UtcNow.Date.AddDays(-1)),
            ],
        });

        var item = Assert.Single(list.Items);
        Assert.Equal("Walking", item.ActivityType);
        Assert.Equal(DateTime.UtcNow.Date.AddDays(-1), item.PerformedAt);
    }

    [Fact]
    public async Task Import_TurnsPendingIntoXp_AndCannotRunTwice()
    {
        var db = CreateDb(nameof(Import_TurnsPendingIntoXp_AndCannotRunTwice));
        var svc = CreateService(db);
        await svc.EnqueueAsync(UserId, Run("strava:1", DateTime.UtcNow.AddHours(-1)));
        var id = (await svc.ListAsync(UserId)).Items[0].Id;

        var first = await svc.ImportAsync(UserId, new ImportPendingRequest { Ids = [id] });
        var second = await svc.ImportAsync(UserId, new ImportPendingRequest { Ids = [id] });

        var imported = Assert.Single(first.Imported);
        Assert.Equal(100, imported.XpGained);
        Assert.Equal(2, imported.Endurance);
        Assert.Equal(100, first.TotalXp);
        Assert.Equal(6.2, first.TotalDistanceKm, 3);
        Assert.Equal(0, first.RemainingPending);
        Assert.Empty(second.Imported);
        Assert.Equal(1, second.Skipped);
        var row = await db.Set<PendingActivity>().SingleAsync();
        Assert.Equal(PendingActivityStatus.Imported, row.Status);
        Assert.True(await db.Set<ExternalActivityRecord>().AnyAsync(r => r.ExternalId == "strava:1" && r.WasImported));
        Assert.Empty((await svc.ListAsync(UserId)).Items);
    }

    [Fact]
    public async Task Import_OnlySelectedWorkouts_LeavesTheRestPending()
    {
        var db = CreateDb(nameof(Import_OnlySelectedWorkouts_LeavesTheRestPending));
        var svc = CreateService(db);
        await svc.EnqueueAsync(UserId, Run("strava:1", DateTime.UtcNow.AddHours(-5)));
        await svc.EnqueueAsync(UserId, Run("strava:2", DateTime.UtcNow.AddHours(-1)));
        var ids = (await svc.ListAsync(UserId)).Items.Select(i => i.Id).ToList();

        var result = await svc.ImportAsync(UserId, new ImportPendingRequest { Ids = [ids[0]] });

        Assert.Single(result.Imported);
        Assert.Equal(1, result.RemainingPending);
    }

    [Fact]
    public async Task Import_IgnoresOtherUsersWorkouts()
    {
        var db = CreateDb(nameof(Import_IgnoresOtherUsersWorkouts));
        var svc = CreateService(db);
        await svc.EnqueueAsync(UserId, Run("strava:1", DateTime.UtcNow.AddHours(-1)));
        var id = (await svc.ListAsync(UserId)).Items[0].Id;

        var result = await svc.ImportAsync(Guid.NewGuid(), new ImportPendingRequest { Ids = [id] });

        Assert.Empty(result.Imported);
        Assert.Equal(PendingActivityStatus.Pending, (await db.Set<PendingActivity>().SingleAsync()).Status);
    }

    [Fact]
    public async Task Notify_SendsOnlyForTheFirstPendingWorkout()
    {
        var db = CreateDb(nameof(Notify_SendsOnlyForTheFirstPendingWorkout));
        var push = new CapturingNotifications();
        var svc = CreateService(db, push);

        await svc.EnqueueAsync(UserId, Run("strava:1", DateTime.UtcNow.AddHours(-3)));
        await svc.NotifyIfFirstPendingAsync(UserId);
        await svc.EnqueueAsync(UserId, Run("strava:2", DateTime.UtcNow.AddHours(-1)));
        await svc.NotifyIfFirstPendingAsync(UserId);

        var sent = Assert.Single(push.Sent);
        Assert.Equal("workouts-pending", sent.Category);
    }

    private sealed class CapturingNotifications : INotificationPort
    {
        public List<(Guid UserId, string Category)> Sent { get; } = [];

        public Task<NotificationSendResult> SendToUserAsync(Guid userId, string category, string title, string body,
            IDictionary<string, string>? data = null, bool isCritical = false, CancellationToken ct = default)
        {
            Sent.Add((userId, category));
            return Task.FromResult(new NotificationSendResult(true, "Sent"));
        }
    }
}
