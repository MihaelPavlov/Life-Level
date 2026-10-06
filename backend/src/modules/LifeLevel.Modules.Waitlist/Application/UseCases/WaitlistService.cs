using System.Globalization;
using System.Net.Mail;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using LifeLevel.Modules.Waitlist.Application.DTOs;
using LifeLevel.Modules.Waitlist.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace LifeLevel.Modules.Waitlist.Application.UseCases;

public partial class WaitlistService(DbContext db, IConfiguration config)
{
    /// <summary>A human needs at least this long to read the page and type an email.</summary>
    public const long MinElapsedMs = 2500;
    /// <summary>New addresses accepted from one IP per 24 h; more are dropped silently.</summary>
    public const int MaxNewPerIpPerDay = 20;

    [GeneratedRegex(@"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$")]
    private static partial Regex EmailShape();

    public async Task<JoinWaitlistOutcome> JoinAsync(
        JoinWaitlistRequest req, string? ip, string? userAgent, CancellationToken ct = default)
    {
        if (!string.IsNullOrWhiteSpace(req.Website) || req.ElapsedMs < MinElapsedMs)
            return JoinWaitlistOutcome.Ignored;

        var email = Normalize(req.Email);
        if (email is null) return JoinWaitlistOutcome.InvalidEmail;

        var now = DateTime.UtcNow;
        var signups = db.Set<WaitlistSignup>();
        var existing = await signups.FirstOrDefaultAsync(s => s.Email == email, ct);
        if (existing is not null)
        {
            existing.SubmitCount++;
            existing.LastSubmittedAt = now;
            await db.SaveChangesAsync(ct);
            return JoinWaitlistOutcome.Joined;
        }

        var ipHash = HashIp(ip);
        if (ipHash is not null)
        {
            var since = now.AddHours(-24);
            var fromIp = await signups.CountAsync(s => s.IpHash == ipHash && s.CreatedAt >= since, ct);
            if (fromIp >= MaxNewPerIpPerDay) return JoinWaitlistOutcome.Ignored;
        }

        signups.Add(new WaitlistSignup
        {
            Id = Guid.NewGuid(),
            Email = email,
            CreatedAt = now,
            LastSubmittedAt = now,
            Source = Clip(req.Source, 40),
            UtmSource = Clip(req.UtmSource, 100),
            UtmMedium = Clip(req.UtmMedium, 100),
            UtmCampaign = Clip(req.UtmCampaign, 100),
            Referrer = Clip(req.Referrer, 500),
            Locale = Clip(req.Locale, 20),
            UserAgent = Clip(userAgent, 300),
            IpHash = ipHash,
        });
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            // Two submits of the same new address raced; the other one saved it.
        }
        return JoinWaitlistOutcome.Joined;
    }

    public async Task<WaitlistStatsDto> GetStatsAsync(CancellationToken ct = default)
    {
        var signups = db.Set<WaitlistSignup>();
        var today = DateTime.UtcNow.Date;
        var total = await signups.CountAsync(ct);
        var todayCount = await signups.CountAsync(s => s.CreatedAt >= today, ct);
        var week = await signups.CountAsync(s => s.CreatedAt >= today.AddDays(-6), ct);
        var sources = await signups
            .GroupBy(s => s.UtmSource ?? s.Source ?? "direct")
            .Select(g => new { Source = g.Key, Count = g.Count() })
            .OrderByDescending(x => x.Count)
            .Take(10)
            .ToListAsync(ct);
        return new WaitlistStatsDto(total, todayCount, week,
            sources.Select(x => new WaitlistSourceCount(x.Source, x.Count)).ToList());
    }

    public async Task<WaitlistPageDto> ListAsync(int page, int size, CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        size = Math.Clamp(size, 1, 200);
        var signups = db.Set<WaitlistSignup>();
        var total = await signups.CountAsync(ct);
        var items = await signups
            .OrderByDescending(s => s.CreatedAt)
            .Skip((page - 1) * size)
            .Take(size)
            .Select(s => ToDto(s))
            .ToListAsync(ct);
        return new WaitlistPageDto(total, page, size, items);
    }

    public async Task<string> ExportCsvAsync(CancellationToken ct = default)
    {
        var rows = await db.Set<WaitlistSignup>()
            .OrderBy(s => s.CreatedAt)
            .ToListAsync(ct);
        var sb = new StringBuilder("email,created_at,last_submitted_at,submit_count,source,utm_source,utm_medium,utm_campaign,referrer,locale\n");
        foreach (var s in rows)
        {
            sb.AppendJoin(',', new[]
            {
                Csv(s.Email), s.CreatedAt.ToString("o", CultureInfo.InvariantCulture),
                s.LastSubmittedAt.ToString("o", CultureInfo.InvariantCulture),
                s.SubmitCount.ToString(CultureInfo.InvariantCulture),
                Csv(s.Source), Csv(s.UtmSource), Csv(s.UtmMedium), Csv(s.UtmCampaign),
                Csv(s.Referrer), Csv(s.Locale),
            });
            sb.Append('\n');
        }
        return sb.ToString();
    }

    /// <summary>Trimmed, lower-case address, or null when it isn't a usable email.</summary>
    public static string? Normalize(string? raw)
    {
        var email = raw?.Trim().ToLowerInvariant();
        if (string.IsNullOrEmpty(email) || email.Length > 254 || !EmailShape().IsMatch(email))
            return null;
        if (!MailAddress.TryCreate(email, out var parsed) || parsed.Address != email)
            return null;
        return DisposableDomains.All.Contains(parsed.Host) ? null : email;
    }

    private string? HashIp(string? ip)
    {
        if (string.IsNullOrWhiteSpace(ip)) return null;
        var salt = config["Waitlist:IpSalt"] ?? "lifelevel-waitlist";
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(salt + "|" + ip));
        return Convert.ToHexStringLower(bytes);
    }

    private static string? Clip(string? value, int max)
    {
        var v = value?.Trim();
        if (string.IsNullOrEmpty(v)) return null;
        return v.Length <= max ? v : v[..max];
    }

    // Quote every field and neutralise spreadsheet formulas (=, +, -, @).
    private static string Csv(string? value)
    {
        var v = value ?? string.Empty;
        if (v.Length > 0 && "=+-@".Contains(v[0])) v = "'" + v;
        return "\"" + v.Replace("\"", "\"\"") + "\"";
    }

    private static WaitlistSignupDto ToDto(WaitlistSignup s) => new(
        s.Email, s.CreatedAt, s.LastSubmittedAt, s.SubmitCount,
        s.Source, s.UtmSource, s.UtmMedium, s.UtmCampaign, s.Referrer, s.Locale);
}
