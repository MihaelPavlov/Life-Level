import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../character/models/xp_history_entry.dart';
import '../character/providers/character_provider.dart';
import 'profile_stat_metadata.dart';

// ── XpHistorySheet ────────────────────────────────────────────────────────────
class XpHistorySheet extends ConsumerWidget {
  const XpHistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(xpHistoryProvider);
    final entries = historyAsync.valueOrNull;
    final totalXp = entries?.fold<int>(0, (sum, e) => sum + e.xp) ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: BoxDecoration(
        color: const Color(0xFF0f1828),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: kPBlue.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2a3a5a),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kPBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPBlue.withOpacity(0.4)),
                  ),
                  child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XP History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kPTextPri),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Experience gained',
                      style: TextStyle(fontSize: 11, color: kPTextSec),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: kPBorder2, height: 1),

          // body
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: kPBlue)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Failed to load history',
                      style: TextStyle(color: kPTextPri, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => ref.invalidate(xpHistoryProvider),
                      child: const Text('Retry', style: TextStyle(color: kPBlue)),
                    ),
                  ],
                ),
              ),
              data: (list) => list.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('⚡', style: TextStyle(fontSize: 40)),
                          SizedBox(height: 12),
                          Text(
                            'No XP earned yet',
                            style: TextStyle(color: kPTextPri, fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Complete activities to earn XP',
                            style: TextStyle(color: kPTextSec, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(color: kPBorder2, height: 1),
                      itemBuilder: (_, i) => XpEntryRow(entry: list[i]),
                    ),
            ),
          ),

          // total footer — only when data is loaded and non-empty
          if (entries != null && entries.isNotEmpty) ...[
            const Divider(color: kPBorder2, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL XP EARNED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kPTextSec,
                      letterSpacing: 0.7,
                    ),
                  ),
                  Text(
                    '+${totalXp >= 1000 ? '${(totalXp / 1000).toStringAsFixed(1)}k' : totalXp} XP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kPBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── XpEntryRow ────────────────────────────────────────────────────────────────
class XpEntryRow extends StatelessWidget {
  final XpHistoryEntry entry;
  const XpEntryRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kPBlue.withOpacity(0.25)),
            ),
            child: Center(
              child: Text(entry.sourceEmoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.source,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPTextPri)),
                const SizedBox(height: 2),
                Text(entry.description,
                    style: const TextStyle(fontSize: 11, color: kPTextSec)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${entry.xp} XP',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kPBlue)),
              const SizedBox(height: 2),
              Text(entry.timeAgo, style: const TextStyle(fontSize: 10, color: kPTextSec)),
            ],
          ),
        ],
      ),
    );
  }
}
