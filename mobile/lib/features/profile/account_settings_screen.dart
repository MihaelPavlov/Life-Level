import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../auth/models/account_models.dart';
import '../auth/services/auth_service.dart';
import '../auth/services/google_sign_in_coordinator.dart';
import '../auth/widgets/google_sign_in_button.dart';
import 'profile_stat_metadata.dart';
import '../../core/widgets/app_toast.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _emailController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late Future<AccountInfo> _accountFuture;
  bool _savingEmail = false;
  bool _savingPassword = false;

  @override
  void initState() {
    super.initState();
    _accountFuture = AuthService().getAccount();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveEmail() async {
    if (_savingEmail) return;
    setState(() => _savingEmail = true);
    try {
      final result = await AuthService().updateEmail(
        email: _emailController.text,
        currentPassword: _emailPasswordController.text,
      );
      await ApiClient.saveToken(result.token);
      _emailPasswordController.clear();
      if (!mounted) return;
      AppToast.success(context, 'Email updated');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _savingEmail = false);
    }
  }

  Future<void> _savePassword() async {
    if (_savingPassword) return;
    setState(() => _savingPassword = true);
    try {
      await AuthService().changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (!mounted) return;
      AppToast.success(context, 'Password updated');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _setGooglePassword() async {
    if (_savingPassword) return;
    if (_newPasswordController.text.length < 8) {
      AppToast.error(context, 'New password must be at least 8 characters.');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      AppToast.error(context, 'New password confirmation does not match.');
      return;
    }
    setState(() => _savingPassword = true);
    try {
      await GoogleSignInCoordinator.instance.signOut();
      if (!mounted) return;
      final googleToken = await showDialog<String>(
        context: context,
        builder: (_) => const _GoogleReauthDialog(),
      );
      if (googleToken == null) return;
      await AuthService().setPasswordWithGoogle(
        googleIdToken: googleToken,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (!mounted) return;
      setState(() => _accountFuture = AuthService().getAccount());
      AppToast.success(context, 'Password added');
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPBg,
      appBar: AppBar(
        backgroundColor: kPBg,
        foregroundColor: kPTextPri,
        title: const Text('Email & Password'),
      ),
      body: FutureBuilder<AccountInfo>(
        future: _accountFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            );
          }
          if (snapshot.hasData && _emailController.text.isEmpty) {
            _emailController.text = snapshot.data!.email;
          }

          final account = snapshot.data;
          final hasPassword = account?.hasPassword ?? true;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Section(
                title: 'Email',
                children: [
                  _Field(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    enabled: hasPassword,
                  ),
                  if (!hasPassword && account?.googleConnected == true) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Managed by your connected Google account.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    _Field(
                      controller: _emailPasswordController,
                      label: 'Current password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 14),
                    _ActionButton(
                      label: _savingEmail ? 'SAVING...' : 'SAVE EMAIL',
                      onPressed: _savingEmail ? null : _saveEmail,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              _Section(
                title: 'Password',
                children: [
                  if (hasPassword) ...[
                    _Field(
                      controller: _currentPasswordController,
                      label: 'Current password',
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                  ],
                  _Field(
                    controller: _newPasswordController,
                    label: 'New password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  _Field(
                    controller: _confirmPasswordController,
                    label: 'Confirm new password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 14),
                  _ActionButton(
                    label: _savingPassword
                        ? 'SAVING...'
                        : hasPassword
                            ? 'SAVE PASSWORD'
                            : 'VERIFY GOOGLE & ADD PASSWORD',
                    onPressed: _savingPassword
                        ? null
                        : hasPassword
                            ? _savePassword
                            : _setGooglePassword,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceElevated),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kPTextPri,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;

  const _Field({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.backgroundAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _GoogleReauthDialog extends StatefulWidget {
  const _GoogleReauthDialog();

  @override
  State<_GoogleReauthDialog> createState() => _GoogleReauthDialogState();
}

class _GoogleReauthDialogState extends State<_GoogleReauthDialog> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify with Google'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Sign in again before adding a Life-Level password.'),
          const SizedBox(height: 18),
          GoogleSignInButton(
            onToken: (token) async => Navigator.pop(context, token),
            onError: (message) => setState(() => _error = message),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _ActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          disabledBackgroundColor: AppColors.surfaceElevated,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label),
      ),
    );
  }
}
