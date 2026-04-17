---
tags: [lifelevel, backend]
aliases: [Identity Module, Users]
---
# Identity

> Owns the `User` record, authentication, and the user's ring-item cosmetic collection.

## Entities

### User
```csharp
class User {
  Guid Id;
  string Username, Email, PasswordHash;
  DateTime CreatedAt;
  UserRole Role;             // Player | Admin
  ICollection<UserRingItem> RingItems;
}
```

### UserRingItem
```csharp
class UserRingItem {
  Guid Id, UserId;
  string RingItemType;       // id of a ring menu item (world, guild, stats, etc.)
  DateTime AcquiredAt;
}
```

Used by the mobile app's radial FAB — the backend stores which ring items a user has selected/acquired.

## Services

### AuthService
- `RegisterAsync(RegisterRequest)` → `AuthResponse`
  - Hash password with **BCrypt**.
  - Insert `User`.
  - **Publish `UserRegisteredEvent(userId)`** — triggers [[Character]] module's `CharacterCreatedHandler` to create initial character row.
  - Generate JWT via `JwtService`.
- `LoginAsync(LoginRequest)` → `AuthResponse`
  - Load user by email, verify BCrypt hash, generate JWT.

### JwtService
- `GenerateTokenAsync(user, claims)` — HMAC-SHA256, 24h lifetime, claims: `sub` (userId), `username`, `role`.
- `ValidateTokenAsync(token)` — validates signing key, issuer, audience, lifetime.

## Ports implemented
None directly (the `IUserReadPort.GetUsernameAsync` adapter bridging Identity→Character lives in `LifeLevel.Api`, registered as scoped).

## Ports consumed
- `IEventPublisher` (from [[SharedKernel]]) — to publish `UserRegisteredEvent`

## Events raised
- `UserRegisteredEvent(userId)` — handled by `CharacterCreatedHandler` in the Character module to create the Character row.

## Endpoints
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/users/me`
- `PUT /api/user/ring` — save the user's radial-menu item selection

## Files
- `backend/src/modules/LifeLevel.Modules.Identity/`

## Related
- [[Auth and JWT]]
- [[Character]]
- [[Cross-Module Events]]
