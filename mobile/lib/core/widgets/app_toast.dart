import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../constants/app_colors.dart';
import '../motion/app_motion.dart';

enum AppToastType { info, success, error, warning }

/// A button on a toast (Retry, View, Open…). Tapping it runs [onTap] and
/// dismisses the toast.
class ToastAction {
  final String label;
  final VoidCallback onTap;
  const ToastAction(this.label, this.onTap);
}

/// Returned by [AppToast.progress]; turns the loading toast into its result
/// in place instead of showing a second toast.
class AppToastHandle {
  final int _id;
  const AppToastHandle._(this._id);

  void success(String message, {String? detail, ToastAction? action}) =>
      AppToast._resolve(_id, AppToastType.success, message, detail, action);

  void error(String message, {String? detail, ToastAction? action}) =>
      AppToast._resolve(_id, AppToastType.error, message, detail, action);

  void info(String message, {String? detail, ToastAction? action}) =>
      AppToast._resolve(_id, AppToastType.info, message, detail, action);

  void dismiss() => AppToast._stack.leave(_id);
}

/// Short status messages above the nav bar, in the Clean HUD style: a flat
/// panel with an icon tile, a title, an optional detail line and an
/// optional action.
///
/// Several messages stay readable: up to three show at once, the newest at
/// full size at the bottom and older ones shrunk to a single line above it
/// (tap one to open it). A fourth pushes the oldest out; the same message
/// again bumps a ×2 counter instead of stacking. Each toast counts down on
/// its own and can be swiped away.
///
/// Messages are cleaned before they're shown: raw exception text
/// ("DioException [bad response]…", "Exception: …") becomes plain words
/// with a "check your connection" hint, "Failed to open chest" reads
/// "Couldn't open chest", and developer notes are stripped.
class AppToast {
  AppToast._();

  static final _stack = _ToastStack();
  static OverlayEntry? _entry;
  static OverlayState? _overlay;

  static void info(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline_rounded,
    Duration? duration,
    String? detail,
    ToastAction? action,
  }) =>
      show(context, message,
          type: AppToastType.info,
          icon: icon,
          duration: duration,
          detail: detail,
          action: action);

  static void success(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_rounded,
    Duration? duration,
    String? detail,
    ToastAction? action,
  }) =>
      show(context, message,
          type: AppToastType.success,
          icon: icon,
          duration: duration,
          detail: detail,
          action: action);

  static void error(
    BuildContext context,
    String message, {
    IconData icon = Icons.priority_high_rounded,
    Duration? duration,
    String? detail,
    ToastAction? action,
  }) =>
      show(context, message,
          type: AppToastType.error,
          icon: icon,
          duration: duration,
          detail: detail,
          action: action);

  static void warning(
    BuildContext context,
    String message, {
    IconData icon = Icons.warning_amber_rounded,
    Duration? duration,
    String? detail,
    ToastAction? action,
  }) =>
      show(context, message,
          type: AppToastType.warning,
          icon: icon,
          duration: duration,
          detail: detail,
          action: action);

  /// Shows a toast. Without [duration] it stays 3 s (+1 s with a detail
  /// line), errors 5 s, and toasts with an [action] 6 s.
  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    IconData? icon,
    Duration? duration,
    String? detail,
    ToastAction? action,
  }) {
    if (!_attach(context)) return;
    final (title, det) = cleanMessage(message, detail);
    _stack.push(_ToastData(
      type: type,
      title: title,
      detail: det,
      icon: icon ?? _defaultIcon(type),
      action: action,
      duration: duration,
    ));
  }

  /// A loading toast with a spinner and no timeout. Finish it with the
  /// handle's [AppToastHandle.success] / [AppToastHandle.error].
  static AppToastHandle progress(
    BuildContext context,
    String message, {
    IconData icon = Icons.sync_rounded,
  }) {
    if (!_attach(context)) return const AppToastHandle._(-1);
    final (title, det) = cleanMessage(message, null);
    final id = _stack.push(_ToastData(
      type: AppToastType.info,
      title: title,
      detail: det,
      icon: icon,
      progress: true,
    ));
    return AppToastHandle._(id);
  }

  /// Dismisses every toast.
  static void dismiss() => _stack.clear();

  static void _resolve(int id, AppToastType type, String message,
      String? detail, ToastAction? action) {
    final (title, det) = cleanMessage(message, detail);
    _stack.resolve(
      id,
      _ToastData(
        type: type,
        title: title,
        detail: det,
        icon: _defaultIcon(type),
        action: action,
      ),
    );
  }

  /// Makes sure the toast layer sits on [context]'s root overlay.
  static bool _attach(BuildContext context) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return false;
    final entry = _entry;
    // An inserted entry only reports `mounted` after the next frame, so
    // several toasts fired back to back must not treat it as stale.
    if (entry != null && identical(_overlay, overlay) && overlay.mounted) {
      return true;
    }
    if (entry != null && entry.mounted) entry.remove();
    _stack.reset();
    _overlay = overlay;
    final fresh = OverlayEntry(builder: (_) => _ToastLayer(stack: _stack));
    _entry = fresh;
    // Toasts are often fired from listeners mid-frame; inserting then
    // would rebuild the overlay during the build phase.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (overlay.mounted && !fresh.mounted) overlay.insert(fresh);
      });
    } else {
      overlay.insert(fresh);
    }
    return true;
  }

  static IconData _defaultIcon(AppToastType type) => switch (type) {
        AppToastType.success => Icons.check_rounded,
        AppToastType.error => Icons.priority_high_rounded,
        AppToastType.warning => Icons.warning_amber_rounded,
        AppToastType.info => Icons.info_outline_rounded,
      };

  static final _rawError = RegExp(
    r'(DioException|SocketException|HttpException|TimeoutException|'
    r'FormatException|PlatformException|\[bad response\]|\[connection)',
    caseSensitive: false,
  );

  /// Turns a message into a (title, detail) pair a player should see.
  @visibleForTesting
  static (String, String?) cleanMessage(String message, String? detail) {
    var title = message.trim();
    var det = detail?.trim();

    // "Title\nBody" (e.g. push notifications) → title + detail.
    final nl = title.indexOf('\n');
    if (nl > 0) {
      det ??= title.substring(nl + 1).trim();
      title = title.substring(0, nl).trim();
    }

    // Developer notes never reach players.
    title = title
        .replaceAll(
            RegExp(r'\s*\([^)]*check logs[^)]*\)', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'\s*[—–-]+\s*no backend for it\.?', caseSensitive: false),
            '')
        .trim();

    title = title.replaceFirst(RegExp(r'^(Exception|Error):\s*'), '');

    // Raw exceptions: keep the human part before the colon, if any.
    if (_rawError.hasMatch(title)) {
      final colon = title.indexOf(':');
      final lead = colon > 0 ? title.substring(0, colon).trim() : '';
      title = lead.isEmpty || _rawError.hasMatch(lead)
          ? 'Something went wrong'
          : lead;
      det ??= 'Check your connection and try again.';
    } else if (title.startsWith('Failed: ')) {
      title = 'Something went wrong';
      det ??= 'Please try again.';
    }

    if (title.startsWith('Failed to ')) {
      title = "Couldn't ${title.substring('Failed to '.length)}";
    }

    if (det != null && det.isEmpty) det = null;
    return (title, det);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class _ToastData {
  int id = 0;
  AppToastType type;
  String title;
  String? detail;
  IconData icon;
  ToastAction? action;
  Duration? duration;
  bool progress;

  int count = 1;

  /// Bumped when the toast is repeated or resolved, so its countdown
  /// restarts.
  int generation = 0;
  bool leaving = false;
  bool expanded = false;

  _ToastData({
    required this.type,
    required this.title,
    required this.detail,
    required this.icon,
    this.action,
    this.duration,
    this.progress = false,
  });

  /// Null while loading: a progress toast waits for its result.
  Duration? get lifetime {
    if (progress) return null;
    if (duration != null) return duration;
    if (action != null) return const Duration(seconds: 6);
    if (type == AppToastType.error) return const Duration(seconds: 5);
    return Duration(seconds: detail == null ? 3 : 4);
  }

  bool sameMessage(_ToastData o) =>
      !progress &&
      !o.progress &&
      type == o.type &&
      title == o.title &&
      detail == o.detail;
}

class _ToastStack extends ChangeNotifier {
  static const maxVisible = 3;
  final items = <_ToastData>[];
  int _nextId = 1;

  List<_ToastData> get visible => [
        for (final t in items)
          if (!t.leaving) t
      ];

  int push(_ToastData data) {
    for (final t in visible) {
      if (t.sameMessage(data)) {
        t
          ..count += 1
          ..generation += 1;
        notifyListeners();
        return t.id;
      }
    }
    final shown = visible;
    if (shown.length >= maxVisible) shown.first.leaving = true;
    data.id = _nextId++;
    items.add(data);
    notifyListeners();
    return data.id;
  }

  void resolve(int id, _ToastData result) {
    final i = items.indexWhere((t) => t.id == id && !t.leaving);
    if (i < 0) {
      push(result);
      return;
    }
    final t = items[i];
    t
      ..type = result.type
      ..title = result.title
      ..detail = result.detail
      ..icon = result.icon
      ..action = result.action
      ..progress = false
      ..generation += 1;
    notifyListeners();
  }

  void leave(int id) {
    for (final t in items) {
      if (t.id == id && !t.leaving) {
        t.leaving = true;
        notifyListeners();
        return;
      }
    }
  }

  void remove(int id) {
    items.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void expand(int id) {
    for (final t in items) {
      if (t.id == id) t.expanded = true;
    }
    notifyListeners();
  }

  void clear() {
    for (final t in items) {
      t.leaving = true;
    }
    notifyListeners();
  }

  void reset() {
    items.clear();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

const _kPanel = Color(0xFF10161F);
const _kPanelOlder = Color(0xFF0C1118);
const _kIconBg = Color(0xFF0B1017);
const _kBorder = Color(0x2EE6EDF3); // text primary @ 18%

Color _colorFor(AppToastType type) => switch (type) {
      AppToastType.success => AppColors.green,
      AppToastType.error => AppColors.red,
      AppToastType.warning => AppColors.orange,
      AppToastType.info => AppColors.blue,
    };

class _ToastLayer extends StatelessWidget {
  final _ToastStack stack;
  const _ToastLayer({required this.stack});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom +
        86 +
        MediaQuery.viewInsetsOf(context).bottom;
    return Positioned(
      left: 12,
      right: 12,
      bottom: bottom,
      // Overlay entries sit above every page's Material; without one of
      // their own, text falls back to the debug style (yellow underline).
      child: Material(
        type: MaterialType.transparency,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListenableBuilder(
              listenable: stack,
              builder: (context, _) {
                final shown = stack.visible;
                final newest = shown.isEmpty ? null : shown.last;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: AnimatedSwitcher(
                        duration: AppMotion.duration(
                            context, const Duration(milliseconds: 200)),
                        child: shown.length >= 2
                            ? _ClearAll(
                                key: const ValueKey('clear'),
                                count: shown.length,
                                onTap: stack.clear,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    for (final t in stack.items)
                      _ToastTile(
                        key: ValueKey(t.id),
                        data: t,
                        compact: t != newest && !t.expanded,
                        stack: stack,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearAll extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _ClearAll({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xE6080C12),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _kBorder),
          ),
          child: Text(
            'Clear all · $count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastTile extends StatefulWidget {
  final _ToastData data;
  final bool compact;
  final _ToastStack stack;

  const _ToastTile({
    super.key,
    required this.data,
    required this.compact,
    required this.stack,
  });

  @override
  State<_ToastTile> createState() => _ToastTileState();
}

class _ToastTileState extends State<_ToastTile> with TickerProviderStateMixin {
  _ToastData get data => widget.data;

  // Enter (0 → 1) and leave (1 → 0); sizes the tile so the stack reflows
  // smoothly around it.
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 220),
  );
  // Countdown to auto-dismiss, shown as the bar along the bottom.
  late final AnimationController _timer = AnimationController(vsync: this)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.stack.leave(data.id);
    });
  // A small pop when the toast repeats or resolves.
  late final AnimationController _bump = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));
  late int _generation = data.generation;
  // A leaving toast keeps the size it had, instead of growing or shrinking
  // on its way out.
  late bool _compact = widget.compact;

  bool get _isCompact {
    if (!data.leaving) _compact = widget.compact;
    return _compact;
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.isFull(context)) {
      _life.forward();
    } else {
      _life.value = 1;
    }
    _arm();
  }

  void _arm() {
    final life = data.lifetime;
    if (life == null) {
      _timer.stop();
      _timer.value = 0;
      return;
    }
    _timer
      ..duration = life
      ..forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _ToastTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (data.generation != _generation) {
      _generation = data.generation;
      _arm();
      if (AppMotion.isFull(context)) _bump.forward(from: 0);
    }
    if (data.leaving &&
        _life.status != AnimationStatus.reverse &&
        _life.status != AnimationStatus.dismissed) {
      _timer.stop();
      _life.reverse().whenComplete(() {
        if (mounted) widget.stack.remove(data.id);
      });
    }
  }

  @override
  void dispose() {
    _life.dispose();
    _timer.dispose();
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final life = CurvedAnimation(
      parent: _life,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return SizeTransition(
      sizeFactor: life,
      axisAlignment: 1,
      child: FadeTransition(
        opacity: life,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .35), end: Offset.zero)
              .animate(life),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Dismissible(
              key: ValueKey('toast-${data.id}'),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => widget.stack.remove(data.id),
              child: GestureDetector(
                onTap: widget.compact && !data.leaving
                    ? () => widget.stack.expand(data.id)
                    : null,
                child: AnimatedBuilder(
                  animation: _bump,
                  builder: (_, child) {
                    final t = _bump.value;
                    final s = 1 + .04 * (t < .5 ? t * 2 : (1 - t) * 2);
                    return Transform.scale(scale: s, child: child);
                  },
                  child: Semantics(liveRegion: true, child: _card()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card() {
    final color = _colorFor(data.type);
    final compact = _isCompact;
    final motion = AppMotion.duration(
        context, const Duration(milliseconds: 250),
        reduced: Duration.zero);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: compact ? _kPanelOlder : _kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x8C000000), blurRadius: 30, offset: Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            AnimatedPadding(
              duration: motion,
              curve: Curves.easeOutCubic,
              padding: compact
                  ? const EdgeInsets.fromLTRB(8, 6, 8, 8)
                  : const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: motion,
                    curve: Curves.easeOutCubic,
                    width: compact ? 26 : 36,
                    height: compact ? 26 : 36,
                    decoration: BoxDecoration(
                      color: _kIconBg,
                      borderRadius: BorderRadius.circular(compact ? 8 : 10),
                      border: Border.all(color: color.withValues(alpha: .45)),
                    ),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: motion,
                      transitionBuilder: (child, a) => ScaleTransition(
                        scale: CurvedAnimation(
                            parent: a, curve: Curves.easeOutBack),
                        child: child,
                      ),
                      child: data.progress
                          ? SizedBox(
                              key: const ValueKey('spin'),
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: color,
                              ),
                            )
                          : Icon(
                              data.icon,
                              key: ValueKey(data.icon),
                              size: compact ? 14 : 18,
                              color: color,
                            ),
                    ),
                  ),
                  SizedBox(width: compact ? 9 : 11),
                  Expanded(child: _texts(compact)),
                  if (data.action != null) ...[
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () {
                        data.action!.onTap();
                        widget.stack.leave(data.id);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: color,
                        minimumSize: const Size(44, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: TextStyle(
                          fontSize: compact ? 11.5 : 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(data.action!.label),
                    ),
                  ],
                ],
              ),
            ),
            // Time left before it hides itself.
            if (!data.progress)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _timer,
                  builder: (_, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (1 - _timer.value).clamp(0.0, 1.0),
                    child: Container(
                      height: 2,
                      color: color.withValues(alpha: .7),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _texts(bool compact) {
    final color = _colorFor(data.type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                data.title,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: compact ? 12 : 13,
                  fontWeight: compact ? FontWeight.w700 : FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
            if (data.count > 1) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '×${data.count}',
                  style: const TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (!compact && data.detail != null) ...[
          const SizedBox(height: 2),
          Text(
            data.detail!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}
