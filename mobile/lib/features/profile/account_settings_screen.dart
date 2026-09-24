import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../auth/models/account_models.dart';
import '../auth/services/auth_service.dart';
import 'profile_stat_metadata.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
                  ),
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
              ),
              const SizedBox(height: 18),
              _Section(
                title: 'Password',
                children: [
                  _Field(
                    controller: _currentPasswordController,
                    label: 'Current password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
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
                    label: _savingPassword ? 'SAVING...' : 'SAVE PASSWORD',
                    onPressed: _savingPassword ? null : _savePassword,
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

  const _Field({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
