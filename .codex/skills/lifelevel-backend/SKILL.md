---
name: lifelevel-backend
description: Work on the Life-Level ASP.NET Core backend. Use for controllers, services, modules, entities, DTOs, EF Core configuration, migrations, tests, JWT auth, background jobs, integrations, and backend architecture decisions in this repository.
---

# Life-Level Backend

## First Reads

For non-trivial backend work, read:

- `backend/ARCHITECTURE.txt`
- `backend/src/LifeLevel.Api/Program.cs`
- `backend/src/LifeLevel.Api/Infrastructure/Persistence/AppDbContext.cs`
- The relevant module note under `docs/obsidian/03 - Backend/Modules/`
- The relevant controller in `backend/src/LifeLevel.Api/Controllers/`

## Architecture Rules

- Keep the backend as a modular monolith.
- Keep `LifeLevel.Api` thin: controllers, DI wiring, Swagger, auth, migrations, seeders, hosted jobs, and unavoidable cross-module orchestration.
- Put business behavior in module `Application/UseCases`.
- Put module-owned entities in module `Domain/Entities`.
- Put request/response records in module `Application/DTOs`.
- Put EF configuration in module `Infrastructure/Persistence/Configurations`.
- Register module services through `AddXxxModule()` extension methods.
- Put shared contracts, cross-module ports, clock/user abstractions, and domain events in `LifeLevel.SharedKernel`.

## Cross-Module Communication

Use SharedKernel ports for synchronous calls where the caller needs the result in the same request.

Use in-process domain events for side effects that do not affect the response and would otherwise create dependency cycles.

Do not directly inject a concrete service from another module.

Do not add cross-module navigation properties to entities casually. Cross-module FKs are configured in `AppDbContext`.

## Controller Pattern

- Controllers stay small.
- Use `[Authorize]` by default unless the endpoint is intentionally public.
- Use route prefix `api/<feature>`.
- Delegate to module services.
- Return DTOs, not EF entities.
- Keep validation and business rules out of controllers.

## Entity and DTO Pattern

- Entities should be persistence-friendly and module-owned.
- Prefer C# records for DTOs.
- Use enums for bounded sets such as activity types, rarity, categories, and statuses.
- Preserve existing naming and namespace conventions.

## EF Core

- Add DbSets to `AppDbContext` when a new entity needs persistence.
- Apply per-module configurations through `ApplyConfigurationsFromAssembly`.
- Configure cross-module relationships inline in `AppDbContext`.
- Use migrations from `LifeLevel.Api`.

## Tests

Use existing xUnit patterns under `backend/tests/LifeLevel.Api.Tests`.

Run the narrowest relevant test first, then broader `dotnet test` when the change affects shared behavior, persistence, cross-module events, or public API behavior.

## Common Commands

```powershell
cd backend
dotnet build
dotnet test
```

```powershell
cd backend/src/LifeLevel.Api
dotnet run --launch-profile http
```
