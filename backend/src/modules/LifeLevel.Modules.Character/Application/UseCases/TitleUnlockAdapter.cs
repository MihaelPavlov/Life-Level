using LifeLevel.Modules.Character.Domain.Data;
using LifeLevel.Modules.Character.Domain.Entities;
using LifeLevel.SharedKernel.Ports;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace LifeLevel.Modules.Character.Application.UseCases;

/// <summary>
/// Character-module adapter for <see cref="ITitleUnlockPort"/>. Resolves a stable string
/// catalog key (e.g. "novice-adventurer") to the concrete <see cref="Title"/> row and inserts
/// a <see cref="CharacterTitle"/> join row if one does not already exist.
///
/// Idempotent: granting the same title twice is a no-op. Unknown keys are logged and return
/// false — they do not throw, so tutorial / reward flows do not need to defend against
/// catalog misconfiguration at runtime.
/// </summary>
public class TitleUnlockAdapter(DbContext db, ILogger<TitleUnlockAdapter> logger) : ITitleUnlockPort
{
    public async Task<bool> UnlockAsync(Guid characterId, string titleKey, CancellationToken ct = default)
    {
        if (!TitleCatalog.KeyToId.TryGetValue(titleKey, out var titleId))
        {
            logger.LogWarning(
                "TitleUnlockAdapter: unknown title key '{TitleKey}' for character {CharacterId}; no-op.",
                titleKey, characterId);
            return false;
        }

        var alreadyEarned = await db.Set<CharacterTitle>()
            .AnyAsync(ct2 => ct2.CharacterId == characterId && ct2.TitleId == titleId, ct);
        if (alreadyEarned) return false;

        db.Set<CharacterTitle>().Add(new CharacterTitle
        {
            Id = Guid.NewGuid(),
            CharacterId = characterId,
            TitleId = titleId,
            EarnedAt = DateTime.UtcNow,
        });
        await db.SaveChangesAsync(ct);
        return true;
    }
}
