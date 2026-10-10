using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Data;
using LifeLevel.Api.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Infrastructure;

public sealed class IdempotencyMiddleware(RequestDelegate next)
{
    public const string Header = "Idempotency-Key";
    public const string ReplayedHeader = "Idempotency-Replayed";

    public async Task InvokeAsync(
        HttpContext context,
        AppDbContext db,
        ILogger<IdempotencyMiddleware> logger)
    {
        if (!IsMutation(context.Request.Method) ||
            context.User.Identity?.IsAuthenticated != true ||
            !Guid.TryParse(context.Request.Headers[Header], out var operationId) ||
            !Guid.TryParse(context.User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
        {
            await next(context);
            return;
        }

        var scope = $"{context.Request.Method}:{context.Request.Path.Value}";
        var isolation = context.GetEndpoint()?.Metadata.GetMetadata<MutationIsolationAttribute>()
            ?.IsolationLevel ?? IsolationLevel.ReadCommitted;
        await using var transaction = await db.Database.BeginTransactionAsync(
            isolation, context.RequestAborted);
        var lockKey = AdvisoryLockKey(userId, scope, operationId);
        await db.Database.ExecuteSqlInterpolatedAsync(
            $"SELECT pg_advisory_xact_lock({lockKey})", context.RequestAborted);

        var existing = await db.IdempotencyReceipts.AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == userId && x.Scope == scope &&
                                      x.OperationId == operationId && x.ExpiresAt > DateTime.UtcNow,
                context.RequestAborted);
        if (existing is not null)
        {
            logger.LogDebug(
                "Replaying idempotent mutation. OperationId={OperationId} Scope={Scope}",
                operationId, scope);
            await Replay(context, existing);
            await transaction.CommitAsync(context.RequestAborted);
            return;
        }

        var originalBody = context.Response.Body;
        await using var buffer = new MemoryStream();
        context.Response.Body = buffer;
        try
        {
            await next(context);
            buffer.Position = 0;
            var body = await new StreamReader(buffer, Encoding.UTF8, leaveOpen: true)
                .ReadToEndAsync(context.RequestAborted);
            if (context.Response.StatusCode < 500 && body.Length <= 131_072)
            {
                db.IdempotencyReceipts.Add(new IdempotencyReceipt
                {
                    Id = Guid.NewGuid(), UserId = userId, Scope = scope,
                    OperationId = operationId, StatusCode = context.Response.StatusCode,
                    ContentType = context.Response.ContentType, ResponseBody = body,
                    CreatedAt = DateTime.UtcNow, ExpiresAt = DateTime.UtcNow.AddDays(7),
                });
                await db.SaveChangesAsync(context.RequestAborted);
            }
            if (context.Response.StatusCode < 500)
                await transaction.CommitAsync(context.RequestAborted);
            else
            {
                logger.LogWarning(
                    "Rolling back failed mutation. OperationId={OperationId} Scope={Scope} Status={StatusCode}",
                    operationId, scope, context.Response.StatusCode);
                await transaction.RollbackAsync(context.RequestAborted);
            }
            context.Response.Body = originalBody;
            buffer.Position = 0;
            await buffer.CopyToAsync(originalBody, context.RequestAborted);
        }
        finally
        {
            context.Response.Body = originalBody;
        }
    }

    private static bool IsMutation(string method) =>
        HttpMethods.IsPost(method) || HttpMethods.IsPut(method) ||
        HttpMethods.IsPatch(method) || HttpMethods.IsDelete(method);

    private static long AdvisoryLockKey(Guid userId, string scope, Guid operationId)
    {
        var input = Encoding.UTF8.GetBytes($"{userId:N}:{scope}:{operationId:N}");
        return BitConverter.ToInt64(SHA256.HashData(input), 0);
    }

    private static async Task Replay(HttpContext context, IdempotencyReceipt receipt)
    {
        context.Response.StatusCode = receipt.StatusCode;
        context.Response.ContentType = receipt.ContentType;
        context.Response.Headers[ReplayedHeader] = "true";
        await context.Response.WriteAsync(receipt.ResponseBody, context.RequestAborted);
    }
}
