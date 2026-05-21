# Project Context Prompt

Read `backend/ARCHITECTURE.txt` in full.

Then produce a concise context brief covering:

1. Architecture style: modular monolith plus ports and adapters.
2. Module list and owned entities.
3. Project reference DAG and no-cycles rule.
4. Cross-module communication: direct ports vs domain events.
5. AppDbContext rule: one context in `LifeLevel.Api`; cross-module FKs inline there.
6. Intentional exceptions: why `MapService` and `WorldSeeder` stay in `LifeLevel.Api`.
7. SharedKernel ports: key port interfaces and what they are for.
8. What not to do: no concrete cross-module service injection, no business logic in controllers, no casual cross-module navigation properties.

End with:

`Architecture context loaded. Ready for backend work.`
