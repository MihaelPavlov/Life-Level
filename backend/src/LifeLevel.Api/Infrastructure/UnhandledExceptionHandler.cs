using Microsoft.AspNetCore.Diagnostics;

namespace LifeLevel.Api.Infrastructure;

public sealed class UnhandledExceptionHandler(
    ILogger<UnhandledExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext context, Exception exception, CancellationToken ct)
    {
        logger.LogError(exception,
            "Unhandled API failure. TraceId={TraceId} OperationId={OperationId} Method={Method} Path={Path}",
            context.TraceIdentifier,
            context.Request.Headers[IdempotencyMiddleware.Header].FirstOrDefault(),
            context.Request.Method,
            context.Request.Path);

        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await context.Response.WriteAsJsonAsync(new
        {
            code = "unexpected_error",
            message = "Something went wrong. Please try again.",
            error = "Something went wrong. Please try again.",
            traceId = context.TraceIdentifier,
        }, ct);
        return true;
    }
}
