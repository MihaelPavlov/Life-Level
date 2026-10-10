namespace LifeLevel.SharedKernel.Abstractions;

public enum DomainErrorKind
{
    Validation,
    Conflict,
    NotFound,
    Forbidden,
    Unauthorized,
    UpstreamUnavailable,
}

/// <summary>A business failure whose code and message are safe to return to a client.</summary>
public class DomainException(
    string code,
    string message,
    DomainErrorKind kind = DomainErrorKind.Conflict,
    bool legacyErrorUsesCode = false,
    IReadOnlyDictionary<string, object?>? metadata = null) : InvalidOperationException(message)
{
    public string Code { get; } = code;
    public DomainErrorKind Kind { get; } = kind;
    public bool LegacyErrorUsesCode { get; } = legacyErrorUsesCode;
    public IReadOnlyDictionary<string, object?> Metadata { get; } =
        metadata ?? new Dictionary<string, object?>();
}
