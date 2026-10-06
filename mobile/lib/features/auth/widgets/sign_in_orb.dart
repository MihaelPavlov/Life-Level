import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A 48px white circle holding a provider's logo, ringed in soft blue like a
/// small Map button. Used for the logo-only "Continue with …" buttons.
class SignInOrb extends StatelessWidget {
  final String semanticLabel;
  final Widget logo;
  final bool busy;
  final VoidCallback? onTap;

  const SignInOrb({
    super.key,
    required this.semanticLabel,
    required this.logo,
    required this.onTap,
    this.busy = false,
  });

  static const size = 48.0;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: AnimatedOpacity(
        opacity: onTap == null && !busy ? .5 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Painted first = lowest: the soft glow, then the blue ring,
              // then a gap in the page colour so the ring floats.
              BoxShadow(
                color: AppColors.blue.withValues(alpha: .25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.blue.withValues(alpha: .45),
                spreadRadius: 4,
              ),
              const BoxShadow(color: AppColors.background, spreadRadius: 3),
            ],
          ),
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onTap : null,
              customBorder: const CircleBorder(),
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1F1F1F),
                        ),
                      )
                    : logo,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "or continue with" between the email form and the sign-in orbs.
class SignInOrbsDivider extends StatelessWidget {
  final String label;
  const SignInOrbsDivider(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.surfaceElevated)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.surfaceElevated)),
      ],
    );
  }
}
