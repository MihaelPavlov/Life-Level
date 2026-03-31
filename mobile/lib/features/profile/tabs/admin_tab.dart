import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';

const _kSurface = Color(0xFF161b22);
const _kBorder = Color(0xFF30363d);
const _kTextPri = Color(0xFFe6edf3);
const _kTextSec = Color(0xFF8b949e);
const _kBlue = Color(0xFF4f9eff);
const _kPurple = Color(0xFFa371f7);

class AdminTab extends StatelessWidget {
  const AdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Panel',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kTextPri),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage items, map, and player data',
            style: TextStyle(fontSize: 12, color: _kTextSec),
          ),
          const SizedBox(height: 20),
          _AdminMenuCard(
            icon: '⚙️',
            accentColor: _kBlue,
            title: 'Item Catalog',
            subtitle: 'Add, edit, and delete items in the game catalog',
            onTap: () => _openUrl(ApiClient.adminPanelUrl),
          ),
          const SizedBox(height: 10),
          _AdminMenuCard(
            icon: '🎯',
            accentColor: _kBlue,
            title: 'Drop Rules',
            subtitle: 'Configure how and when items are acquired',
            onTap: () => _openUrl(ApiClient.adminPanelUrl),
          ),
          const SizedBox(height: 10),
          _AdminMenuCard(
            icon: '🎁',
            accentColor: _kBlue,
            title: 'Grant Item',
            subtitle: 'Manually award items to a player',
            onTap: () => _openUrl(ApiClient.adminPanelUrl),
          ),
          const SizedBox(height: 20),
          const Text(
            'Map',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextSec),
          ),
          const SizedBox(height: 10),
          _AdminMenuCard(
            icon: '🗺️',
            accentColor: _kPurple,
            title: 'Map Panel',
            subtitle: 'Manage nodes, edges, and bosses on the adventure map',
            onTap: () => _openUrl(ApiClient.adminMapUrl),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(Future<String> urlFuture) async {
    final url = await urlFuture;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}

class _AdminMenuCard extends StatelessWidget {
  final String icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentColor.withOpacity(0.30)),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: _kTextPri)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: _kTextSec)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: _kTextSec),
          ],
        ),
      ),
    );
  }
}
