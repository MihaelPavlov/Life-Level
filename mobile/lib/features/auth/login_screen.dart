import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/motion/app_motion.dart';
import '../../core/widgets/main_shell.dart';
import '../character/setup/setup_resume_service.dart';
import '../character/setup/welcome_setup_screen.dart';
import 'services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _authService.login(
        emailOrUsername: _identifierCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await ApiClient.saveToken(result.token);
      if (result.isSetupComplete) {
        await SetupResumeService.instance.clear();
      } else {
        await SetupResumeService.instance.saveWelcome(
          ringItems: result.ringItems,
        );
      }
      if (mounted) {
        if (result.isSetupComplete) {
          Navigator.pushReplacement(
            context,
            AppRoute(
                builder: (_) => MainShell(initialRingIds: result.ringItems)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            AppRoute(
                builder: (_) =>
                    WelcomeSetupScreen(ringItems: result.ringItems)),
          );
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Login failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo / title
                  const Text(
                    'LIFE LEVEL',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Train in the real world.\nProgress in a game world.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 48),

                  // Email or Username
                  _AuthField(
                    controller: _identifierCtrl,
                    label: 'Email or Username',
                    keyboardType: TextInputType.text,
                    validator: (v) =>
                        v != null && (v.contains('@') || v.length >= 3)
                            ? null
                            : 'Enter your email or username',
                  ),
                  const SizedBox(height: 16),

                  // Password
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
                      style:
                          const TextStyle(color: AppColors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 24),

                  // Login button
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
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
                        : const Text('LOGIN',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5)),
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            AppRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('Sign up',
                            style: TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
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
