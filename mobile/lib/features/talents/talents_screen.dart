import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_icon_image.dart';
import '../../core/widgets/app_toast.dart';
import '../character/providers/character_provider.dart';
import 'models/talent_models.dart';
import 'providers/talents_provider.dart';
import 'widgets/talent_draw_overlay.dart';
import 'widgets/talent_theme.dart';

class TalentsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  const TalentsScreen({super.key, this.onClose});

  @override
  ConsumerState<TalentsScreen> createState() => _TalentsScreenState();
}

class _TalentsScreenState extends ConsumerState<TalentsScreen> {
  String? _selectedKey;
  bool _busy = false;

  Future<void> _draw() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(talentsProvider.notifier).draw();
      ref.invalidate(characterProfileProvider);
      if (!mounted) return;
      setState(() => _selectedKey = result.talent.key);
      showTalentDrawnOverlay(context, result);
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upgrade(String key) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(talentsProvider.notifier).upgrade(key);
      ref.invalidate(characterProfileProvider);
      if (!mounted) return;
      AppToast.success(
          context, '${result.talent.name} → Lv.${result.newLevel}');
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(talentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onClose: widget.onClose),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.blue, strokeWidth: 2),
                ),
                error: (e, _) => _ErrorState(
                  onRetry: () => ref.read(talentsProvider.notifier).refresh(),
                ),
                data: (screen) => _Body(
                  screen: screen,
                  selectedKey: _selectedKey,
                  busy: _busy,
                  onSelect: (k) => setState(() => _selectedKey = k),
                  onDraw: _draw,
                  onUpgrade: _upgrade,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback? onClose;
  const _Header({this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            color: AppColors.textSecondary,
            onPressed: onClose ?? () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          const Text(
            'TALENTS',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final TalentScreen screen;
  final String? selectedKey;
  final bool busy;
  final ValueChanged<String> onSelect;
  final VoidCallback onDraw;
  final ValueChanged<String> onUpgrade;

  const _Body({
    required this.screen,
    required this.selectedKey,
    required this.busy,
    required this.onSelect,
    required this.onDraw,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedKey == null
        ? null
        : screen.talents.where((t) => t.key == selectedKey).firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        _CurrencyBar(wallet: screen.wallet),
        const SizedBox(height: 16),
        _TalentGrid(
          talents: screen.talents,
          selectedKey: selectedKey,
          onSelect: onSelect,
        ),
        const SizedBox(height: 16),
        if (selected != null)
          _DetailPanel(
            talent: selected,
            busy: busy,
            onUpgrade: () => onUpgrade(selected.key),
          ),
        const SizedBox(height: 16),
        _DrawButton(
          tokenCost: screen.drawTokenCost,
          coinCost: screen.drawCoinCost,
          enabled: screen.canDraw && !busy,
          onTap: onDraw,
        ),
      ],
    );
  }
}

class _CurrencyBar extends StatelessWidget {
  final TalentWallet wallet;
  const _CurrencyBar({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _pill(Icons.toll, '${wallet.coins}', AppColors.orange),
        _pill(Icons.confirmation_number_outlined, '${wallet.tokens}',
            AppColors.blue),
        _pill(Icons.auto_awesome, '${wallet.ownedCount}/${wallet.catalogCount}',
            AppColors.purple),
      ],
    );
  }

  Widget _pill(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _TalentGrid extends StatelessWidget {
  final List<TalentView> talents;
  final String? selectedKey;
  final ValueChanged<String> onSelect;

  const _TalentGrid({
    required this.talents,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
        childAspectRatio: 0.74,
      ),
      itemCount: talents.length,
      itemBuilder: (_, i) {
        final t = talents[i];
        return _TalentTile(
          talent: t,
          selected: t.key == selectedKey,
          onTap: () => onSelect(t.key),
        );
      },
    );
  }
}

class _TalentTile extends StatelessWidget {
  final TalentView talent;
  final bool selected;
  final VoidCallback onTap;

  const _TalentTile({
    required this.talent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = talentRarityColor(talent.rarity);
    final dim = !talent.owned;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? accent
                        : accent.withValues(alpha: dim ? 0.15 : 0.5),
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 12)
                        ]
                      : null,
                ),
                child: Opacity(
                  opacity: dim ? 0.4 : 1,
                  child: Center(
                    child:
                        AppIconImage(talentIconAsset(talent.iconKey), size: 30),
                  ),
                ),
              ),
              if (talent.owned)
                Positioned(
                  bottom: -3,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        'Lv.${talent.level}',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                ),
              if (talent.state == TalentTileState.upgradeable)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: const Icon(Icons.arrow_upward,
                        size: 8, color: Color(0xFF05101f)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            talent.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: dim ? AppColors.textMuted : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final TalentView talent;
  final bool busy;
  final VoidCallback onUpgrade;

  const _DetailPanel({
    required this.talent,
    required this.busy,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final accent = talentRarityColor(talent.rarity);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child:
                      AppIconImage(talentIconAsset(talent.iconKey), size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(talent.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    Text(
                      talent.owned
                          ? '${talent.rarity} · Lv.${talent.level} / ${talent.maxLevel}'
                          : '${talent.rarity} · not owned',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            talent.owned ? talent.effectText : talent.description,
            style: const TextStyle(
                fontSize: 12.5, height: 1.4, color: AppColors.textPrimary),
          ),
          if (talent.owned) ...[
            const SizedBox(height: 12),
            if (talent.isMaxed)
              const Text('Max level',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted))
            else
              Row(
                children: [
                  Text(
                    'Upgrade  ·  ${talent.upgradeShardCost} shards + ${talent.upgradeCoinCost} coins  ·  have ${talent.shards} shards',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (!talent.isMaxed)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        talent.canUpgrade ? accent : AppColors.surfaceElevated,
                    foregroundColor: talent.canUpgrade
                        ? const Color(0xFF05101f)
                        : AppColors.textMuted,
                  ),
                  onPressed: (talent.canUpgrade && !busy) ? onUpgrade : null,
                  child: Text(talent.canUpgrade
                      ? 'Upgrade to Lv.${talent.level + 1}'
                      : 'Need more shards'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DrawButton extends StatelessWidget {
  final int tokenCost;
  final int coinCost;
  final bool enabled;
  final VoidCallback onTap;

  const _DrawButton({
    required this.tokenCost,
    required this.coinCost,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
                colors: [AppColors.blue, AppColors.purple]),
            boxShadow: enabled
                ? [
                    BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 10))
                  ]
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Draw Talent Card',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF05101f))),
                const SizedBox(height: 2),
                Text('$tokenCost token · $coinCost coins',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF05101f))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load talents',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
