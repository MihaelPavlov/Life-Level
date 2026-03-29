using LifeLevel.Api.Infrastructure.Persistence;
using LifeLevel.Modules.Identity.Domain.Entities;
using LifeLevel.Modules.Identity.Domain.Enums;
using LifeLevel.SharedKernel.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LifeLevel.Api.Controllers;

[ApiController]
[Route("api/user")]
[Authorize]
public class UserController(AppDbContext db, IUserContext userContext) : ControllerBase
{
    [HttpPut("ring")]
    public async Task<IActionResult> SaveRingConfig([FromBody] SaveRingRequest req)
    {
        var userId = userContext.UserId;

        // Replace existing ring items
        var existing = await db.UserRingItems
            .Where(r => r.UserId == userId)
            .ToListAsync();
        db.UserRingItems.RemoveRange(existing);

        var newItems = req.Items.Select((type, i) => new UserRingItem
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ItemType = type,
            SortOrder = i,
        });
        db.UserRingItems.AddRange(newItems);

        await db.SaveChangesAsync();
        return NoContent();
    }
}

public record SaveRingRequest(IReadOnlyList<RingItemType> Items);
