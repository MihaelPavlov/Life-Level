import 'package:flutter/material.dart';

enum TrailEncounterType { story, merchant, blocker }

class TrailEncounterNode {
  final String id;
  final String fromZoneId;
  final String toZoneId;
  final double t;
  final double sideOffset;
  final TrailEncounterType type;
  final MerchantEncounterData? merchant;
  final BlockerEncounterData? blocker;
  final StoryEncounterData? story;

  const TrailEncounterNode({
    required this.id,
    required this.fromZoneId,
    required this.toZoneId,
    required this.t,
    required this.sideOffset,
    required this.type,
    this.merchant,
    this.blocker,
    this.story,
  });

  factory TrailEncounterNode.fromJson(Map<String, dynamic> json) {
    final type = TrailEncounterType.values.byName(json['type'] as String);
    return TrailEncounterNode(
      id: json['id'] as String,
      fromZoneId: json['fromZoneId'] as String,
      toZoneId: json['toZoneId'] as String,
      t: (json['t'] as num).toDouble(),
      sideOffset: (json['sideOffset'] as num? ?? 0).toDouble(),
      type: type,
      merchant: json['merchant'] != null
          ? MerchantEncounterData.fromJson(json['merchant'] as Map<String, dynamic>)
          : null,
      blocker: json['blocker'] != null
          ? BlockerEncounterData.fromJson(json['blocker'] as Map<String, dynamic>)
          : null,
      story: json['story'] != null
          ? StoryEncounterData.fromJson(json['story'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromZoneId': fromZoneId,
        'toZoneId': toZoneId,
        't': t,
        'sideOffset': sideOffset,
        'type': type.name,
        if (merchant != null) 'merchant': merchant!.toJson(),
        if (blocker != null) 'blocker': blocker!.toJson(),
        if (story != null) 'story': story!.toJson(),
      };
}

// ─── Merchant ────────────────────────────────────────────────────────────────

class MerchantItem {
  final String? itemId;
  final String emoji;
  final String name;
  final String description;
  final String rarity; // 'rare' | 'uncommon' | 'mystery'
  final int xpCost;

  const MerchantItem({
    this.itemId,
    required this.emoji,
    required this.name,
    required this.description,
    required this.rarity,
    required this.xpCost,
  });

  factory MerchantItem.fromJson(Map<String, dynamic> j) => MerchantItem(
        itemId: j['itemId'] as String?,
        emoji: j['emoji'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        rarity: j['rarity'] as String,
        xpCost: j['xpCost'] as int,
      );

  Map<String, dynamic> toJson() => {
        if (itemId != null) 'itemId': itemId,
        'emoji': emoji,
        'name': name,
        'description': description,
        'rarity': rarity,
        'xpCost': xpCost,
      };
}

class MerchantEncounterData {
  final String name;
  final Duration timeLeft;
  final List<MerchantItem> items;
  final int playerXp;

  const MerchantEncounterData({
    required this.name,
    required this.timeLeft,
    required this.items,
    required this.playerXp,
  });

  factory MerchantEncounterData.fromJson(Map<String, dynamic> j) =>
      MerchantEncounterData(
        name: j['name'] as String,
        timeLeft: Duration(seconds: j['timeLeftSeconds'] as int),
        items: (j['items'] as List<dynamic>)
            .map((e) => MerchantItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        playerXp: j['playerXp'] as int,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'timeLeftSeconds': timeLeft.inSeconds,
        'items': items.map((e) => e.toJson()).toList(),
        'playerXp': playerXp,
      };
}

// ─── Blocker ─────────────────────────────────────────────────────────────────

class BlockerEncounterData {
  final String name;
  final String blockedZoneName;
  final int maxHp;
  final int currentHp;
  final int playerDamageDone;
  final String? lastHitDescription;
  final Duration retreatsIn;
  final List<String> rewards;

  const BlockerEncounterData({
    required this.name,
    required this.blockedZoneName,
    required this.maxHp,
    required this.currentHp,
    required this.playerDamageDone,
    this.lastHitDescription,
    required this.retreatsIn,
    required this.rewards,
  });

  bool get isInCombat => playerDamageDone > 0;
  double get hpFraction => currentHp / maxHp;

  factory BlockerEncounterData.fromJson(Map<String, dynamic> j) =>
      BlockerEncounterData(
        name: j['name'] as String,
        blockedZoneName: j['blockedZoneName'] as String,
        maxHp: j['maxHp'] as int,
        currentHp: j['currentHp'] as int,
        playerDamageDone: j['playerDamageDone'] as int? ?? 0,
        lastHitDescription: j['lastHitDescription'] as String?,
        retreatsIn: Duration(seconds: j['retreatsInSeconds'] as int),
        rewards: List<String>.from(j['rewards'] as List),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'blockedZoneName': blockedZoneName,
        'maxHp': maxHp,
        'currentHp': currentHp,
        'playerDamageDone': playerDamageDone,
        if (lastHitDescription != null) 'lastHitDescription': lastHitDescription,
        'retreatsInSeconds': retreatsIn.inSeconds,
        'rewards': rewards,
      };
}

// ─── Story ────────────────────────────────────────────────────────────────────

class StoryChoice {
  final String text;
  final String iconEmoji;
  final Color iconBg;
  final String rewardLabel;
  final Color rewardColor;

  const StoryChoice({
    required this.text,
    required this.iconEmoji,
    required this.iconBg,
    required this.rewardLabel,
    required this.rewardColor,
  });
}

class StoryEncounterData {
  final String npcName;
  final String npcTitle;
  final String portrait;
  final String dialogue;
  final int loreXp;
  final List<StoryChoice> choices;

  const StoryEncounterData({
    required this.npcName,
    required this.npcTitle,
    required this.portrait,
    required this.dialogue,
    required this.loreXp,
    required this.choices,
  });

  factory StoryEncounterData.fromJson(Map<String, dynamic> j) =>
      StoryEncounterData(
        npcName: j['npcName'] as String,
        npcTitle: j['npcTitle'] as String,
        portrait: j['portrait'] as String,
        dialogue: j['dialogue'] as String,
        loreXp: j['loreXp'] as int,
        choices: const [], // hydrated in code, not from API
      );

  Map<String, dynamic> toJson() => {
        'npcName': npcName,
        'npcTitle': npcTitle,
        'portrait': portrait,
        'dialogue': dialogue,
        'loreXp': loreXp,
      };
}
