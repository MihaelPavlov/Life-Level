namespace LifeLevel.Modules.Waitlist.Domain.Entities;

/// <summary>
/// An email left on the pre-launch landing page. One row per address;
/// repeat submissions bump <see cref="SubmitCount"/>. No email is sent.
/// </summary>
public class WaitlistSignup
{
    public Guid Id { get; set; }
    /// <summary>Trimmed, lower-case address.</summary>
    public string Email { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime LastSubmittedAt { get; set; }
    public int SubmitCount { get; set; } = 1;

    public string? Source { get; set; }
    public string? UtmSource { get; set; }
    public string? UtmMedium { get; set; }
    public string? UtmCampaign { get; set; }
    public string? Referrer { get; set; }
    public string? Locale { get; set; }
    public string? UserAgent { get; set; }
    /// <summary>Salted SHA-256 of the client IP, for abuse limits. The raw IP is never stored.</summary>
    public string? IpHash { get; set; }
}
