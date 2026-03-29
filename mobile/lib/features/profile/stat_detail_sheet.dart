import 'package:flutter/material.dart';
import '../character/character_service.dart';
import 'profile_stat_metadata.dart';
import 'profile_widgets.dart';

// ── StatDetailSheet ───────────────────────────────────────────────────────────
class StatDetailSheet extends StatefulWidget {
  final StatData stat;
  final int availablePoints;
  final VoidCallback onStatSpent;
  const StatDetailSheet({
    super.key,
    required this.stat,
    required this.availablePoints,
    required this.onStatSpent,
  });

  @override
  State<StatDetailSheet> createState() => _StatDetailSheetState();
}

class _StatDetailSheetState extends State<StatDetailSheet> {
  bool _spending = false;

  Future<void> _spendPoint() async {
    setState(() => _spending = true);
    try {
      await CharacterService().spendStatPoint(widget.stat.key);
      widget.onStatSpent();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _spending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.stat.value / 100.0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(top: 120),
      decoration: BoxDecoration(
        color: const Color(0xFF0f1828),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: widget.stat.color.withOpacity(0.25)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // header row
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.stat.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.stat.color.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(widget.stat.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.stat.label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: kPTextPri,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.stat.key,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.stat.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // value badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.stat.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.stat.color.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${widget.stat.value}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: widget.stat.color,
                    ),
                  ),
                ),
                // + button — only when points available
                if (widget.availablePoints > 0) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _spending ? null : _spendPoint,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.stat.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: widget.stat.color.withOpacity(0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: widget.stat.color.withOpacity(0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: _spending
                          ? Padding(
                              padding: const EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: widget.stat.color),
                            )
                          : Icon(Icons.add, size: 18, color: widget.stat.color),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 8, color: kPSurface2),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.stat.color,
                        boxShadow: [
                          BoxShadow(
                            color: widget.stat.color.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current: ${widget.stat.value} / 100',
                  style: const TextStyle(fontSize: 10, color: kPTextSec),
                ),
                Text(
                  '${(pct * 100).round()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: widget.stat.color,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // description
            Text(
              widget.stat.description,
              style: const TextStyle(fontSize: 13, color: kPTextPri, height: 1.55),
            ),

            const SizedBox(height: 20),

            // raised by
            ProfileSheetSection(
              label: 'RAISED BY',
              color: widget.stat.color,
              items: widget.stat.activities,
            ),

            const SizedBox(height: 16),

            // perks
            ProfileSheetSection(
              label: 'HIGH ${widget.stat.key} PERKS',
              color: widget.stat.color,
              items: widget.stat.perks,
            ),
          ],
        ),
      ),
    );
  }
}
