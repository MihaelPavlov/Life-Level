Read the file `backend/ARCHITECTURE.txt` in full.

Then output a concise context brief covering:

1. **Architecture style** — one sentence on what this is (modular monolith + ports & adapters)
2. **Module list** — all 11 modules with their owned entities
3. **Project reference DAG** — which modules can reference which (no cycles rule)
4. **Cross-module communication rules** — Tier 1 (direct port calls) vs Tier 2 (domain events)
5. **AppDbContext rule** — single context in LifeLevel.Api; cross-module FKs configured inline there
6. **Intentional exceptions** — MapService and WorldSeeder stay in LifeLevel.Api and why
7. **SharedKernel ports** — list the key port interfaces (ICharacterXpPort, ICharacterStatPort, ICharacterLevelReadPort, IStreakReadPort, IStreakShieldPort, ILoginRewardReadPort, IDailyQuestReadPort, IMapProgressReadPort)
8. **What NOT to do** — no concrete service registrations in Program.cs (only AddXxxModule()), no cross-module nav properties on entities, no direct service-to-service injection across module boundaries

End with: "Architecture context loaded. Ready for backend work."
