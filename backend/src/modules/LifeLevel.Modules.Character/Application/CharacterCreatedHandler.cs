using LifeLevel.SharedKernel.Events;
using Microsoft.EntityFrameworkCore;

using CharacterEntity = LifeLevel.Modules.Character.Domain.Entities.Character;

namespace LifeLevel.Modules.Character.Application;

public class CharacterCreatedHandler(DbContext db) : IEventHandler<UserRegisteredEvent>
{
    public async Task HandleAsync(UserRegisteredEvent e, CancellationToken ct = default)
    {
        // Idempotent: only create if character doesn't exist yet
        var exists = await db.Set<CharacterEntity>().AnyAsync(c => c.UserId == e.UserId, ct);
        if (exists) return;

        var character = new CharacterEntity
        {
            Id = Guid.NewGuid(),
            UserId = e.UserId,
        };
        db.Set<CharacterEntity>().Add(character);
        await db.SaveChangesAsync(ct);
    }
}
