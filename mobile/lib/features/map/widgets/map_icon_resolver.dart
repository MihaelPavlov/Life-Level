import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon_image.dart';
import '../models/world_map_models.dart';

String? regionIconAsset(RegionCard region) =>
    regionThemeIconAsset(region.theme, name: region.name);

String? regionThemeIconAsset(RegionTheme? theme, {String? name}) {
  final key = _normalize(name);

  if (_hasAny(key, ['ocean', 'reef', 'trench', 'tide', 'coral'])) {
    return AppIcons.zoneCoralCoast;
  }
  if (_hasAny(key, ['mountain', 'peak', 'thunder', 'iron'])) {
    return AppIcons.zoneIronPeaks;
  }
  if (_hasAny(key, ['frost', 'glacier', 'tundra', 'ice'])) {
    return AppIcons.zoneFrostboundPeaks;
  }
  if (_hasAny(key, ['desert', 'dune', 'waste', 'sunscorch', 'mirage'])) {
    return AppIcons.zoneDesertOfTrials;
  }
  if (_hasAny(key, ['caldera', 'ash', 'ember', 'volcano', 'crater'])) {
    return AppIcons.zoneFinalApproach;
  }
  if (_hasAny(key, ['forest', 'wood', 'grove', 'verdant', 'thorn'])) {
    return AppIcons.zoneThornwoodForest;
  }

  switch (theme) {
    case RegionTheme.ocean:
      return AppIcons.zoneCoralCoast;
    case RegionTheme.mountain:
      return AppIcons.zoneIronPeaks;
    case RegionTheme.frost:
      return AppIcons.zoneFrostboundPeaks;
    case RegionTheme.desert:
      return AppIcons.zoneDesertOfTrials;
    case RegionTheme.volcano:
      return AppIcons.zoneFinalApproach;
    case RegionTheme.forest:
      return AppIcons.zoneThornwoodForest;
    case null:
      return null;
  }
}

String? zoneNodeIconAsset(
  ZoneNode node, {
  RegionTheme? regionTheme,
  String? regionName,
}) {
  final key = _normalize(node.name);

  if (node.isChest || _hasAny(key, ['chest', 'hoard', 'vault'])) {
    return AppIcons.rewardTreasureChest;
  }
  if (node.isBoss && _hasAny(key, ['forest warden'])) {
    return AppIcons.bossForestWarden;
  }
  if (node.isBoss) return AppIcons.ringBoss;
  if (node.isCrossroads || _hasAny(key, ['fork', 'crossroads'])) {
    return AppIcons.zoneFirstFork;
  }
  if (node.isDungeon ||
      _hasAny(key, ['dungeon', 'ruins', 'crypt', 'labyrinth'])) {
    return AppIcons.zoneTheConvergence;
  }
  if (_hasAny(key, ['approach', 'convergence', 'heart'])) {
    return AppIcons.zoneFinalApproach;
  }

  return regionThemeIconAsset(regionTheme, name: regionName);
}

class MapIconOrEmoji extends StatelessWidget {
  final String? asset;
  final String emoji;
  final double size;
  final double emojiSize;
  final double visualScale;
  final Color? emojiColor;
  final FontWeight? emojiWeight;
  final double? opacity;
  final Offset visualOffset;

  const MapIconOrEmoji({
    super.key,
    required this.asset,
    required this.emoji,
    required this.size,
    required this.emojiSize,
    this.visualScale = 1.45,
    this.emojiColor,
    this.emojiWeight,
    this.opacity,
    this.visualOffset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (asset != null) {
      return AppIconImage(
        asset!,
        size: size,
        visualScale: visualScale,
        visualOffset: visualOffset,
        opacity: opacity,
      );
    }

    final text = Text(
      emoji,
      style: TextStyle(
        fontSize: emojiSize,
        color: emojiColor,
        fontWeight: emojiWeight,
        height: 1,
      ),
    );

    if (opacity == null) return text;
    return Opacity(opacity: opacity!, child: text);
  }
}

String _normalize(String? value) =>
    (value ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');

bool _hasAny(String value, List<String> needles) =>
    needles.any((needle) => value.contains(needle));
