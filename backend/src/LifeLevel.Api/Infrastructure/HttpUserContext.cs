using System.Security.Claims;
using LifeLevel.SharedKernel.Contracts;

namespace LifeLevel.Api.Infrastructure;

public class HttpUserContext : IUserContext
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public HttpUserContext(IHttpContextAccessor httpContextAccessor)
        => _httpContextAccessor = httpContextAccessor;

    public Guid UserId
    {
        get
        {
            var value = _httpContextAccessor.HttpContext?.User
                .FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? throw new UnauthorizedAccessException();
            return Guid.Parse(value);
        }
    }
}
