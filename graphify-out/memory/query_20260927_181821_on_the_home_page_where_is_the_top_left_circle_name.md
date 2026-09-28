---
type: "query"
date: "2026-09-27T18:18:21.310933+00:00"
question: "on the home page where is the top left circle name and lv when we click on the icon of the user lets get navigated to the profile page, and also on the home page if we click on the mount and sword lets get navigate to gear page"
contributor: "graphify"
outcome: "useful"
source_nodes: ["home_hero_stage.dart", "shell/main_shell.dart", "NavTabNotifier"]
---

# Q: on the home page where is the top left circle name and lv when we click on the icon of the user lets get navigated to the profile page, and also on the home page if we click on the mount and sword lets get navigate to gear page

## Answer

Expanded from original query via graph vocab: [home, hero, profile, gear, mount, sword, avatar, level, navigation, shell, notifier, tap]. HomeHeroStage now routes its avatar/name/level hit area through NavTabNotifier to profile, and both mount and weapon mini-cards through the same notifier to gear. Added semantics labels, stable keys, and a widget test confirming emitted tab ids [profile, gear, gear].

## Outcome

- Signal: useful

## Source Nodes

- home_hero_stage.dart
- shell/main_shell.dart
- NavTabNotifier