import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class IntegrationTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isConnected;
  final bool isSyncing;
  final DateTime? lastSyncAt;
  final VoidCallback? onConnect;
  final VoidCallback? onSyncNow;

  const IntegrationTile({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isConnected,
    required this.isSyncing,
    this.lastSyncAt,
    this.onConnect,
    this.onSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConnected
              ? AppColors.green.withOpacity(0.35)
              : const Color(0xFF30363d),
        ),
      ),
      child: Row(
        children: [
          // icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.green.withOpacity(0.12)
                  : const Color(0xFF1e2632),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnected
                    ? AppColors.green.withOpacity(0.35)
                    : const Color(0xFF30363d),
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),

          const SizedBox(width: 14),

          // text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFe6edf3),
                      ),
                    ),
                    if (isConnected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.green.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'Connected',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isConnected && lastSyncAt != null
                      ? 'Last synced: ${_formatSyncTime(lastSyncAt!)}'
                      : subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8b949e),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // action
          if (!isConnected)
            _ActionButton(
              label: 'Connect',
              color: AppColors.blue,
              onTap: isSyncing ? null : onConnect,
            )
          else if (isSyncing)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.blue,
              ),
            )
          else
            _ActionButton(
              label: 'Sync',
              color: AppColors.blue,
              onTap: onSyncNow,
            ),
        ],
      ),
    );
  }

  static String _formatSyncTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}
