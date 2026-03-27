import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/api/api_client.dart';
import 'auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final result = await _authService.register(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await ApiClient.saveToken(result.token);
      if (mounted) {
        // TODO: navigate to main screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, ${result.username}! Your adventure begins.')),
        );
      }
    } catch (e) {
      setState(() => _error = 'Registration failed. Email or username may already be taken.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'CREATE ACCOUNT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Begin your journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 40),

                  _AuthField(
                    controller: _usernameCtrl,
                    label: 'Username',
                    validator: (v) =>
                        v != null && v.length >= 3 ? null : 'Min 3 characters',
                  ),
                  const SizedBox(height: 16),

                  _AuthField(
                    controller: _emailCtrl,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v != null && v.contains('@') ? null : 'Enter a valid email',
                  ),
                  const SizedBox(height: 16),

                  _AuthField(
                    controller: _passwordCtrl,
                    label: 'Password',
                    obscureText: true,
                    validator: (v) =>
                        v != null && v.length >= 6 ? null : 'Min 6 characters',
                  ),
                  const SizedBox(height: 12),

                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: _loading ? null : _register,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('START ADVENTURE',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceElevated),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceElevated),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
    );
  }
}
