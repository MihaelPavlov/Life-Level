import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/google_sign_in_coordinator.dart';
import 'provider_logos.dart';
import 'sign_in_orb.dart';
import 'google_web_button_stub.dart'
    if (dart.library.html) 'google_web_button.dart';

class GoogleSignInButton extends StatefulWidget {
  final Future<void> Function(String idToken) onToken;
  final ValueChanged<String>? onError;
  final bool enabled;

  const GoogleSignInButton({
    super.key,
    required this.onToken,
    this.onError,
    this.enabled = true,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final coordinator = GoogleSignInCoordinator.instance;
      if (coordinator.isConfigured) {
        unawaited(coordinator.initialize().catchError((Object error) {
          if (mounted) widget.onError?.call(error.toString());
        }));
        _subscription = coordinator.authenticationEvents.listen(
          (event) {
            if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
              _submit(coordinator.tokenForEvent(event));
            }
          },
          onError: (Object error) => widget.onError?.call(error.toString()),
        );
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _authenticate() async {
    try {
      final token = await GoogleSignInCoordinator.instance.authenticate();
      if (token != null) await _submit(token);
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled) {
        widget.onError?.call(error.description ?? 'Google sign-in failed.');
      }
    } catch (error) {
      widget.onError?.call(error.toString());
    }
  }

  Future<void> _submit(String token) async {
    if (_busy || !widget.enabled) return;
    setState(() => _busy = true);
    try {
      await widget.onToken(token);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      if (!GoogleSignInCoordinator.instance.isConfigured) {
        return const SizedBox.shrink();
      }
      return IgnorePointer(
        ignoring: !widget.enabled || _busy,
        child: Center(child: buildGoogleWebButton()),
      );
    }

    return SignInOrb(
      key: const Key('google-sign-in-button'),
      semanticLabel: 'Continue with Google',
      busy: _busy,
      onTap: widget.enabled ? _authenticate : null,
      logo: const GoogleGLogo(size: 22),
    );
  }
}
