import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMotionPreference { system, full, reduced, off }

enum AppRouteStyle { standard, fade, fullscreen }

enum AppHaptic { none, selection, light }

class AppMotionTokens {
  AppMotionTokens._();

  static const pressDown = Duration(milliseconds: 80);
  static const pressUp = Duration(milliseconds: 120);
  static const micro = Duration(milliseconds: 210);
  static const sheetEnter = Duration(milliseconds: 280);
  static const sheetExit = Duration(milliseconds: 200);
  static const routeEnter = Duration(milliseconds: 280);
  static const routeExit = Duration(milliseconds: 210);
  static const celebrationEnter = Duration(milliseconds: 300);
  static const celebrationExit = Duration(milliseconds: 210);

  static const enterCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;
}

class AppMotionSettings extends ChangeNotifier {
  static const _preferenceKey = 'app_motion_preference';
  static AppMotionPreference currentPreference = AppMotionPreference.system;

  AppMotionPreference _preference = AppMotionPreference.system;
  AppMotionPreference get preference => _preference;

  AppMotionSettings() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_preferenceKey);
    final value = AppMotionPreference.values.where((e) => e.name == stored);
    if (value.isEmpty || value.first == _preference) return;
    _preference = value.first;
    currentPreference = _preference;
    notifyListeners();
  }

  Future<void> setPreference(AppMotionPreference value) async {
    if (value == _preference) return;
    _preference = value;
    currentPreference = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, value.name);
  }
}

final appMotionSettingsProvider =
    ChangeNotifierProvider<AppMotionSettings>((ref) => AppMotionSettings());

class AppMotionScope extends InheritedNotifier<AppMotionSettings> {
  const AppMotionScope({
    super.key,
    required AppMotionSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppMotionSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppMotionScope>()?.notifier;
}

class AppMotion {
  AppMotion._();

  static AppMotionPreference effectivePreference(BuildContext context) {
    final requested = AppMotionScope.maybeOf(context)?.preference ??
        AppMotionPreference.system;
    final media = MediaQuery.maybeOf(context);
    final systemReduced =
        media?.disableAnimations == true || media?.accessibleNavigation == true;

    if (requested == AppMotionPreference.off) return AppMotionPreference.off;
    if (systemReduced) return AppMotionPreference.reduced;
    return requested == AppMotionPreference.system
        ? AppMotionPreference.full
        : requested;
  }

  static bool isFull(BuildContext context) =>
      effectivePreference(context) == AppMotionPreference.full;

  static bool allowsDecorativeMotion(BuildContext context) => isFull(context);

  static Duration duration(BuildContext context, Duration normal,
      {Duration reduced = const Duration(milliseconds: 100)}) {
    return switch (effectivePreference(context)) {
      AppMotionPreference.off => Duration.zero,
      AppMotionPreference.reduced => reduced,
      _ => normal,
    };
  }

  static AnimationStyle animationStyle(
    BuildContext context, {
    Duration enter = AppMotionTokens.sheetEnter,
    Duration exit = AppMotionTokens.sheetExit,
  }) {
    if (effectivePreference(context) == AppMotionPreference.off) {
      return AnimationStyle.noAnimation;
    }
    return AnimationStyle(
      duration: duration(context, enter),
      reverseDuration: duration(context, exit),
      curve: AppMotionTokens.enterCurve,
      reverseCurve: AppMotionTokens.exitCurve,
    );
  }

  static Future<void> haptic(AppHaptic haptic) async {
    if (kIsWeb || haptic == AppHaptic.none) return;
    switch (haptic) {
      case AppHaptic.selection:
        await HapticFeedback.selectionClick();
      case AppHaptic.light:
        await HapticFeedback.lightImpact();
      case AppHaptic.none:
        return;
    }
  }
}

class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final preference = AppMotion.effectivePreference(context);
    if (preference == AppMotionPreference.off) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotionTokens.enterCurve,
      reverseCurve: AppMotionTokens.exitCurve,
    );
    final fade = FadeTransition(opacity: curved, child: child);
    if (preference == AppMotionPreference.reduced) return fade;

    final begin =
        route.fullscreenDialog ? const Offset(0, .12) : const Offset(.10, 0);
    return SlideTransition(
      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
      child: fade,
    );
  }
}

class AppRoute<T> extends PageRouteBuilder<T> {
  AppRoute({
    required WidgetBuilder builder,
    AppRouteStyle style = AppRouteStyle.standard,
    super.settings,
    super.fullscreenDialog = false,
  }) : super(
          transitionDuration:
              AppMotionSettings.currentPreference == AppMotionPreference.off
                  ? Duration.zero
                  : AppMotionSettings.currentPreference ==
                          AppMotionPreference.reduced
                      ? const Duration(milliseconds: 100)
                      : AppMotionTokens.routeEnter,
          reverseTransitionDuration:
              AppMotionSettings.currentPreference == AppMotionPreference.off
                  ? Duration.zero
                  : AppMotionSettings.currentPreference ==
                          AppMotionPreference.reduced
                      ? const Duration(milliseconds: 100)
                      : AppMotionTokens.routeExit,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final preference = AppMotion.effectivePreference(context);
            if (preference == AppMotionPreference.off) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: AppMotionTokens.enterCurve,
              reverseCurve: AppMotionTokens.exitCurve,
            );
            final faded = FadeTransition(opacity: curved, child: child);
            if (style == AppRouteStyle.fade ||
                preference == AppMotionPreference.reduced) {
              return faded;
            }
            final begin = style == AppRouteStyle.fullscreen
                ? const Offset(0, .12)
                : const Offset(.10, 0);
            return SlideTransition(
              position:
                  Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
              child: faded,
            );
          },
        );
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = false,
  bool useRootNavigator = false,
  bool? showDragHandle,
  Color backgroundColor = Colors.transparent,
  Color? barrierColor,
  ShapeBorder? shape,
  RouteSettings? routeSettings,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (sheetContext) => _AppSheetEntrance(
      child: builder(sheetContext),
    ),
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    shape: shape,
    routeSettings: routeSettings,
    sheetAnimationStyle: AppMotion.animationStyle(context),
  );
}

class _AppSheetEntrance extends StatelessWidget {
  final Widget child;

  const _AppSheetEntrance({required this.child});

  @override
  Widget build(BuildContext context) {
    final preference = AppMotion.effectivePreference(context);
    if (preference == AppMotionPreference.off) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.duration(context, AppMotionTokens.sheetEnter),
      curve: AppMotionTokens.enterCurve,
      child: child,
      builder: (context, value, child) {
        final full = preference == AppMotionPreference.full;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, full ? (1 - value) * 22 : 0),
            child: Transform.scale(
              alignment: Alignment.bottomCenter,
              scale: full ? .94 + (.06 * value) : 1,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String barrierLabel = 'Dismiss dialog',
  Color barrierColor = const Color(0xA6000000),
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    transitionDuration: AppMotion.duration(context, AppMotionTokens.sheetEnter),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final preference = AppMotion.effectivePreference(context);
      if (preference == AppMotionPreference.off) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotionTokens.enterCurve,
        reverseCurve: AppMotionTokens.exitCurve,
      );
      final faded = FadeTransition(opacity: curved, child: child);
      if (preference == AppMotionPreference.reduced) return faded;
      return ScaleTransition(
        scale: Tween<double>(begin: .90, end: 1).animate(curved),
        child: faded,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  );
}

Future<T?> showAppCelebration<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String barrierLabel = 'Dismiss reward',
  Color barrierColor = const Color(0xA6000000),
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    transitionDuration:
        AppMotion.duration(context, AppMotionTokens.celebrationEnter),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final preference = AppMotion.effectivePreference(context);
      if (preference == AppMotionPreference.off) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotionTokens.enterCurve,
        reverseCurve: AppMotionTokens.exitCurve,
      );
      final faded = FadeTransition(opacity: curved, child: child);
      if (preference == AppMotionPreference.reduced) return faded;
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .09),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: .88, end: 1).animate(curved),
          child: faded,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) => TickerMode(
      enabled: AppMotion.allowsDecorativeMotion(context),
      child: builder(context),
    ),
  );
}

class AppPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final AppHaptic haptic;
  final HitTestBehavior behavior;
  final double pressedScale;
  final String? semanticLabel;

  const AppPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.haptic = AppHaptic.selection,
    this.behavior = HitTestBehavior.opaque,
    this.pressedScale = .95,
    this.semanticLabel,
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || value == _pressed) return;
    setState(() => _pressed = value);
  }

  void _tap() {
    if (widget.onTap == null) return;
    AppMotion.haptic(widget.haptic);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final animate = AppMotion.isFull(context);
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
        onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
        onTap: widget.onTap == null ? null : _tap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: animate && _pressed ? widget.pressedScale : 1,
          duration:
              _pressed ? AppMotionTokens.pressDown : AppMotionTokens.pressUp,
          curve: AppMotionTokens.enterCurve,
          child: widget.child,
        ),
      ),
    );
  }
}

class AppAnimatedState extends StatelessWidget {
  final Object stateKey;
  final Widget child;

  const AppAnimatedState({
    super.key,
    required this.stateKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotionTokens.micro),
      reverseDuration: AppMotion.duration(context, AppMotionTokens.micro),
      switchInCurve: AppMotionTokens.enterCurve,
      switchOutCurve: AppMotionTokens.exitCurve,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}

/// Keeps every tab mounted while cross-fading only the outgoing and incoming
/// tabs. Hidden tabs have tickers disabled so ambient animations do not spend
/// frame budget in the background.
class AppAnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const AppAnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<AppAnimatedIndexedStack> createState() =>
      _AppAnimatedIndexedStackState();
}

class _AppAnimatedIndexedStackState extends State<AppAnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _previousIndex;
  late int _currentIndex;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: AppMotionTokens.micro,
      value: 1,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _previousIndex = null);
        }
      });
  }

  @override
  void didUpdateWidget(covariant AppAnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == _currentIndex) return;
    _previousIndex = _currentIndex;
    _direction = widget.index > _currentIndex ? 1 : -1;
    _currentIndex = widget.index;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preference = AppMotion.effectivePreference(context);
    _controller.duration = preference == AppMotionPreference.off
        ? Duration.zero
        : AppMotion.duration(context, AppMotionTokens.micro);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotionTokens.enterCurve,
      reverseCurve: AppMotionTokens.exitCurve,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          AnimatedBuilder(
            animation: curved,
            child: TickerMode(
              enabled: i == _currentIndex,
              child: widget.children[i],
            ),
            builder: (context, child) {
              final active = i == _currentIndex;
              final outgoing = i == _previousIndex;
              final opacity = active ? curved.value : 1 - curved.value;
              final translation =
                  active && preference == AppMotionPreference.full
                      ? Offset((1 - curved.value) * .04 * _direction, 0)
                      : Offset.zero;
              return Offstage(
                offstage: !active && !outgoing,
                child: IgnorePointer(
                  ignoring: !active,
                  child: FractionalTranslation(
                    translation: translation,
                    child: Opacity(opacity: opacity, child: child),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
