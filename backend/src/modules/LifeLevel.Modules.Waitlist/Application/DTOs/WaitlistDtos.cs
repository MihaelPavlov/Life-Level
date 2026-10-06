namespace LifeLevel.Modules.Waitlist.Application.DTOs;

public class JoinWaitlistRequest
{
    public string Email { get; set; } = string.Empty;
    /// <summary>Honeypot: hidden on the page, so only bots fill it.</summary>
    public string? Website { get; set; }
    /// <summary>Milliseconds between page load and submit.</summary>
    public long ElapsedMs { get; set; }
    public string? Source { get; set; }
    public string? UtmSource { get; set; }
    public string? UtmMedium { get; set; }
    public string? UtmCampaign { get; set; }
    public string? Referrer { get; set; }
    public string? Locale { get; set; }
}

public enum JoinWaitlistOutcome
{
    /// <summary>Saved or updated.</summary>
    Joined,
    /// <summary>Looked like a bot or hit the per-IP cap; told "ok" but not saved.</summary>
    Ignored,
    InvalidEmail,
}

public record WaitlistSignupDto(
    string Email, DateTime CreatedAt, DateTime LastSubmittedAt, int SubmitCount,
    string? Source, string? UtmSource, string? UtmMedium, string? UtmCampaign,
    string? Referrer, string? Locale);

public record WaitlistPageDto(int Total, int Page, int Size, List<WaitlistSignupDto> Items);

public record WaitlistSourceCount(string Source, int Count);

public record WaitlistStatsDto(int Total, int Today, int Last7Days, List<WaitlistSourceCount> TopSources);
