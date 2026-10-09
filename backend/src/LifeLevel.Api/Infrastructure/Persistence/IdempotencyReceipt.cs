namespace LifeLevel.Api.Infrastructure.Persistence;

public sealed class IdempotencyReceipt
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Scope { get; set; } = string.Empty;
    public Guid OperationId { get; set; }
    public int StatusCode { get; set; }
    public string? ContentType { get; set; }
    public string ResponseBody { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
}
