import 'package:flutter/material.dart';
import 'profile_stat_metadata.dart';

// ── ProfileRankBadge ──────────────────────────────────────────────────────────
class ProfileRankBadge extends StatelessWidget {
  final String rank;
  final Color color;
  const ProfileRankBadge({super.key, required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.40)),
      ),
      child: Text(
        rank,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── ProfileMiniCard ───────────────────────────────────────────────────────────
class ProfileMiniCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String sub;
  const ProfileMiniCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kPSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: kPTextSec,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kPTextPri,
            ),
          ),
          Text(sub, style: const TextStyle(fontSize: 9, color: kPTextSec)),
        ],
      ),
    );
  }
}

// ── ProfilePlaceholderTab ─────────────────────────────────────────────────────
class ProfilePlaceholderTab extends StatelessWidget {
  final String label;
  final String emoji;
  const ProfilePlaceholderTab(this.label, this.emoji, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kPTextPri,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coming soon',
            style: TextStyle(fontSize: 12, color: kPTextSec),
          ),
        ],
      ),
    );
  }
}

// ── ProfileSheetSection ───────────────────────────────────────────────────────
class ProfileSheetSection extends StatelessWidget {
  final String label;
  final Color color;
  final List<String> items;
  const ProfileSheetSection({
    super.key,
    required this.label,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in items) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 5, right: 10),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 12, color: kPTextPri, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}
