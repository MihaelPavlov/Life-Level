using System.Collections;
using System.Reflection;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace LifeLevel.Api.Infrastructure;

/// <summary>Adds the canonical error contract to legacy controller responses.</summary>
public sealed class ApiErrorEnvelopeFilter : IAsyncResultFilter
{
    public async Task OnResultExecutionAsync(ResultExecutingContext context, ResultExecutionDelegate next)
    {
        if (context.Result is ObjectResult result)
        {
            var status = result.StatusCode ?? StatusCodes.Status200OK;
            if (status >= 400)
                result.Value = Envelope(result.Value, status, context.HttpContext.TraceIdentifier);
        }
        await next();
    }

    private static Dictionary<string, object?> Envelope(object? value, int status, string traceId)
    {
        var fields = Fields(value);
        var explicitCode = Text(fields, "code");
        var legacyError = Text(fields, "error");
        var explicitMessage = Text(fields, "message");
        var errorIsCode = IsCode(legacyError);
        var code = explicitCode
            ?? (errorIsCode ? legacyError : null)
            ?? DefaultCode(status);
        var candidate = explicitMessage
            ?? (!errorIsCode ? legacyError : null)
            ?? (value as string);
        var message = SafeMessage(candidate, status);

        fields["code"] = code;
        fields["message"] = message;
        fields["traceId"] = traceId;
        // Preserve whether a legacy endpoint used `error` as its code or message.
        fields["error"] = errorIsCode ? legacyError : message;
        return fields;
    }

    private static Dictionary<string, object?> Fields(object? value)
    {
        if (value is IDictionary dictionary)
        {
            var mapped = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
            foreach (DictionaryEntry entry in dictionary)
                if (entry.Key is string key) mapped[key] = entry.Value;
            return mapped;
        }
        if (value is null || value is string) return new(StringComparer.OrdinalIgnoreCase);
        return value.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public)
            .Where(p => p.GetIndexParameters().Length == 0)
            .ToDictionary(p => p.Name, p => p.GetValue(value), StringComparer.OrdinalIgnoreCase);
    }

    private static string? Text(IReadOnlyDictionary<string, object?> fields, string key) =>
        fields.TryGetValue(key, out var value) ? value as string : null;

    private static bool IsCode(string? value) => value is { Length: > 0 and <= 80 }
        && value.All(c => char.IsLetterOrDigit(c) || c is '_' or '-' or '.');

    private static string DefaultCode(int status) => status switch
    {
        400 => "invalid_request",
        401 => "unauthorized",
        403 => "forbidden",
        404 => "not_found",
        409 => "conflict",
        429 => "rate_limited",
        502 or 503 or 504 => "service_unavailable",
        _ => "request_failed",
    };

    private static string SafeMessage(string? value, int status)
    {
        if (status >= 500) return "Something went wrong. Please try again.";
        if (string.IsNullOrWhiteSpace(value)) return status switch
        {
            401 => "Please sign in again.",
            403 => "You cannot perform this action.",
            404 => "The requested item was not found.",
            409 => "This action could not be completed in the current state.",
            429 => "Too many attempts. Please try again shortly.",
            _ => "Please check your request and try again.",
        };

        var message = value.Trim();
        var technical = new[]
        {
            "transaction", "npgsql", "entityframework", "dbcontext", "sqlstate",
            "database", "stack trace", "system.", " at ", "connection is already",
        };
        return technical.Any(token => message.Contains(token, StringComparison.OrdinalIgnoreCase))
            ? "Something went wrong. Please try again."
            : message;
    }
}
