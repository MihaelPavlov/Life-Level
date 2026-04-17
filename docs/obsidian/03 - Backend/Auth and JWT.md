---
tags: [lifelevel, backend]
aliases: [JWT, Auth, Authentication]
---
# Auth and JWT

> Stateless JWT bearer tokens. Password hashed with BCrypt. 24-hour token lifetime, HMAC-SHA256 signing. No Supabase Auth — all auth logic is in ASP.NET Core.

## Registration

`POST /api/auth/register` → `AuthService.RegisterAsync`:

1. Validates uniqueness (email + username).
2. Hashes password via **BCrypt**.
3. Inserts `User` row (default `Role = Player`).
4. Publishes `UserRegisteredEvent(userId)`.
5. `CharacterCreatedHandler` (in [[Character]] module) creates a Character row with default stats.
6. `JwtService.GenerateTokenAsync` builds a token.
7. Returns `AuthResponse(token, refreshToken, userId)`.

## Login

`POST /api/auth/login` → `AuthService.LoginAsync`:

1. Load user by email.
2. Verify password with BCrypt.
3. Generate JWT.
4. Return `AuthResponse`.

## JWT configuration

| Setting | Value |
|---------|-------|
| Scheme | `Bearer` |
| Algorithm | HMAC-SHA256 |
| Signing key | `Jwt:Key` from `appsettings.json` |
| Issuer | `Jwt:Issuer` |
| Audience | `Jwt:Audience` |
| Lifetime | **24 hours** |
| Claims | `sub` (userId), `username`, `role` |

Validation enabled: `ValidateIssuer`, `ValidateAudience`, `ValidateLifetime`, `ValidateIssuerSigningKey`.

## User context

`IUserContext` (in [[SharedKernel]]) → implemented as `HttpUserContext` in `LifeLevel.Api`:

```csharp
public class HttpUserContext : IUserContext {
    public Guid UserId => Guid.Parse(
        _httpContextAccessor.HttpContext.User.FindFirst("sub")?.Value);
    public string? Username => ...FindFirst("username")?.Value;
    public string? Role => ...FindFirst("role")?.Value;
}
```

Scoped per HTTP request. Every service that needs to know "who am I" injects `IUserContext`.

## Admin role

`User.Role` enum:
- `Player` (default)
- `Admin` (set manually / via admin-panel or DB)

Admin controllers use `[Authorize(Roles = "Admin")]`. Mobile app decodes JWT payload client-side (in `ApiClient.isAdmin()`) to conditionally show the Admin tab in Profile.

## Mobile side

- Token stored in `FlutterSecureStorage` (Android EncryptedSharedPreferences, iOS Keychain).
- Injected into every Dio request as `Authorization: Bearer {token}`.
- On 401 response: token cleared, navigator pushed to `LoginScreen`.

## Files

- Backend: `LifeLevel.Modules.Identity/Application/UseCases/AuthService.cs`, `JwtService.cs`
- Backend: `LifeLevel.Api/Infrastructure/HttpUserContext.cs`
- Mobile: `mobile/lib/core/api/api_client.dart`, `mobile/lib/features/auth/services/auth_service.dart`

## Related
- [[Identity]] (backend module)
- [[Feature - Auth]] (mobile)
- [[Cross-Module Events]] (UserRegisteredEvent)
- [[Environment Setup]] (Jwt:Key config)
