import 'package:flutter/material.dart';

import '../services/apple_sign_in_coordinator.dart';
import 'provider_logos.dart';
import 'sign_in_orb.dart';

/// Logo-only "Continue with Apple" orb. Renders nothing where Sign in with
/// Apple isn't available (Android, web), and adds its own trailing gap so the
/// Google orb stays centred when it's alone.
class AppleSignInButton extends StatefulWidget {
  final Future<void> Function(AppleCredential credential) onCredential;
  final ValueChanged<String>? onError;
  final bool enabled;

  const AppleSignInButton({
    super.key,
    required this.onCredential,
    this.onError,
    this.enabled = true,
  });

  @override
  State<AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<AppleSignInButton> {
  final _coordinator = AppleSignInCoordinator.instance;
  late final Future<bool> _available = _coordinator.isAvailable();
  bool _busy = false;

  Future<void> _authenticate() async {
    if (_busy || !widget.enabled) return;
    setState(() => _busy = true);
    try {
      final credential = await _coordinator.authenticate();
      if (credential != null) await widget.onCredential(credential);
    } on AppleSignInFlowException catch (e) {
      widget.onError?.call(e.message);
    } catch (_) {
      widget.onError?.call('Apple sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_coordinator.isSupportedPlatform) return const SizedBox.shrink();
    return FutureBuilder<bool>(
      future: _available,
      initialData: _coordinator.cachedAvailable,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 18),
          child: SignInOrb(
            key: const Key('apple-sign-in-button'),
            semanticLabel: 'Continue with Apple',
            busy: _busy,
            onTap: widget.enabled ? _authenticate : null,
            logo: const AppleLogo(height: 22),
          ),
        );
      },
    );
  }
}
