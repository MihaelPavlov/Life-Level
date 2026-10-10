using LifeLevel.SharedKernel.Abstractions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace LifeLevel.Api.Infrastructure;

public sealed class ApiExceptionFilter : IExceptionFilter
{
    public void OnException(ExceptionContext context)
    {
        var error = context.Exception switch
        {
            DomainException domain => domain,
            KeyNotFoundException missing => new DomainException(
                "not_found", missing.Message, DomainErrorKind.NotFound),
            _ => null,
        };
        if (error is null) return;

        var body = new Dictionary<string, object?>
        {
            ["code"] = error.Code,
            ["message"] = error.Message,
            ["traceId"] = context.HttpContext.TraceIdentifier,
            // Compatibility for app builds that predate the canonical envelope.
            ["error"] = error.LegacyErrorUsesCode ? error.Code : error.Message,
        };
        foreach (var (key, value) in error.Metadata) body[key] = value;

        context.Result = new ObjectResult(body) { StatusCode = Status(error.Kind) };
        context.ExceptionHandled = true;
    }

    private static int Status(DomainErrorKind kind) => kind switch
    {
        DomainErrorKind.Validation => StatusCodes.Status400BadRequest,
        DomainErrorKind.Unauthorized => StatusCodes.Status401Unauthorized,
        DomainErrorKind.Forbidden => StatusCodes.Status403Forbidden,
        DomainErrorKind.NotFound => StatusCodes.Status404NotFound,
        DomainErrorKind.UpstreamUnavailable => StatusCodes.Status502BadGateway,
        _ => StatusCodes.Status409Conflict,
    };
}
