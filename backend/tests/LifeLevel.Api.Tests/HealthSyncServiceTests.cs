using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.Integrations.Application.DTOs;
using LifeLevel.Modules.Integrations.Application.Mappers;
using LifeLevel.Modules.Integrations.Application.UseCases;
using LifeLevel.Modules.Integrations.Domain.Entities;
using LifeLevel.SharedKernel.Enums;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Tests;

public class HealthSyncServiceTests
{
    private static AppDbContext CreateDb(string dbName)
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(dbName)
            .Options;
        return new AppDbContext(options);
    }

    private static HealthSyncService CreateService(
        AppDbContext db,
        IActivityLogPort? activityLog = null,
        IActivityExternalIdReadPort? externalIdRead = null)
    {
        return new HealthSyncService(
            db,
            new DbCharacterIdReadPort(db),
            activityLog ?? new StubActivityLogPort(),
            externalIdRead ?? new StubActivityExternalIdReadPort());
    }

    private static async Task<(Guid UserId, Guid CharacterId)> SeedUserAndCharacter(AppDbContext db, string suffix = "1")
    {
        var userId = Guid.NewGuid();
        var characterId = Guid.NewGuid();
        db.Users.Add(new User { Id = userId, Username = $"sync{suffix}", Email = $"sync{suffix}@test.com", PasswordHash = "x" });
        db.Characters.Add(new Character { Id = characterId, UserId = userId, Level = 1 });
        await db.SaveChangesAsync();
        return (userId, characterId);
    }

    private static ExternalActivityDto MakeDto(string externalId = "strava:123", string activityType = "Running")
    {
        return new ExternalActivityDto
        {
            Provider = IntegrationProviders.Strava,
            ExternalId = externalId,
            ActivityType = activityType,
            DurationMinutes = 30,
            DistanceKm = 5.0,
            Calories = 300,
            PerformedAt = DateTime.UtcNow
        };
    }

    // ── ImportSingleAsync ────────────────────────────────────────────────────

    [Fact]
    public async Task ImportSingleAsync_NewActivity_ImportsSuccessfully()
    {
        var db = CreateDb(nameof(ImportSingleAsync_NewActivity_ImportsSuccessfully));
        var (userId, characterId) = await SeedUserAndCharacter(db);

        var service = CreateService(db);
        var result = await service.ImportSingleAsync(userId, MakeDto());

        Assert.Equal(1, result.Imported);
        Assert.Equal(0, result.Skipped);
        Assert.Empty(result.Errors);

        var record = await db.ExternalActivityRecords.FirstOrDefaultAsync(r => r.CharacterId == characterId);
        Assert.NotNull(record);
        Assert.True(record.WasImported);
        Assert.NotNull(record.ImportedActivityId);
    }

    [Fact]
    public async Task ImportSingleAsync_DuplicateActivity_SkipsSecondImport()
    {
        var db = CreateDb(nameof(ImportSingleAsync_DuplicateActivity_SkipsSecondImport));
        var (userId, _) = await SeedUserAndCharacter(db);

        var service = CreateService(db);
        var dto = MakeDto("strava:dup1");

        var first = await service.ImportSingleAsync(userId, dto);
        Assert.Equal(1, first.Imported);

        var second = await service.ImportSingleAsync(userId, dto);
        Assert.Equal(0, second.Imported);
        Assert.Equal(1, second.Skipped);
    }

    [Fact]
    public async Task ImportSingleAsync_NoCharacter_ReturnsError()
    {
        var db = CreateDb(nameof(ImportSingleAsync_NoCharacter_ReturnsError));
        var userId = Guid.NewGuid();
        // No user/character seeded

        var service = CreateService(db);
        var result = await service.ImportSingleAsync(userId, MakeDto());

        Assert.Equal(0, result.Imported);
        Assert.Single(result.Errors);
        Assert.Contains("Character not found", result.Errors[0]);
    }

    // ── SyncBatchAsync ───────────────────────────────────────────────────────

    [Fact]
    public async Task SyncBatchAsync_MultipleActivities_ImportsAll()
    {
        var db = CreateDb(nameof(SyncBatchAsync_MultipleActivities_ImportsAll));
        var (userId, _) = await SeedUserAndCharacter(db);

        var service = CreateService(db);
        var request = new SyncBatchRequest
        {
            Activities =
            [
                MakeDto("strava:a1", "Running"),
                MakeDto("strava:a2", "Cycling"),
                MakeDto("strava:a3", "Swimming"),
            ]
        };

        var result = await service.SyncBatchAsync(userId, request);

        Assert.Equal(3, result.Imported);
        Assert.Equal(0, result.Skipped);
        Assert.Empty(result.Errors);
    }

    [Fact]
    public async Task SyncBatchAsync_MixOfNewAndDuplicate_SkipsDuplicates()
    {
        var db = CreateDb(nameof(SyncBatchAsync_MixOfNewAndDuplicate_SkipsDuplicates));
        var (userId, _) = await SeedUserAndCharacter(db);

        var service = CreateService(db);

        // Import first activity
        await service.ImportSingleAsync(userId, MakeDto("strava:existing"));

        // Batch includes the existing one plus a new one
        var request = new SyncBatchRequest
        {
            Activities =
            [
                MakeDto("strava:existing"),
                MakeDto("strava:brand-new"),
            ]
        };

        var result = await service.SyncBatchAsync(userId, request);

        Assert.Equal(1, result.Imported);
        Assert.Equal(1, result.Skipped);
    }

    [Fact]
    public async Task SyncBatchAsync_EmptyBatch_ReturnsZeros()
    {
        var db = CreateDb(nameof(SyncBatchAsync_EmptyBatch_ReturnsZeros));
        var (userId, _) = await SeedUserAndCharacter(db);

        var service = CreateService(db);
        var result = await service.SyncBatchAsync(userId, new SyncBatchRequest { Activities = [] });

        Assert.Equal(0, result.Imported);
        Assert.Equal(0, result.Skipped);
        Assert.Empty(result.Errors);
    }

    // ── SyncBatchAsync: stuck record retry ───────────────────────────────────

    [Fact]
    public async Task SyncBatchAsync_StuckRecord_RetriesAndImports()
    {
        var db = CreateDb(nameof(SyncBatchAsync_StuckRecord_RetriesAndImports));
        var (userId, characterId) = await SeedUserAndCharacter(db);

        // Simulate a stuck record (WasImported = false, no ActivityId)
        db.ExternalActivityRecords.Add(new ExternalActivityRecord
        {
            Id = Guid.NewGuid(),
            CharacterId = characterId,
            Provider = IntegrationProviders.Strava,
            ExternalId = "strava:stuck1",
            ActivityStartTime = DateTime.UtcNow,
            WasImported = false,
            SyncedAt = DateTime.UtcNow.AddHours(-1)
        });
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var result = await service.ImportSingleAsync(userId, MakeDto("strava:stuck1"));

        // Should retry the stuck record, not skip it
        Assert.Equal(1, result.Imported);
        Assert.Equal(0, result.Skipped);

        var record = await db.ExternalActivityRecords
            .FirstAsync(r => r.ExternalId == "strava:stuck1");
        Assert.True(record.WasImported);
    }

    // ── ReprocessStuckAsync ──────────────────────────────────────────────────

    [Fact]
    public async Task ReprocessStuckAsync_NoStuckRecords_ReturnsEmpty()
    {
        var db = CreateDb(nameof(ReprocessStuckAsync_NoStuckRecords_ReturnsEmpty));
        var (userId, _) = await SeedUserAndCharacter(db);

        var service = CreateService(db);
        var result = await service.ReprocessStuckAsync(userId);

        Assert.Equal(0, result.Imported);
        Assert.Equal(0, result.Skipped);
        Assert.Empty(result.Errors);
    }

    [Fact]
    public async Task ReprocessStuckAsync_TornWrite_RepairsRecord()
    {
        var db = CreateDb(nameof(ReprocessStuckAsync_TornWrite_RepairsRecord));
        var (userId, characterId) = await SeedUserAndCharacter(db);

        var existingActivityId = Guid.NewGuid();

        // Simulate torn write: stuck record exists, but Activity row also exists
        db.ExternalActivityRecords.Add(new ExternalActivityRecord
        {
            Id = Guid.NewGuid(),
            CharacterId = characterId,
            Provider = IntegrationProviders.Strava,
            ExternalId = "strava:torn1",
            ActivityStartTime = DateTime.UtcNow,
            WasImported = false,
            SyncedAt = DateTime.UtcNow.AddHours(-1)
        });
        await db.SaveChangesAsync();

        // Stub returns a matching activity ID (simulating the torn-write scenario)
        var externalIdRead = new StubActivityExternalIdReadPort(
            new Dictionary<string, Guid> { ["strava:torn1"] = existingActivityId });

        var service = CreateService(db, externalIdRead: externalIdRead);
        var result = await service.ReprocessStuckAsync(userId);

        Assert.Equal(1, result.Skipped); // repaired, counted as skipped
        Assert.Empty(result.Errors);

        var record = await db.ExternalActivityRecords
            .FirstAsync(r => r.ExternalId == "strava:torn1");
        Assert.True(record.WasImported);
        Assert.Equal(existingActivityId, record.ImportedActivityId);
    }

    [Fact]
    public async Task ReprocessStuckAsync_TrueStuck_ReportsError()
    {
        var db = CreateDb(nameof(ReprocessStuckAsync_TrueStuck_ReportsError));
        var (userId, characterId) = await SeedUserAndCharacter(db);

        // Stuck record with no matching Activity row
        db.ExternalActivityRecords.Add(new ExternalActivityRecord
        {
            Id = Guid.NewGuid(),
            CharacterId = characterId,
            Provider = IntegrationProviders.Strava,
            ExternalId = "strava:truly-stuck",
            ActivityStartTime = DateTime.UtcNow,
            WasImported = false,
            SyncedAt = DateTime.UtcNow.AddMinutes(-30)
        });
        await db.SaveChangesAsync();

        var service = CreateService(db);
        var result = await service.ReprocessStuckAsync(userId);

        Assert.Single(result.Errors);
        Assert.Contains("strava:truly-stuck", result.Errors[0]);
        Assert.Contains("fresh sync", result.Errors[0]);
    }

    [Fact]
    public async Task ReprocessStuckAsync_NoCharacter_ReturnsError()
    {
        var db = CreateDb(nameof(ReprocessStuckAsync_NoCharacter_ReturnsError));

        var service = CreateService(db);
        var result = await service.ReprocessStuckAsync(Guid.NewGuid());

        Assert.Single(result.Errors);
        Assert.Contains("Character not found", result.Errors[0]);
    }

    // ── SyncBatchAsync: ActivityLogPort failure ──────────────────────────────

    [Fact]
    public async Task SyncBatchAsync_LogPortThrows_RecordsErrorAndContinues()
    {
        var db = CreateDb(nameof(SyncBatchAsync_LogPortThrows_RecordsErrorAndContinues));
        var (userId, _) = await SeedUserAndCharacter(db);

        var failingLog = new FailingActivityLogPort();
        var service = CreateService(db, activityLog: failingLog);

        var request = new SyncBatchRequest
        {
            Activities =
            [
                MakeDto("strava:fail1"),
                MakeDto("strava:fail2"),
            ]
        };

        var result = await service.SyncBatchAsync(userId, request);

        Assert.Equal(0, result.Imported);
        Assert.Equal(2, result.Errors.Count);
    }

    // ── SyncBatchAsync: unknown activity type falls back to Gym ──────────────

    [Fact]
    public async Task SyncBatchAsync_UnknownActivityType_FallsBackToGym()
    {
        var db = CreateDb(nameof(SyncBatchAsync_UnknownActivityType_FallsBackToGym));
        var (userId, _) = await SeedUserAndCharacter(db);

        var capturingLog = new CapturingActivityLogPort();
        var service = CreateService(db, activityLog: capturingLog);

        var dto = MakeDto("strava:unknown-type");
        dto.ActivityType = "SomeInvalidType";

        var result = await service.ImportSingleAsync(userId, dto);

        Assert.Equal(1, result.Imported);
        Assert.Equal(ActivityType.Gym, capturingLog.LastActivityType);
    }
}
