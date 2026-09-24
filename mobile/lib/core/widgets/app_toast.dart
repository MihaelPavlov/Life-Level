import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../motion/app_motion.dart';

enum AppToastType { info, success, error, warning }

class AppToast {
  AppToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void info(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(context, message,
          type: AppToastType.info, icon: icon, duration: duration);

  static void success(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_rounded,
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(context, message,
          type: AppToastType.success, icon: icon, duration: duration);

  static void error(
    BuildContext context,
    String message, {
    IconData icon = Icons.priority_high_rounded,
    Duration duration = const Duration(seconds: 4),
  }) =>
      show(context, message,
          type: AppToastType.error, icon: icon, duration: duration);

  static void warning(
    BuildContext context,
    String message, {
    IconData icon = Icons.warning_amber_rounded,
    Duration duration = const Duration(seconds: 3),
  }) =>
      show(context, message,
          type: AppToastType.warning, icon: icon, duration: duration);

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _timer?.cancel();
    _entry?.remove();

    _entry = OverlayEntry(
      builder: (context) => _AppToastOverlay(
        message: message,
        type: type,
        icon: icon ?? _defaultIcon(type),
      ),
    );
    overlay.insert(_entry!);

    _timer = Timer(duration, dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }

  static IconData _defaultIcon(AppToastType type) => switch (type) {
        AppToastType.success => Icons.check_rounded,
        AppToastType.error => Icons.priority_high_rounded,
        AppToastType.warning => Icons.warning_amber_rounded,
        AppToastType.info => Icons.info_outline_rounded,
      };
}

class _AppToastOverlay extends StatelessWidget {
  final String message;
  final AppToastType type;
  final IconData icon;

  const _AppToastOverlay({
    required this.message,
    required this.type,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(type);
    final bottom = MediaQuery.paddingOf(context).bottom + 86;

    return Positioned(
      left: 18,
      right: 18,
      bottom: bottom,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          duration: AppMotion.duration(
            context,
            const Duration(milliseconds: 220),
          ),
          curve: Curves.easeOutCubic,
          tween: Tween(
            begin: AppMotion.isFull(context) ? 18 : 0,
            end: 0,
          ),
          builder: (context, offset, child) {
            return Transform.translate(
              offset: Offset(0, offset),
              child: AnimatedOpacity(
                opacity: offset == 0 ? 1 : 0.96,
                duration: AppMotion.duration(
                  context,
                  const Duration(milliseconds: 160),
                ),
                child: child,
              ),
            );
          },
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
                minWidth: 0,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: .97),
                  border: Border.all(color: color.withValues(alpha: .42)),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .38),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 13, 7),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .14),
                          border:
                              Border.all(color: color.withValues(alpha: .36)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 17),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _colorFor(AppToastType type) => switch (type) {
        AppToastType.success => AppColors.green,
        AppToastType.error => AppColors.red,
        AppToastType.warning => AppColors.orange,
        AppToastType.info => AppColors.blue,
      };
}
