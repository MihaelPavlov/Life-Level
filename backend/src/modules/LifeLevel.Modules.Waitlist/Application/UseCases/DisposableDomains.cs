namespace LifeLevel.Modules.Waitlist.Application.UseCases;

/// <summary>Common throwaway-inbox domains rejected by the waitlist.</summary>
internal static class DisposableDomains
{
    public static readonly HashSet<string> All = new(StringComparer.OrdinalIgnoreCase)
    {
        "mailinator.com", "10minutemail.com", "10minutemail.net", "guerrillamail.com",
        "guerrillamail.net", "guerrillamail.org", "sharklasers.com", "grr.la",
        "tempmail.com", "temp-mail.org", "temp-mail.io", "tempmail.net", "tempmailo.com",
        "yopmail.com", "yopmail.net", "throwawaymail.com", "trashmail.com", "trashmail.net",
        "getnada.com", "nada.email", "dispostable.com", "maildrop.cc", "mailnesia.com",
        "mintemail.com", "fakeinbox.com", "spamgourmet.com", "mohmal.com", "emailondeck.com",
        "mailcatch.com", "moakt.com", "tempinbox.com", "burnermail.io", "inboxkitten.com",
        "mail.tm", "mailpoof.com", "33mail.com", "spambox.us", "discard.email",
    };
}
