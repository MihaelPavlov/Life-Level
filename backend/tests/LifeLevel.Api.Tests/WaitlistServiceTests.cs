using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Waitlist.Application.DTOs;
using LifeLevel.Modules.Waitlist.Application.UseCases;
using LifeLevel.Modules.Waitlist.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace LifeLevel.Api.Tests;

public class WaitlistServiceTests
{
    private static AppDbContext CreateDb(string name) =>
        new(new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(name).Options);

    private static WaitlistService CreateService(AppDbContext db) =>
        new(db, new ConfigurationBuilder().AddInMemoryCollection(
            new Dictionary<string, string?> { ["Waitlist:IpSalt"] = "test-salt" }).Build());

    private static JoinWaitlistRequest Req(string email, long elapsedMs = 6000, string? website = null) => new()
    {
        Email = email, ElapsedMs = elapsedMs, Website = website,
        Source = "landing", UtmSource = "instagram", Referrer = "https://instagram.com/", Locale = "bg-BG",
    };

    [Fact]
    public async Task Join_SavesNormalizedEmailWithTracking_AndHashesTheIp()
    {
        var db = CreateDb(nameof(Join_SavesNormalizedEmailWithTracking_AndHashesTheIp));
        var outcome = await CreateService(db).JoinAsync(Req("  Hero@Example.COM "), "203.0.113.7", "UA");

        Assert.Equal(JoinWaitlistOutcome.Joined, outcome);
        var row = await db.Set<WaitlistSignup>().SingleAsync();
        Assert.Equal("hero@example.com", row.Email);
        Assert.Equal("instagram", row.UtmSource);
        Assert.Equal("bg-BG", row.Locale);
        Assert.Equal(1, row.SubmitCount);
        Assert.NotNull(row.IpHash);
        Assert.DoesNotContain("203.0.113.7", row.IpHash);
    }

    [Fact]
    public async Task Join_SameEmailTwice_KeepsOneRow_AndCountsSubmits()
    {
        var db = CreateDb(nameof(Join_SameEmailTwice_KeepsOneRow_AndCountsSubmits));
        var svc = CreateService(db);

        var first = await svc.JoinAsync(Req("hero@example.com"), "203.0.113.7", null);
        var second = await svc.JoinAsync(Req("HERO@example.com"), "198.51.100.2", null);

        Assert.Equal(first, second);
        var row = await db.Set<WaitlistSignup>().SingleAsync();
        Assert.Equal(2, row.SubmitCount);
    }

    [Theory]
    [InlineData(6000, "https://spam.example")]
    [InlineData(800, null)]
    public async Task Join_BotSignals_AreIgnoredWithoutSaving(long elapsedMs, string? website)
    {
        var db = CreateDb(nameof(Join_BotSignals_AreIgnoredWithoutSaving) + elapsedMs);

        var outcome = await CreateService(db).JoinAsync(Req("bot@example.com", elapsedMs, website), "203.0.113.7", null);

        Assert.Equal(JoinWaitlistOutcome.Ignored, outcome);
        Assert.Empty(await db.Set<WaitlistSignup>().ToListAsync());
    }

    [Theory]
    [InlineData("")]
    [InlineData("not-an-email")]
    [InlineData("a@b")]
    [InlineData("two words@example.com")]
    [InlineData("someone@mailinator.com")]
    [InlineData("x@YOPMAIL.com")]
    public async Task Join_InvalidOrDisposableEmail_IsRejected(string email)
    {
        var db = CreateDb(nameof(Join_InvalidOrDisposableEmail_IsRejected) + email);

        var outcome = await CreateService(db).JoinAsync(Req(email), "203.0.113.7", null);

        Assert.Equal(JoinWaitlistOutcome.InvalidEmail, outcome);
        Assert.Empty(await db.Set<WaitlistSignup>().ToListAsync());
    }

    [Fact]
    public async Task Join_TooManyNewAddressesFromOneIp_StopsSaving()
    {
        var db = CreateDb(nameof(Join_TooManyNewAddressesFromOneIp_StopsSaving));
        var svc = CreateService(db);
        for (var i = 0; i < WaitlistService.MaxNewPerIpPerDay; i++)
            Assert.Equal(JoinWaitlistOutcome.Joined, await svc.JoinAsync(Req($"user{i}@example.com"), "203.0.113.7", null));

        var extra = await svc.JoinAsync(Req("one-more@example.com"), "203.0.113.7", null);
        var otherIp = await svc.JoinAsync(Req("other@example.com"), "198.51.100.2", null);

        Assert.Equal(JoinWaitlistOutcome.Ignored, extra);
        Assert.Equal(JoinWaitlistOutcome.Joined, otherIp);
        Assert.Equal(WaitlistService.MaxNewPerIpPerDay + 1, await db.Set<WaitlistSignup>().CountAsync());
    }

    [Fact]
    public async Task Stats_AndCsvExport_ReflectSignups()
    {
        var db = CreateDb(nameof(Stats_AndCsvExport_ReflectSignups));
        var svc = CreateService(db);
        await svc.JoinAsync(Req("a@example.com"), "203.0.113.7", null);
        await svc.JoinAsync(new JoinWaitlistRequest { Email = "=cmd@example.com", ElapsedMs = 6000 }, "198.51.100.2", null);

        var stats = await svc.GetStatsAsync();
        var csv = await svc.ExportCsvAsync();

        Assert.Equal(2, stats.Total);
        Assert.Equal(2, stats.Today);
        Assert.Contains(stats.TopSources, s => s.Source == "instagram" && s.Count == 1);
        Assert.StartsWith("email,created_at", csv);
        Assert.Contains("\"a@example.com\"", csv);
        Assert.Contains("\"'=cmd@example.com\"", csv);
    }
}
