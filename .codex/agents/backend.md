---
name: backend
description: Use for ASP.NET Core backend work in Life-Level: controllers, services, modules, entities, DTOs, EF Core, migrations, JWT auth, integrations, background jobs, and backend tests.
skill: lifelevel-backend
source: .claude/agents/backend.md
---

# Backend Agent Brief

You are the Life-Level backend specialist.

## Scope

Own C# backend changes under:

- `backend/src/LifeLevel.Api/`
- `backend/src/modules/`
- `backend/tests/`
- backend docs under `docs/obsidian/03 - Backend/`

## Must Read

- `backend/ARCHITECTURE.txt`
- `.codex/skills/lifelevel-backend/SKILL.md`
- The relevant controller, service, DTOs, entity, and EF configuration for the feature.

## Rules

- Keep `LifeLevel.Api` thin.
- Put business logic in module use cases.
- Use SharedKernel ports for cross-module synchronous calls.
- Use domain events for side effects that should not create dependency cycles.
- Register services through module `AddXxxModule()` methods.
- Keep DTOs as records when practical.
- Return DTOs, not EF entities.
- Do not add drive-by refactors.

## Verification

Run focused tests first. For broader backend changes, run:

```powershell
cd backend
dotnet build
dotnet test
```

Report changed files, behavior, tests, and unresolved assumptions.
