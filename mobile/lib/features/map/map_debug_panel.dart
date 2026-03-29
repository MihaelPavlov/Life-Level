import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../character/providers/character_provider.dart';
import 'map_colors.dart';
import 'boss_service.dart';
import 'chest_service.dart';
import 'dungeon_service.dart';
import 'crossroads_service.dart';
import 'map_service.dart';
import 'models/map_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MapDebugPanel
// ─────────────────────────────────────────────────────────────────────────────
class MapDebugPanel extends ConsumerStatefulWidget {
  final List<MapNodeModel> nodes;
  final UserMapProgressModel userProgress;
  final MapService service;
  final BossService bossService;
  final VoidCallback onRefresh;

  const MapDebugPanel({
    super.key,
    required this.nodes,
    required this.userProgress,
    required this.service,
    required this.bossService,
    required this.onRefresh,
  });

  @override
  ConsumerState<MapDebugPanel> createState() => _MapDebugPanelState();
}

class _MapDebugPanelState extends ConsumerState<MapDebugPanel> {
  bool _busy = false;
  String? _status;
  int? _currentLevel;
  int? _currentXp;
  String? _selectedBossId;
  String? _selectedBossName;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    ApiClient.isAdmin().then((v) { if (mounted) setState(() => _isAdmin = v); });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() { _busy = true; _status = null; });
    try {
      await action();
      widget.onRefresh();
      if (mounted) setState(() { _busy = false; _status = '✓ Done'; });
    } catch (e) {
      if (mounted) setState(() { _busy = false; _status = '✗ $e'; });
    }
  }

  Future<void> _adjustLevel(int delta) async {
    setState(() { _busy = true; _status = null; });
    try {
      final newLevel = await widget.service.debugAdjustLevel(delta);
      if (mounted) setState(() { _busy = false; _currentLevel = newLevel; _status = '✓ Level $newLevel'; });
      // Refresh map node locks + character profile (fires LevelUpNotifier if level increased).
      widget.onRefresh();
      await ref.read(characterProfileProvider.notifier).refresh();
    } catch (e) {
      if (mounted) setState(() { _busy = false; _status = '✗ $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleNodes = widget.nodes
        .where((n) => !n.isHidden || (n.userState?.isUnlocked ?? false) || n.isStartNode)
        .toList();
    final hasDestination = widget.userProgress.destinationNodeId != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161b22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFF30363d))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(children: [
                const Text('🛠️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text('Debug Panel',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_busy)
                  const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: AppColors.purple, strokeWidth: 2)),
                if (_status != null)
                  Text(_status!,
                    style: TextStyle(
                      color: _status!.startsWith('✓') ? AppColors.green : AppColors.red,
                      fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
            const Divider(color: Color(0xFF30363d), height: 1),
            if (_isAdmin)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: InkWell(
                  onTap: () async {
                    final token = await ApiClient.getToken();
                    final uri = Uri.parse('http://localhost:5128/admin-map')
                        .replace(queryParameters: token != null ? {'token': token} : null);
                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.purple.withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('⚙️', style: TextStyle(fontSize: 15)),
                        SizedBox(width: 8),
                        Text('Open Admin Portal',
                          style: TextStyle(color: AppColors.purple,
                            fontSize: 13, fontWeight: FontWeight.w700)),
                        SizedBox(width: 6),
                        Icon(Icons.open_in_new, color: AppColors.purple, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            if (_isAdmin)
              const SizedBox(height: 6),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Level controls ─────────────────────────────────────
                    const Text('CHARACTER LEVEL',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Row(children: [
                      DebugButton(
                        label: '− Level Down',
                        color: AppColors.red,
                        onTap: _busy ? null : () => _adjustLevel(-1),
                      ),
                      const SizedBox(width: 8),
                      if (_currentLevel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.orange.withOpacity(0.4)),
                          ),
                          child: Text('Lv $_currentLevel',
                            style: const TextStyle(color: AppColors.orange,
                              fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      const SizedBox(width: 8),
                      DebugButton(
                        label: '+ Level Up',
                        color: AppColors.green,
                        onTap: _busy ? null : () => _adjustLevel(1),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Travel controls ────────────────────────────────────
                    const Text('SIMULATE TRAVEL',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    hasDestination
                      ? Wrap(
                          spacing: 8, runSpacing: 8,
                          children: [1.0, 3.0, 5.0, 10.0, 99.0].map((km) =>
                            DebugButton(
                              label: km == 99.0 ? 'Complete' : '+${km.toStringAsFixed(0)} km',
                              color: km == 99.0 ? AppColors.green : AppColors.blue,
                              onTap: _busy ? null : () => _run(() => widget.service.debugAddDistance(km)),
                            ),
                          ).toList(),
                        )
                      : Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                          ),
                          child: const Row(children: [
                            Text('⚠️', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 8),
                            Text('Set a destination first',
                              style: TextStyle(color: AppColors.orange, fontSize: 12)),
                          ]),
                        ),
                    const SizedBox(height: 20),
                    const Text('TELEPORT TO NODE',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    ...visibleNodes.map((node) {
                      final isCurrent = node.id == widget.userProgress.currentNodeId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: _busy || isCurrent
                              ? null
                              : () => _run(() => widget.service.debugTeleport(node.id)),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? mapNodeColor(node.type).withOpacity(0.15)
                                  : const Color(0xFF1e2632),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCurrent
                                    ? mapNodeColor(node.type).withOpacity(0.5)
                                    : const Color(0xFF30363d),
                              ),
                            ),
                            child: Row(children: [
                              Text(node.icon, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(node.name,
                                    style: TextStyle(
                                      color: isCurrent ? mapNodeColor(node.type) : AppColors.textPrimary,
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(node.region,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              )),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('HERE',
                                    style: TextStyle(color: AppColors.green, fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                                )
                              else
                                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                            ]),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // ── XP controls ────────────────────────────────────────
                    const Text('CHARACTER XP',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      DebugButton(
                        label: '+1 000 XP',
                        color: AppColors.orange,
                        onTap: _busy ? null : () async {
                          setState(() { _busy = true; _status = null; });
                          try {
                            final newXp = await widget.service.debugSetXp((_currentXp ?? 0) + 1000);
                            if (mounted) setState(() { _busy = false; _currentXp = newXp; _status = '✓ XP: $newXp'; });
                            widget.onRefresh();
                            await ref.read(characterProfileProvider.notifier).refresh();
                          } catch (e) {
                            if (mounted) setState(() { _busy = false; _status = '✗ $e'; });
                          }
                        },
                      ),
                      DebugButton(
                        label: '+5 000 XP',
                        color: AppColors.orange,
                        onTap: _busy ? null : () async {
                          setState(() { _busy = true; _status = null; });
                          try {
                            final newXp = await widget.service.debugSetXp((_currentXp ?? 0) + 5000);
                            if (mounted) setState(() { _busy = false; _currentXp = newXp; _status = '✓ XP: $newXp'; });
                            widget.onRefresh();
                            await ref.read(characterProfileProvider.notifier).refresh();
                          } catch (e) {
                            if (mounted) setState(() { _busy = false; _status = '✗ $e'; });
                          }
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Node unlock controls ───────────────────────────────
                    const Text('NODE UNLOCKS',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      DebugButton(
                        label: '🔓 Unlock All',
                        color: AppColors.green,
                        onTap: _busy ? null : () => _run(() => widget.service.debugUnlockAll()),
                      ),
                      DebugButton(
                        label: '🔴 Reset Progress',
                        color: AppColors.red,
                        onTap: _busy ? null : () => _run(() => widget.service.debugResetProgress()),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Boss fight debug ───────────────────────────────────
                    const Text('BOSS FIGHT',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    // Boss selector
                    ...widget.nodes.where((n) => n.type == 'Boss' && n.boss != null).map((node) {
                      final isSelected = _selectedBossId == node.boss!.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => setState(() {
                            _selectedBossId = node.boss!.id;
                            _selectedBossName = node.boss!.name;
                          }),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.red.withOpacity(0.15)
                                  : const Color(0xFF1e2632),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.red.withOpacity(0.5)
                                    : const Color(0xFF30363d),
                              ),
                            ),
                            child: Row(children: [
                              Text(node.boss!.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(node.boss!.name,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.red : AppColors.textPrimary,
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text('${node.boss!.hpDealt}/${node.boss!.maxHp} HP dealt',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                ],
                              )),
                              if (node.boss!.isDefeated)
                                const Text('✓', style: TextStyle(color: AppColors.green, fontSize: 14, fontWeight: FontWeight.w700))
                              else if (node.boss!.isExpired)
                                const Text('⌛', style: TextStyle(fontSize: 14))
                              else if (node.boss!.isActivated)
                                const Text('⚔️', style: TextStyle(fontSize: 14))
                              else
                                const Text('💤', style: TextStyle(fontSize: 14)),
                            ]),
                          ),
                        ),
                      );
                    }),
                    if (_selectedBossId != null) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        DebugButton(
                          label: '½ HP',
                          color: AppColors.orange,
                          onTap: _busy ? null : () async {
                            final boss = widget.nodes
                                .where((n) => n.boss?.id == _selectedBossId)
                                .first.boss!;
                            await _run(() => widget.bossService.debugSetHp(_selectedBossId!, boss.maxHp ~/ 2));
                          },
                        ),
                        DebugButton(
                          label: '⚔️ Force Defeat',
                          color: AppColors.green,
                          onTap: _busy ? null : () => _run(() => widget.bossService.debugForceDefeat(_selectedBossId!)),
                        ),
                        DebugButton(
                          label: '⌛ Force Expire',
                          color: AppColors.textSecondary,
                          onTap: _busy ? null : () => _run(() => widget.bossService.debugForceExpire(_selectedBossId!)),
                        ),
                        DebugButton(
                          label: '🔄 Reset',
                          color: AppColors.blue,
                          onTap: _busy ? null : () => _run(() => widget.bossService.debugReset(_selectedBossId!)),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 20),

                    // ── Chest debug ────────────────────────────────────────
                    const Text('CHESTS',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    ...widget.nodes.where((n) => n.type == 'Chest' && n.chest != null).map((node) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Text(node.icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(node.name,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                          if (node.chest!.isCollected)
                            const Text('✓', style: TextStyle(color: AppColors.green, fontSize: 14, fontWeight: FontWeight.w700))
                          else
                            DebugButton(
                              label: 'Reset',
                              color: AppColors.blue,
                              onTap: _busy ? null : () => _run(() => ChestService().debugReset(node.chest!.id)),
                            ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Dungeon debug ──────────────────────────────────────
                    const Text('DUNGEONS',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    ...widget.nodes.where((n) => n.type == 'Dungeon' && n.dungeonPortal != null).map((node) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1e2632),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF30363d)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text(node.icon, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(node.name,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                                Text('Floor ${node.dungeonPortal!.currentFloor}/${node.dungeonPortal!.totalFloors}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ]),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                ...List.generate(node.dungeonPortal!.totalFloors + 1, (i) =>
                                  DebugButton(
                                    label: 'Floor $i',
                                    color: i == node.dungeonPortal!.currentFloor
                                        ? AppColors.purple
                                        : AppColors.textSecondary,
                                    onTap: _busy ? null : () => _run(
                                      () => DungeonService().debugSetFloor(node.dungeonPortal!.id, i)),
                                  ),
                                ),
                                DebugButton(
                                  label: '🔄 Reset',
                                  color: AppColors.blue,
                                  onTap: _busy ? null : () => _run(() => DungeonService().debugReset(node.dungeonPortal!.id)),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Crossroads debug ───────────────────────────────────
                    const Text('CROSSROADS',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    ...widget.nodes.where((n) => n.type == 'Crossroads' && n.crossroads != null).map((node) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Text(node.icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(node.name,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                              Text(
                                node.crossroads!.chosenPathId != null
                                    ? 'Path chosen'
                                    : 'No path chosen',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          )),
                          DebugButton(
                            label: '🔄 Reset',
                            color: AppColors.blue,
                            onTap: _busy ? null : () => _run(() => CrossroadsService().debugReset(node.crossroads!.id)),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DebugButton
// ─────────────────────────────────────────────────────────────────────────────
class DebugButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const DebugButton({super.key, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(onTap == null ? 0.05 : 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(onTap == null ? 0.2 : 0.5)),
        ),
        child: Text(label,
          style: TextStyle(
            color: onTap == null ? color.withOpacity(0.4) : color,
            fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
