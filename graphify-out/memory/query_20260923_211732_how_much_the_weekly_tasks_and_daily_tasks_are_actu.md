---
type: "query"
date: "2026-09-23T21:17:32.565296+00:00"
question: "How much the weekly tasks and daily tasks are actually undertandble ?"
contributor: "graphify"
outcome: "useful"
source_nodes: ["Quest", "QuestService.cs", "QuestSeedData.cs", "weekly_quests_tab.dart"]
---

# Q: How much the weekly tasks and daily tasks are actually undertandble ?

## Answer

Expanded from original query via graph vocab: [quest, task, daily, weekly, reward, progress, requirement, target, description, milestone, claim]. Assessment: task definitions are mostly clear in seed data, but the Rewards sheet hides descriptions and required activity, uses very small 7-11px labels, and leaves point and milestone behavior unexplained. Daily wording has a logic mismatch: tasks described as single-session goals are accumulated across sessions by QuestService. Weekly aggregate wording matches backend behavior better. Overall Daily 4/10, Weekly 6/10 in the Rewards sheet.

## Outcome

- Signal: useful

## Source Nodes

- Quest
- QuestService.cs
- QuestSeedData.cs
- weekly_quests_tab.dart