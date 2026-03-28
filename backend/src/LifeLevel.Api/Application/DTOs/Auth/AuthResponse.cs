using LifeLevel.Api.Domain.Enums;

namespace LifeLevel.Api.Application.DTOs.Auth;

public record AuthResponse(string Token, string Username, Guid CharacterId, IReadOnlyList<RingItemType> RingItems, bool IsSetupComplete);
