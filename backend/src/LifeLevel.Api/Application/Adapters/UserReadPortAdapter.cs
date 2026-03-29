using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Application.Adapters;

/// <summary>Temporary adapter — removed when Identity module is extracted in Step 3.</summary>
internal class UserReadPortAdapter(AppDbContext db) : IUserReadPort
{
    public async Task<string?> GetUsernameAsync(Guid userId, CancellationToken ct = default)
    {
        return await db.Users
            .Where(u => u.Id == userId)
            .Select(u => u.Username)
            .FirstOrDefaultAsync(ct);
    }
}
