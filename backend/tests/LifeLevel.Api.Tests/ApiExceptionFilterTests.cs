using LifeLevel.Api.Infrastructure;
using LifeLevel.SharedKernel.Abstractions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Abstractions;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.AspNetCore.Routing;

namespace LifeLevel.Api.Tests;

public class ApiExceptionFilterTests
{
    [Fact]
    public void DomainFailure_UsesCanonicalSafeEnvelope()
    {
        var http = new DefaultHttpContext { TraceIdentifier = "trace-123" };
        var action = new ActionContext(http, new RouteData(), new ActionDescriptor());
        var context = new ExceptionContext(action, [])
        {
            Exception = new DomainException(
                "insufficient_currency", "Not enough coins.", DomainErrorKind.Conflict),
        };

        new ApiExceptionFilter().OnException(context);

        var result = Assert.IsType<ObjectResult>(context.Result);
        Assert.Equal(StatusCodes.Status409Conflict, result.StatusCode);
        var body = Assert.IsType<Dictionary<string, object?>>(result.Value);
        Assert.Equal("insufficient_currency", body["code"]);
        Assert.Equal("Not enough coins.", body["message"]);
        Assert.Equal("trace-123", body["traceId"]);
    }
}
