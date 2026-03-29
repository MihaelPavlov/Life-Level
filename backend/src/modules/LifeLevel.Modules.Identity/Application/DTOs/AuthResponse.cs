using LifeLevel.Modules.Identity.Domain.Enums;

namespace LifeLevel.Modules.Identity.Application.DTOs;

public record AuthResponse(
    string Token,
    string Username,
    Guid? CharacterId,
    IReadOnlyList<RingItemType> RingItems,
    bool IsSetupComplete
);
