import 'dart:math';
import 'package:flutter/material.dart';
import 'main_shell.dart' show kAllRingItems, RingItem, kAllNavItems, NavTab, anglesFor;

const _kSheetBg   = Color(0xFF0f1828);
const _kCardBg    = Color(0xFF1a2848);
const _kSurfaceBg = Color(0xFF111830);
const _kBorder    = Color(0xFF1e2d4a);
const _kTextPri   = Color(0xFFdde8ff);
const _kTextSec   = Color(0xFF6e84b0);
const _kTeal      = Color(0xFF38d9c8);

const _kMaxRing = 6;
const _kMinRing = 1;
const _kNavCount = 4; // nav bar always has exactly 4 tabs

class CustomizeRingSheet extends StatefulWidget {
  final List<String> currentIds;
  final List<String> currentNavIds;
  final void Function(List<String> ringIds, List<String> navIds) onSave;

  const CustomizeRingSheet({
    super.key,
    required this.currentIds,
    required this.currentNavIds,
    required this.onSave,
  });

  @override
  State<CustomizeRingSheet> createState() => _CustomizeRingSheetState();
}

class _CustomizeRingSheetState extends State<CustomizeRingSheet> {
  late List<String> _ids;
  late List<String> _navIds;

  @override
  void initState() {
    super.initState();
    _ids    = List.from(widget.currentIds);
    _navIds = List.from(widget.currentNavIds);
  }

  // ── ring helpers ──────────────────────────────────────────────────────────
  bool _inRing(String id) => _ids.contains(id);

  void _toggleRing(String id) {
    setState(() {
      if (_inRing(id)) {
        // Remove only if more than the minimum remains
        if (_ids.length > _kMinRing) _ids.remove(id);
      } else {
        if (_ids.length < _kMaxRing) _ids.add(id);
        // Ring full → do nothing; user must remove one first
      }
    });
  }

  // ── nav helpers ───────────────────────────────────────────────────────────
  bool _inNav(String id) => _navIds.contains(id);

  void _toggleNav(String id) {
    setState(() {
      if (_inNav(id)) {
        // Swap out with first available replacement to keep exactly _kNavCount
        final replacement = kAllNavItems
            .where((e) => !_navIds.contains(e.id) && e.id != id)
            .firstOrNull;
        if (replacement != null) {
          _navIds[_navIds.indexOf(id)] = replacement.id;
        }
      } else {
        // Swap in — replace last slot
        if (_navIds.length < _kNavCount) {
          _navIds.add(id);
        } else {
          _navIds[_navIds.length - 1] = id;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: _kSheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Column(
        children: [
          // ── handle ──────────────────────────────────────────────────────
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2a3a5a),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Customize',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _kTextPri)),
                      const SizedBox(height: 2),
                      Text('Ring 1–6 slots · Nav bar 4 tabs',
                          style: const TextStyle(fontSize: 11, color: _kTextSec)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    widget.onSave(_ids, _navIds);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kTeal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Done',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF090d1a))),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── scrollable body ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── ring preview ───────────────────────────────────────
                  _RingPreview(ids: _ids),

                  const SizedBox(height: 20),

                  // ── ring items section ─────────────────────────────────
                  _SectionLabel('RING ITEMS  ·  ${_ids.length} / $_kMaxRing'),
                  const SizedBox(height: 8),

                  for (final item in kAllRingItems) ...[
                    _DestRow(
                      emoji: item.emoji,
                      label: item.label,
                      color: item.color,
                      active: _inRing(item.id),
                      statusText: _inRing(item.id)
                          ? 'In ring · slot ${_ids.indexOf(item.id) + 1}'
                          : _ids.length < _kMaxRing
                              ? 'Tap to add'
                              : 'Ring full — remove one first',
                      statusDim: !_inRing(item.id) && _ids.length >= _kMaxRing,
                      canInteract: _inRing(item.id)
                          ? _ids.length > _kMinRing   // can remove if > 1
                          : _ids.length < _kMaxRing,  // can add if < 6
                      actionLabel: _inRing(item.id) ? '✓' : '+',
                      onTap: () => _toggleRing(item.id),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 12),

                  // ── nav bar preview ────────────────────────────────────
                  _NavPreview(navIds: _navIds),

                  const SizedBox(height: 20),

                  // ── nav tabs section ───────────────────────────────────
                  _SectionLabel('NAV BAR TABS  ·  $_kNavCount fixed slots'),
                  const SizedBox(height: 8),

                  for (final tab in kAllNavItems) ...[
                    _DestRow(
                      emoji: tab.emoji,
                      label: tab.label,
                      color: const Color(0xFF4f9eff),
                      active: _inNav(tab.id),
                      statusText: _inNav(tab.id)
                          ? 'In nav bar · slot ${_navIds.indexOf(tab.id) + 1}'
                          : 'Tap to swap in',
                      statusDim: false,
                      canInteract: true,
                      actionLabel: _inNav(tab.id) ? '✓' : '⇄',
                      onTap: () => _toggleNav(tab.id),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 10,
            color: _kTextSec,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7));
  }
}

// ── ring preview ──────────────────────────────────────────────────────────────
class _RingPreview extends StatelessWidget {
  final List<String> ids;
  const _RingPreview({required this.ids});

  @override
  Widget build(BuildContext context) {
    const previewRadius = 46.0;
    const itemSize = 24.0;
    const boxSize = 120.0;

    final items = ids
        .map((id) => kAllRingItems.firstWhere((e) => e.id == id))
        .toList();
    final n = items.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Stack(
        children: [
          // label
          const Positioned(
            top: 0, left: 0,
            child: Text('PREVIEW',
                style: TextStyle(
                    fontSize: 9,
                    color: _kTextSec,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6)),
          ),
          // slot count
          Positioned(
            bottom: 0, right: 0,
            child: Text('${ids.length} / $_kMaxRing slots',
                style: const TextStyle(fontSize: 9, color: _kTextSec)),
          ),
          // ring
          Center(
            child: SizedBox(
              width: boxSize,
              height: boxSize,
              child: Stack(
                children: [
                  // centre boss button
                  Positioned(
                    left: boxSize / 2 - 16,
                    top:  boxSize / 2 - 16,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFff4040), Color(0xFFff8040)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                          child: Text('⚔️', style: TextStyle(fontSize: 16))),
                    ),
                  ),
                  // ring items
                  for (int i = 0; i < n; i++) ...[
                    Builder(builder: (_) {
                      final spread = n == 1 ? 0.0 : 120.0 / (n - 1);
                      final angleDeg = 30.0 + spread * i;
                      final rad = angleDeg * pi / 180;
                      final cx = boxSize / 2 + cos(rad) * previewRadius;
                      final cy = boxSize / 2 - sin(rad) * previewRadius;
                      final item = items[i];
                      return Positioned(
                        left: cx - itemSize / 2,
                        top:  cy - itemSize / 2,
                        child: Container(
                          width: itemSize, height: itemSize,
                          decoration: BoxDecoration(
                            color: _kCardBg,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: item.color.withOpacity(0.5)),
                          ),
                          child: Center(
                            child: Text(item.emoji,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      );
                    }),
                  ],
                  // empty slots
                  for (int i = n; i < _kMaxRing; i++) ...[
                    Builder(builder: (_) {
                      const spread = 120.0 / (_kMaxRing - 1);
                      final angleDeg = 30.0 + spread * i;
                      final rad = angleDeg * pi / 180;
                      final cx = boxSize / 2 + cos(rad) * previewRadius;
                      final cy = boxSize / 2 - sin(rad) * previewRadius;
                      return Positioned(
                        left: cx - itemSize / 2,
                        top:  cy - itemSize / 2,
                        child: Container(
                          width: itemSize, height: itemSize,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                                color: _kBorder,
                                style: BorderStyle.solid,
                                width: 1.5),
                          ),
                          child: const Center(
                            child: Text('+',
                                style: TextStyle(
                                    fontSize: 12, color: _kTextSec)),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── nav bar preview ───────────────────────────────────────────────────────────
class _NavPreview extends StatelessWidget {
  final List<String> navIds;
  const _NavPreview({required this.navIds});

  @override
  Widget build(BuildContext context) {
    final tabs = navIds
        .map((id) => kAllNavItems.firstWhere((e) => e.id == id))
        .toList();
    final half = tabs.length ~/ 2;

    return Container(
      decoration: BoxDecoration(
        color: _kSurfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NAV BAR PREVIEW',
              style: TextStyle(
                  fontSize: 8,
                  color: _kTextSec,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6)),
          const SizedBox(height: 10),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF111830),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                // left tabs
                for (int i = 0; i < half; i++)
                  Expanded(child: _MiniNavItem(tab: tabs[i], active: i == 0)),
                // FAB gap
                Container(
                  width: 52,
                  alignment: Alignment.center,
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFff4040), Color(0xFFff8040)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                        child: Text('⚔️', style: TextStyle(fontSize: 13))),
                  ),
                ),
                // right tabs
                for (int i = half; i < tabs.length; i++)
                  Expanded(child: _MiniNavItem(tab: tabs[i], active: false)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniNavItem extends StatelessWidget {
  final NavTab tab;
  final bool active;
  const _MiniNavItem({required this.tab, required this.active});

  @override
  Widget build(BuildContext context) {
    const activeColor   = Color(0xFF4f9eff);
    const inactiveColor = Color(0xFF6e84b0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(tab.emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Text(tab.label,
            style: TextStyle(
                fontSize: 7,
                color: active ? activeColor : inactiveColor,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
      ],
    );
  }
}

// ── generic destination row ───────────────────────────────────────────────────
class _DestRow extends StatelessWidget {
  final String emoji;
  final String label;
  final Color  color;
  final bool   active;
  final String statusText;
  final bool   statusDim;
  final bool   canInteract;
  final String actionLabel;
  final VoidCallback onTap;

  const _DestRow({
    required this.emoji,
    required this.label,
    required this.color,
    required this.active,
    required this.statusText,
    required this.statusDim,
    required this.canInteract,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canInteract ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? _kCardBg : _kSurfaceBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? color.withOpacity(0.4) : _kBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: active
                    ? color.withOpacity(0.12)
                    : const Color(0xFF162040),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kTextPri)),
                  const SizedBox(height: 2),
                  Text(statusText,
                      style: TextStyle(
                          fontSize: 10,
                          color: statusDim
                              ? const Color(0xFF4a5a70)
                              : _kTextSec)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: active
                    ? color.withOpacity(0.2)
                    : const Color(0xFF162040),
                border: Border.all(
                  color: active
                      ? color.withOpacity(0.7)
                      : const Color(0xFF2a3a5a),
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  actionLabel,
                  style: TextStyle(
                      fontSize: 10,
                      color: active
                          ? color
                          : canInteract
                              ? const Color(0xFF3a5070)
                              : const Color(0xFF2a3a5a),
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
