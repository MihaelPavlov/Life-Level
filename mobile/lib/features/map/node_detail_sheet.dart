import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'map_colors.dart';
import 'map_ui_components.dart';
import 'map_debug_panel.dart';
import 'map_banners.dart';
import 'services/boss_service.dart';
import 'services/chest_service.dart';
import 'services/dungeon_service.dart';
import 'services/crossroads_service.dart';
import 'services/map_service.dart';
import 'models/map_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NodeDetailSheet
// ─────────────────────────────────────────────────────────────────────────────
class NodeDetailSheet extends StatefulWidget {
  final MapNodeModel node;
  final bool isAdjacent;
  final double? distanceKm;
  final UserMapProgressModel userProgress;
  final VoidCallback onDestinationSet;
  final VoidCallback onRefresh;
  final void Function(int newLevel) onLevelUp;

  const NodeDetailSheet({
    super.key,
    required this.node,
    required this.isAdjacent,
    this.distanceKm,
    required this.userProgress,
    required this.onDestinationSet,
    required this.onRefresh,
    required this.onLevelUp,
  });

  @override
  State<NodeDetailSheet> createState() => _NodeDetailSheetState();
}

class _NodeDetailSheetState extends State<NodeDetailSheet> {
  bool _settingDestination = false;
  bool _bossBusy = false;
  String? _bossStatus;
  int? _localBossHpDealt;
  bool? _localBossDefeated;
  bool? _localBossActivated;
  bool? _localBossExpired;
  final _bossService = BossService();

  bool _chestBusy = false;
  String? _chestStatus;
  bool? _localChestCollected;
  final _chestService = ChestService();

  bool _dungeonBusy = false;
  String? _dungeonStatus;
  bool? _localDungeonDiscovered;
  int? _localDungeonFloor;
  final _dungeonService = DungeonService();

  bool _crossroadsBusy = false;
  String? _crossroadsStatus;
  final _crossroadsService = CrossroadsService();

  bool get _isUnlocked =>
      widget.node.isStartNode || (widget.node.userState?.isUnlocked ?? false);

  bool get _isLevelMet =>
      widget.node.isStartNode || (widget.node.userState?.isLevelMet ?? false);
  bool get _isCurrentNode => widget.node.userState?.isCurrentNode ?? false;
  bool get _isDestination => widget.node.userState?.isDestination ?? false;

  Future<void> _setDestination() async {
    setState(() => _settingDestination = true);
    try {
      await MapService().setDestination(widget.node.id);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDestinationSet();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _settingDestination = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = mapNodeColor(widget.node.type);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: kMapBorder, width: 1),
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
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
                          ),
                          child: Center(child: Text(widget.node.icon,
                            style: const TextStyle(fontSize: 26))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.node.name,
                                style: const TextStyle(color: AppColors.textPrimary,
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Wrap(spacing: 6, children: [
                                MapPill(widget.node.region, color: AppColors.purple),
                                MapPill('Lv ${widget.node.levelRequirement}+',
                                  color: _isLevelMet ? AppColors.green : AppColors.orange),
                                if (_isCurrentNode)
                                  MapPill('📍 Here', color: AppColors.green),
                                if (_isDestination)
                                  MapPill('🎯 Destination', color: AppColors.orange),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (!_isLevelMet) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kMapSurface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kMapBorder),
                        ),
                        child: Row(children: [
                          const Text('🔒', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(
                            'Reach level ${widget.node.levelRequirement} to unlock this location.',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          )),
                        ]),
                      ),
                    ] else ...[
                      if (widget.node.description != null) ...[
                        Text(widget.node.description!,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                        const SizedBox(height: 16),
                      ],
                      _buildTypeContent(),
                      const SizedBox(height: 16),
                      _buildDestinationButton(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeContent() {
    switch (widget.node.type) {
      case 'Boss': return _buildBossContent();
      case 'Chest': return _buildChestContent();
      case 'Dungeon': return _buildDungeonContent();
      case 'Crossroads': return _buildCrossroadsContent();
      default: return _buildZoneContent();
    }
  }

  Widget _buildZoneContent() {
    if (widget.distanceKm != null && !_isCurrentNode) {
      return MapInfoRow('Distance', '${widget.distanceKm!.toStringAsFixed(1)} km to reach');
    }
    return const SizedBox.shrink();
  }

  Widget _buildBossContent() {
    final boss = widget.node.boss;
    if (boss == null) return const SizedBox.shrink();

    final hpDealt     = _localBossHpDealt   ?? boss.hpDealt;
    final isDefeated  = _localBossDefeated  ?? boss.isDefeated;
    final isActivated = _localBossActivated ?? boss.isActivated;
    final isExpired   = _localBossExpired   ?? boss.isExpired;

    final hpRemaining = boss.maxHp - hpDealt;
    final hpPct = isDefeated ? 0.0 : (hpRemaining / boss.maxHp).clamp(0.0, 1.0);
    final hpBarColor = isDefeated
        ? AppColors.green
        : isExpired
            ? AppColors.textSecondary
            : AppColors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Boss header row
        Row(children: [
          Text(boss.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(boss.name,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              if (boss.isMini)
                const Text('Mini Boss · No travel required',
                  style: TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          )),
          const SizedBox(width: 8),
          if (isDefeated)
            MapPill('✓ Defeated', color: AppColors.green)
          else if (isExpired)
            MapPill('⌛ Expired', color: AppColors.textSecondary)
          else if (isActivated)
            MapPill('⚔️ Active', color: AppColors.orange),
        ]),
        const SizedBox(height: 10),

        // HP bar
        const MapSectionLabel('HP'),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: hpPct,
            minHeight: 8,
            backgroundColor: kMapSurface2,
            valueColor: AlwaysStoppedAnimation(hpBarColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(children: [
          Text('$hpDealt dealt',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const Spacer(),
          Text('$hpRemaining / ${boss.maxHp} HP remaining',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 10),

        // Stats row
        Wrap(spacing: 8, runSpacing: 6, children: [
          MapInfoChip('⚡ ${boss.rewardXp} XP reward'),
          MapInfoChip('⏱ ${boss.timerDays}d timer'),
          if (boss.isMini) MapInfoChip('🌍 Fight anywhere'),
          if (boss.timerExpiresAt != null && !isDefeated && !isExpired)
            MapInfoChip('🗓 Expires ${_formatDate(boss.timerExpiresAt!)}'),
          if (boss.defeatedAt != null)
            MapInfoChip('🏆 Defeated ${_formatDate(boss.defeatedAt!)}'),
        ]),

        // Status feedback
        if (_bossStatus != null) ...[
          const SizedBox(height: 10),
          _buildStatusMessage(_bossStatus!),
        ],

        // Action buttons
        if ((_isCurrentNode || boss.isMini) && !isDefeated) ...[
          const SizedBox(height: 14),
          if (!isActivated && !isExpired) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: boss.isMini ? AppColors.orange : AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _bossBusy ? null : () => _bossActivate(boss.id),
                child: _bossBusy
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        boss.isMini ? '⚡ Challenge Mini Boss' : '⚔️ Activate Fight',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ] else if (isActivated && !isExpired) ...[
            const MapSectionLabel('DEAL DAMAGE'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [10, 25, 50, 100, 200].map((dmg) =>
                DebugButton(
                  label: '-$dmg HP',
                  color: boss.isMini ? AppColors.orange : AppColors.red,
                  onTap: _bossBusy ? null : () => _bossDamage(boss.id, dmg),
                ),
              ).toList(),
            ),
          ] else if (isExpired) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kMapSurface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kMapBorder),
              ),
              child: const Row(children: [
                Text('⌛', style: TextStyle(fontSize: 16)),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Timer expired. Use the debug panel to reset.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                )),
              ]),
            ),
          ],
        ],
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusMessage(String status) {
    final color = status.startsWith('✓') ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _bossActivate(String bossId) async {
    setState(() { _bossBusy = true; _bossStatus = null; });
    try {
      await _bossService.activateFight(bossId);
      if (mounted) {
        final timerDays = widget.node.boss?.timerDays ?? 7;
        setState(() {
          _bossBusy = false;
          _localBossActivated = true;
          _bossStatus = '✓ Fight activated! ${timerDays}d timer started.';
        });
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) setState(() { _bossBusy = false; _bossStatus = '✗ $e'; });
    }
  }

  Future<void> _bossDamage(String bossId, int damage) async {
    setState(() { _bossBusy = true; _bossStatus = null; });
    try {
      final result = await _bossService.dealDamage(bossId, damage);
      if (mounted) {
        final defeated = result['isDefeated'] as bool? ?? false;
        final justDefeated = result['justDefeated'] as bool? ?? false;
        final newHpDealt = result['hpDealt'] as int? ?? 0;
        final maxHp = result['maxHp'] as int? ?? 0;
        final xp = result['rewardXpAwarded'] as int? ?? 0;
        setState(() {
          _bossBusy = false;
          _localBossHpDealt = newHpDealt;
          if (defeated) _localBossDefeated = true;
          _bossStatus = defeated
              ? '✓ DEFEATED! +$xp XP awarded!'
              : '✓ -$damage HP dealt ($newHpDealt/$maxHp)';
        });
        widget.onRefresh();
        if (justDefeated && mounted) {
          _showBossSlainOverlay(context, boss: widget.node.boss!, xpAwarded: xp);
          final leveledUp = result['leveledUp'] as bool? ?? false;
          final newLevel  = result['newLevel']  as int?  ?? 0;
          if (leveledUp) {
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) widget.onLevelUp(newLevel);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() { _bossBusy = false; _bossStatus = '✗ $e'; });
    }
  }

  void _showBossSlainOverlay(BuildContext context, {required BossData boss, required int xpAwarded}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => BossSlainOverlay(boss: boss, xpAwarded: xpAwarded),
    );
  }

  Widget _buildChestContent() {
    final chest = widget.node.chest;
    if (chest == null) return const SizedBox.shrink();
    final isCollected = _localChestCollected ?? chest.isCollected;
    final rarityColor = mapRarityColor(chest.rarity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          MapPill(chest.rarity, color: rarityColor),
          const SizedBox(width: 8),
          MapInfoChip('⚡ ${chest.rewardXp} XP'),
          const SizedBox(width: 8),
          if (isCollected) MapPill('✓ Collected', color: AppColors.green),
        ]),

        if (_chestStatus != null) ...[
          const SizedBox(height: 10),
          _buildStatusMessage(_chestStatus!),
        ],

        if (_isCurrentNode && !isCollected) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kMapGold,
                foregroundColor: const Color(0xFF1a1000),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _chestBusy ? null : () => _collectChest(chest.id),
              child: _chestBusy
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Color(0xFF1a1000), strokeWidth: 2))
                  : const Text('📦 Open Chest',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _collectChest(String chestId) async {
    setState(() { _chestBusy = true; _chestStatus = null; });
    try {
      final result = await _chestService.collect(chestId);
      if (mounted) {
        final xp = result['rewardXp'] as int? ?? 0;
        final rarity = result['rarity'] as String? ?? '';
        setState(() { _chestBusy = false; _localChestCollected = true; });
        widget.onRefresh();
        if (mounted) _showChestRewardDialog(rarity, xp);
        final leveledUp = result['leveledUp'] as bool? ?? false;
        final newLevel  = result['newLevel']  as int?  ?? 0;
        if (leveledUp && mounted) {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) widget.onLevelUp(newLevel);
        }
      }
    } catch (e) {
      if (mounted) setState(() { _chestBusy = false; _chestStatus = '✗ $e'; });
    }
  }

  void _showChestRewardDialog(String rarity, int xp) {
    final color = mapRarityColor(rarity);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => ChestRewardDialog(rarity: rarity, xp: xp, color: color),
    );
  }

  Widget _buildDungeonContent() {
    final dungeon = widget.node.dungeonPortal;
    if (dungeon == null) return const SizedBox.shrink();

    final currentFloor = _localDungeonFloor ?? dungeon.currentFloor;
    final isDiscovered = _localDungeonDiscovered ?? dungeon.isDiscovered;
    final isFullyCleared = currentFloor >= dungeon.totalFloors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(dungeon.name,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700))),
          if (isFullyCleared)
            MapPill('✓ Cleared', color: AppColors.green)
          else if (isDiscovered)
            MapPill('Floor $currentFloor/${dungeon.totalFloors}', color: AppColors.purple)
          else
            MapPill('Undiscovered', color: AppColors.textSecondary),
        ]),
        const SizedBox(height: 12),
        const MapSectionLabel('FLOORS'),
        const SizedBox(height: 6),
        ...dungeon.floors.map((f) {
          final isCompleted = f.floorNumber <= currentFloor;
          final isNextFloor = f.floorNumber == currentFloor + 1 && isDiscovered;
          return DungeonFloorRow(
            floor: f,
            isCompleted: isCompleted,
            isNext: isNextFloor && _isCurrentNode,
            isBusy: _dungeonBusy,
            onComplete: _isCurrentNode && isNextFloor && !_dungeonBusy
                ? () => _completeFloor(dungeon.id, f.floorNumber)
                : null,
          );
        }),

        if (_dungeonStatus != null) ...[
          const SizedBox(height: 10),
          _buildStatusMessage(_dungeonStatus!),
        ],

        if (_isCurrentNode && !isDiscovered) ...[
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _dungeonBusy ? null : () => _enterDungeon(dungeon.id),
              child: _dungeonBusy
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('🌀 Enter Dungeon',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _enterDungeon(String dungeonId) async {
    setState(() { _dungeonBusy = true; _dungeonStatus = null; });
    try {
      await _dungeonService.enter(dungeonId);
      if (mounted) {
        setState(() {
          _dungeonBusy = false;
          _localDungeonDiscovered = true;
          _dungeonStatus = '✓ Entered dungeon. Complete floors below.';
        });
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) setState(() { _dungeonBusy = false; _dungeonStatus = '✗ $e'; });
    }
  }

  Future<void> _completeFloor(String dungeonId, int floorNumber) async {
    setState(() { _dungeonBusy = true; _dungeonStatus = null; });
    try {
      final result = await _dungeonService.completeFloor(dungeonId, floorNumber);
      if (mounted) {
        final xp = result['rewardXp'] as int? ?? 0;
        final isCleared = result['isFullyCleared'] as bool? ?? false;
        final newFloor = result['currentFloor'] as int? ?? floorNumber;
        setState(() {
          _dungeonBusy = false;
          _localDungeonFloor = newFloor;
          _dungeonStatus = isCleared
              ? '✓ Dungeon cleared! +$xp XP'
              : '✓ Floor $floorNumber complete! +$xp XP';
        });
        widget.onRefresh();
        final leveledUp = result['leveledUp'] as bool? ?? false;
        final newLevel  = result['newLevel']  as int?  ?? 0;
        if (leveledUp && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) widget.onLevelUp(newLevel);
        }
      }
    } catch (e) {
      if (mounted) setState(() { _dungeonBusy = false; _dungeonStatus = '✗ $e'; });
    }
  }

  Widget _buildCrossroadsContent() {
    final crossroads = widget.node.crossroads;
    if (crossroads == null) return const SizedBox.shrink();
    final hasChosen = crossroads.chosenPathId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Expanded(child: MapSectionLabel('CHOOSE YOUR PATH')),
          if (hasChosen) MapPill('Path chosen', color: AppColors.orange),
        ]),
        const SizedBox(height: 8),
        if (!hasChosen && _isCurrentNode)
          const Text(
            'Tap a path to commit to it. This cannot be changed.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        if (!hasChosen && _isCurrentNode) const SizedBox(height: 10),
        ...crossroads.paths.map((p) {
          final isChosen = crossroads.chosenPathId == p.id;
          final canChoose = !hasChosen && _isCurrentNode && !_crossroadsBusy;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SelectablePathCard(
              path: p,
              isChosen: isChosen,
              isDisabled: hasChosen && !isChosen,
              canChoose: canChoose,
              onTap: canChoose ? () => _choosePath(crossroads.id, p.id) : null,
            ),
          );
        }),

        if (_crossroadsStatus != null) ...[
          const SizedBox(height: 4),
          _buildCrossroadsStatusMessage(_crossroadsStatus!),
        ],
      ],
    );
  }

  Widget _buildCrossroadsStatusMessage(String status) {
    final isSuccess = status.startsWith('✓');
    final color = isSuccess ? AppColors.orange : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _choosePath(String crossroadsId, String pathId) async {
    setState(() { _crossroadsBusy = true; _crossroadsStatus = null; });
    try {
      final result = await _crossroadsService.choosePath(crossroadsId, pathId);
      if (mounted) {
        final name = result['pathName'] as String? ?? '';
        setState(() { _crossroadsBusy = false; _crossroadsStatus = '✓ "$name" chosen — journey begins!'; });
        widget.onRefresh();
        final leveledUp = result['leveledUp'] as bool? ?? false;
        final newLevel  = result['newLevel']  as int?  ?? 0;
        if (leveledUp && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) widget.onLevelUp(newLevel);
        }
      }
    } catch (e) {
      if (mounted) setState(() { _crossroadsBusy = false; _crossroadsStatus = '✗ $e'; });
    }
  }

  Widget _buildDestinationButton() {
    if (_isCurrentNode) return const SizedBox.shrink();
    if (!widget.isAdjacent) {
      return Text('Not reachable from current location',
        style: TextStyle(color: AppColors.textSecondary.withOpacity(0.6), fontSize: 12));
    }
    if (_isDestination) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.orange.withOpacity(0.4)),
        ),
        child: const Center(child: Text('🎯 Currently Heading Here',
          style: TextStyle(color: AppColors.orange, fontSize: 14, fontWeight: FontWeight.w600))),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _settingDestination ? null : _setDestination,
        child: _settingDestination
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text('Set Destination → ${widget.distanceKm != null ? "${widget.distanceKm!.toStringAsFixed(1)} km" : ""}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}
