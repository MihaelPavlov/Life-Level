---
type: "query"
date: "2026-09-27T17:44:47.860968+00:00"
question: "currenthly if a boss or enocunter take hit do we have animations on the home map section boss for reducing the health ?"
contributor: "graphify"
outcome: "useful"
source_nodes: ["Boss", "HomePortalCard", "BossBattleView", "HomeProgressBar", "BlockerSheet"]
---

# Q: currenthly if a boss or enocunter take hit do we have animations on the home map section boss for reducing the health ?

## Answer

Expanded from original query via graph vocab: [boss, encounter, health, damage, animation, animate, hit, map, progress, raid]. The dedicated BossBattleView has a 1300ms hit reaction with slash, shake, floating damage, HP countdown, and ember burn when hpDealt increases. The HomePortalCard boss HP bar is not animated between old and new values: it rebuilds HomeProgressBar with a static FractionallySizedBox; its heartbeat and raid ember are idle effects. Blocker encounter HP in BlockerSheet is also a static FractionallySizedBox, and the home encounter portal shows travel distance rather than encounter HP.

## Outcome

- Signal: useful

## Source Nodes

- Boss
- HomePortalCard
- BossBattleView
- HomeProgressBar
- BlockerSheet