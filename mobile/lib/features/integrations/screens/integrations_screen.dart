import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/integration_models.dart';
import '../providers/integrations_provider.dart';
import '../services/garmin_service.dart';
import '../services/strava_service.dart';
import '../widgets/integration_tile.dart';
import '../widgets/sync_status_banner.dart';

class IntegrationsScreen extends ConsumerStatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  ConsumerState<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends ConsumerState<IntegrationsScreen> {
  SyncResult? _bannerResult;
  String? _pendingGarminVerifier;

  @override
  void initState() {
    super.initState();
    // Deep link handling is owned by MainShell — do not add a second listener here.
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _connectStrava(BuildContext context) async {
    try {
      // Open in external browser (not Chrome Custom Tab) so the deep link
      // redirect lifelevel://oauth/strava is handled correctly on MIUI.
      await launchUrl(
        Uri.parse(StravaService().authorizationUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Strava OAuth error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Strava error: $e')),
        );
      }
    }
  }

  Future<void> _connectGarmin(BuildContext context) async {
    try {
      final verifier = GarminService.generateCodeVerifier();
      final challenge = GarminService.generateCodeChallenge(verifier);
      _pendingGarminVerifier = verifier;
      await launchUrl(
        Uri.parse(GarminService().authorizationUrl(challenge)),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Garmin OAuth error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Garmin error: $e')),
        );
      }
    }
  }

  void _showBanner(SyncResult result) {
    setState(() => _bannerResult = result);
  }

  void _dismissBanner() {
    if (mounted) setState(() => _bannerResult = null);
  }

  void _showHealthSyncHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161b22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Using Health Sync',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFe6edf3),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'If you use a Mi Band, Huawei, or Honor wearable, you can bridge your data into Health Connect using the free "Health Sync" app:',
              style: TextStyle(fontSize: 13, color: Color(0xFF8b949e)),
            ),
            const SizedBox(height: 12),
            _helpStep('1', 'Install Health Sync from the Play Store'),
            _helpStep('2', 'Open Health Sync and select your device app as source (e.g. Zepp Life or HUAWEI Health)'),
            _helpStep('3', 'Set Health Connect as the destination'),
            _helpStep('4', 'Run a sync — your workouts will appear here automatically'),
          ],
        ),
      ),
    );
  }

  Widget _helpStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF4f9eff).withOpacity(0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4f9eff),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFFe6edf3)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final state = ref.watch(integrationSyncProvider);

    // Show banner when sync result arrives
    ref.listen<IntegrationSyncState>(integrationSyncProvider, (prev, next) {
      if (!next.isSyncing && next.lastResult != null) {
        if (prev?.lastResult != next.lastResult) {
          _showBanner(next.lastResult!);
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF040810),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: top),
          _Header(onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                if (_bannerResult != null)
                  SyncStatusBanner(result: _bannerResult!, onDismiss: _dismissBanner),

                _SectionLabel('DEVICE HEALTH'),
                IntegrationTile(
                  emoji: '❤️',
                  title: 'Health Connect / Apple Health',
                  subtitle: 'Sync workouts from your phone\'s health store',
                  isConnected: state.isHealthConnected,
                  isSyncing: state.isSyncing,
                  lastSyncAt: state.lastSyncAt,
                  onConnect: () =>
                      ref.read(integrationSyncProvider.notifier).requestPermissions(),
                  onSyncNow: () =>
                      ref.read(integrationSyncProvider.notifier).syncNow(),
                ),

                const SizedBox(height: 12),
                _SectionLabel('CONNECTED APPS'),
                _StravaIntegrationTile(
                  isConnected: state.isStravaConnected,
                  athleteName: state.stravaAthleteName,
                  onConnect: () => _connectStrava(context),
                  onDisconnect: () =>
                      ref.read(integrationSyncProvider.notifier).disconnectStrava(),
                ),
                _GarminIntegrationTile(
                  isConnected: state.isGarminConnected,
                  displayName: state.garminDisplayName,
                  onConnect: () => _connectGarmin(context),
                  onDisconnect: () =>
                      ref.read(integrationSyncProvider.notifier).disconnectGarmin(),
                ),

                const SizedBox(height: 12),
                _SectionLabel('COMPATIBLE DEVICES'),
                _InfoTile(
                  emoji: '✅',
                  title: 'Samsung, Amazfit & OPPO',
                  subtitle:
                      'Watches from these brands sync automatically via Health Connect — no extra setup needed.',
                ),
                _InfoTile(
                  emoji: '🔄',
                  title: 'Mi Band (Zepp Life) & Huawei',
                  subtitle:
                      'Install the free "Health Sync" app and configure it to bridge your data into Health Connect.',
                  actionLabel: 'How it works',
                  onAction: () => _showHealthSyncHelp(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF161b22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF30363d)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Color(0xFF8b949e),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Integrations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFe6edf3),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8b949e),
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

// ── Strava integration tile ───────────────────────────────────────────────────
class _StravaIntegrationTile extends StatelessWidget {
  final bool isConnected;
  final String? athleteName;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _StravaIntegrationTile({
    required this.isConnected,
    required this.onConnect,
    required this.onDisconnect,
    this.athleteName,
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
          color: isConnected ? const Color(0xFFFC4C02) : const Color(0xFF30363d),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isConnected ? const Color(0xFF2d1a12) : const Color(0xFF1e2632),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnected ? const Color(0xFFFC4C02) : const Color(0xFF30363d),
              ),
            ),
            child: const Center(
              child: Text('🚴', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strava',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isConnected
                        ? const Color(0xFFFC4C02)
                        : const Color(0xFFe6edf3),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isConnected
                      ? (athleteName != null
                          ? 'Connected as $athleteName'
                          : 'Connected')
                      : 'Auto-import runs, rides & more via OAuth',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8b949e)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isConnected ? onDisconnect : onConnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isConnected
                    ? const Color(0xFF2d1a12)
                    : const Color(0xFF1e2632),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isConnected
                      ? const Color(0xFFFC4C02)
                      : const Color(0xFF30363d),
                ),
              ),
              child: Text(
                isConnected ? 'Disconnect' : 'Connect',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isConnected
                      ? const Color(0xFFFC4C02)
                      : const Color(0xFF4f9eff),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Garmin integration tile ───────────────────────────────────────────────────
class _GarminIntegrationTile extends StatelessWidget {
  final bool isConnected;
  final String? displayName;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _GarminIntegrationTile({
    required this.isConnected,
    required this.onConnect,
    required this.onDisconnect,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF009BDE);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConnected ? brandColor : const Color(0xFF30363d),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isConnected ? const Color(0xFF0a1e2d) : const Color(0xFF1e2632),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnected ? brandColor : const Color(0xFF30363d),
              ),
            ),
            child: const Center(child: Text('🏃', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Garmin Connect',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isConnected ? brandColor : const Color(0xFFe6edf3),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isConnected
                      ? (displayName != null ? 'Connected as $displayName' : 'Connected')
                      : 'Coming soon — integration scaffolded',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8b949e)),
                ),
              ],
            ),
          ),
          // TODO: replace with connect/disconnect button when Garmin credentials are set
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1e2632),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF30363d)),
            ),
            child: const Text(
              'Soon',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8b949e),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info tile ─────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InfoTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFe6edf3),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8b949e)),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4f9eff),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
