import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/motion/app_motion.dart';
import '../../core/widgets/main_shell.dart';
import '../character/setup/setup_resume_service.dart';
import '../onboarding/onboarding_flow.dart';
import 'services/apple_sign_in_coordinator.dart';
import 'services/auth_service.dart';

Future<void> finishAuthentication(
    BuildContext context, AuthResult result) async {
  await ApiClient.saveToken(result.token);
  // A new Google or Apple player names their hero before the rest of setup.
  final firstStep =
      result.needsUsername ? SetupStep.username : SetupStep.welcome;
  if (result.isSetupComplete) {
    await SetupResumeService.instance.clear();
  } else {
    await SetupResumeService.instance.save(
        SetupResumeState(step: firstStep, ringItems: result.ringItems));
  }
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    AppRoute(
      builder: (_) => result.isSetupComplete
          ? MainShell(initialRingIds: result.ringItems)
          : OnboardingFlow(
              initial: SetupResumeState(
                  step: firstStep, ringItems: result.ringItems),
            ),
    ),
    (_) => false,
  );
}

Future<AuthResult?> authenticateGoogle(
  BuildContext context,
  AuthService authService,
  String idToken,
) async {
  try {
    return await authService.signInWithGoogle(idToken: idToken);
  } on GoogleAccountLinkRequiredException {
    if (!context.mounted) return null;
    final password = await _requestExistingPassword(context,
        provider: 'Google', fieldKey: const Key('google-link-password'));
    if (password == null || password.isEmpty) return null;
    return authService.signInWithGoogle(
      idToken: idToken,
      currentPassword: password,
    );
  }
}

Future<AuthResult?> authenticateApple(
  BuildContext context,
  AuthService authService,
  AppleCredential credential,
) async {
  try {
    return await authService.signInWithApple(credential: credential);
  } on AppleAccountLinkRequiredException {
    if (!context.mounted) return null;
    final password = await _requestExistingPassword(context,
        provider: 'Apple', fieldKey: const Key('apple-link-password'));
    if (password == null || password.isEmpty) return null;
    // The server checks the same token and nonce again, so it must be used
    // within Apple's token lifetime (minutes).
    return authService.signInWithApple(
      credential: credential,
      currentPassword: password,
    );
  }
}

Future<String?> _requestExistingPassword(
  BuildContext context, {
  required String provider,
  required Key fieldKey,
}) async {
  final controller = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Connect existing account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This email already has a Life-Level account. Enter its password to connect $provider.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: fieldKey,
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Current password'),
              onSubmitted: (value) => Navigator.pop(dialogContext, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('CONNECT'),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}
