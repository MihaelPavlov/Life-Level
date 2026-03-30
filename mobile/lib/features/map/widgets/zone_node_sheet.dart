import 'package:flutter/material.dart';
import '../map_ui_components.dart';
import '../models/map_models.dart';

class ZoneNodeSheet extends StatelessWidget {
  final MapNodeModel node;
  final bool isCurrentNode;
  final double? distanceKm;

  const ZoneNodeSheet({
    super.key,
    required this.node,
    required this.isCurrentNode,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    if (distanceKm != null && !isCurrentNode) {
      return MapInfoRow('Distance', '${distanceKm!.toStringAsFixed(1)} km to reach');
    }
    return const SizedBox.shrink();
  }
}
