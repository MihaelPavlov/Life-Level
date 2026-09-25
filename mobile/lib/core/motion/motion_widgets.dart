import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_motion.dart';

int? _digitsOf(String s) {
  final d = s.replaceAll(RegExp(r'[^0-9-]'), '');
  return d.isEmpty ? null : int.tryParse(d);
}

/// Changes that arrive right after a widget mounts are initial data
/// loading in (placeholder → real value), not something the player did —
/// those should just appear.
const _settleTime = Duration(milliseconds: 1500);

bool _settled(DateTime mountedAt) =>
    DateTime.now().difference(mountedAt) > _settleTime;

Matrix4 _rotX(double radians) => Matrix4.identity()
  ..setEntry(3, 2, 0.004)
  ..rotateX(radians);

/// Text whose changed characters flip like an airport split-flap board,
/// rightmost first. When old and new both parse as numbers the flipped
/// digits flash [upColor] / [downColor].
class FlapText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color upColor;
  final Color downColor;

  const FlapText(
    this.text, {
    super.key,
    required this.style,
    this.upColor = const Color(0xFFFFA11C),
    this.downColor = const Color(0xFFFF0047),
  });

  @override
  State<FlapText> createState() => _FlapTextState();
}

class _FlapTextState extends State<FlapText>
    with SingleTickerProviderStateMixin {
  final _mountedAt = DateTime.now();
  static const _stagger = 70.0, _out = 120.0, _in = 380.0;

  late final AnimationController _c = AnimationController(vsync: this)
    ..addListener(() => setState(() {}));
  String _old = '';
  Map<int, double> _delayOf = {};
  Color? _tint;

  @override
  void didUpdateWidget(FlapText old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text ||
        !AppMotion.isFull(context) ||
        !_settled(_mountedAt)) {
      return;
    }
    final n = math.max(old.text.length, widget.text.length);
    final a = old.text.padLeft(n), b = widget.text.padLeft(n);
    _old = a;
    _delayOf = {};
    var k = 0;
    for (var i = n - 1; i >= 0; i--) {
      if (a[i] != b[i]) _delayOf[i] = (k++) * _stagger;
    }
    final va = _digitsOf(old.text), vb = _digitsOf(widget.text);
    _tint = (va == null || vb == null || va == vb)
        ? null
        : (vb > va ? widget.upColor : widget.downColor);
    final total = (k - 1) * _stagger + _out + _in;
    _c.duration = Duration(milliseconds: total.round());
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.isAnimating) return Text(widget.text, style: widget.style);
    final ms = _c.value * _c.duration!.inMilliseconds;
    final n = math.max(_old.length, widget.text.length);
    final b = widget.text.padLeft(n);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < n; i++) _cell(i, ms, b),
      ],
    );
  }

  Widget _cell(int i, double ms, String b) {
    final d = _delayOf[i];
    if (d == null) return Text(b[i], style: widget.style);
    final t = ms - d;
    if (t < _out) {
      final p = (t / _out).clamp(0.0, 1.0);
      return Transform(
        alignment: Alignment.center,
        transform: _rotX(-math.pi / 2 * p),
        child: Text(_old[i], style: widget.style),
      );
    }
    final p = ((t - _out) / _in).clamp(0.0, 1.0);
    final e = Curves.easeOut.transform(p);
    final color = _tint == null
        ? widget.style.color
        : Color.lerp(_tint, widget.style.color, (p - .6).clamp(0, .4) / .4);
    return Transform(
      alignment: Alignment.center,
      transform: _rotX(math.pi / 2 * (1 - e)),
      child: Text(b[i], style: widget.style.copyWith(color: color)),
    );
  }
}

/// Swaps [child] with a calendar-page flip whenever [value] changes.
/// Pass [flash] to tint the incoming child briefly.
class FlipSwap extends StatefulWidget {
  final Object value;
  final Widget child;
  final Duration duration;

  const FlipSwap({
    super.key,
    required this.value,
    required this.child,
    this.duration = const Duration(milliseconds: 370),
  });

  @override
  State<FlipSwap> createState() => _FlipSwapState();
}

class _FlipSwapState extends State<FlipSwap>
    with SingleTickerProviderStateMixin {
  final _mountedAt = DateTime.now();
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)
        ..addListener(() => setState(() {}));
  Widget? _old;

  @override
  void didUpdateWidget(FlipSwap old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value ||
        !AppMotion.isFull(context) ||
        !_settled(_mountedAt)) {
      return;
    }
    _old = old.child;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.isAnimating || _old == null) return widget.child;
    final t = _c.value;
    if (t < .4) {
      return Transform(
        alignment: Alignment.center,
        transform: _rotX(-math.pi / 2 * Curves.easeIn.transform(t / .4)),
        child: _old,
      );
    }
    return Transform(
      alignment: Alignment.center,
      transform:
          _rotX(math.pi / 2 * (1 - Curves.easeOut.transform((t - .4) / .6))),
      child: widget.child,
    );
  }
}

/// Shows [text]; when it changes the old value slides up and out while the
/// new one springs up from below, flashing [flashColor] first.
class SlotNumber extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color flashColor;

  const SlotNumber(
    this.text, {
    super.key,
    required this.style,
    this.flashColor = Colors.white,
  });

  @override
  State<SlotNumber> createState() => _SlotNumberState();
}

class _SlotNumberState extends State<SlotNumber>
    with SingleTickerProviderStateMixin {
  final _mountedAt = DateTime.now();
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..addListener(() => setState(() {}));
  String? _old;

  @override
  void didUpdateWidget(SlotNumber old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text ||
        !AppMotion.isFull(context) ||
        !_settled(_mountedAt)) {
      return;
    }
    _old = old.text;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.isAnimating || _old == null) {
      return Text(widget.text, style: widget.style);
    }
    final ms = _c.value * 1200;
    final outP = (ms / 280).clamp(0.0, 1.0);
    final inP =
        const Cubic(.2, .9, .3, 1.3).transform((ms / 320).clamp(0.0, 1.0));
    final colorP = ((ms - 800) / 400).clamp(0.0, 1.0);
    return ClipRect(
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Opacity(opacity: 0, child: Text(widget.text, style: widget.style)),
          if (outP < 1)
            FractionalTranslation(
              translation: Offset(0, -outP),
              child: Opacity(
                  opacity: 1 - outP, child: Text(_old!, style: widget.style)),
            ),
          FractionalTranslation(
            translation: Offset(0, 1 - inP),
            child: Opacity(
              opacity: inP.clamp(0.0, 1.0),
              child: Text(
                widget.text,
                style: widget.style.copyWith(
                  color:
                      Color.lerp(widget.flashColor, widget.style.color, colorP),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A circled check mark that draws itself when [shown] becomes true.
class DrawnCheck extends StatefulWidget {
  final bool shown;
  final double size;
  final Color color;

  const DrawnCheck({
    super.key,
    required this.shown,
    this.size = 20,
    this.color = const Color(0xFF00CA50),
  });

  @override
  State<DrawnCheck> createState() => _DrawnCheckState();
}

class _DrawnCheckState extends State<DrawnCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: widget.shown ? 1 : 0,
  )..addListener(() => setState(() {}));

  @override
  void didUpdateWidget(DrawnCheck old) {
    super.didUpdateWidget(old);
    if (widget.shown == old.shown) return;
    if (!widget.shown) {
      _c.value = 0;
    } else if (AppMotion.isFull(context)) {
      _c.forward(from: 0);
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_c.value == 0) return SizedBox.square(dimension: widget.size);
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _CheckPainter(_c.value, widget.color),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double t;
  final Color color;
  _CheckPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final r = s.width / 2 - 1;
    final c = s.center(Offset.zero);
    final ringT = (t / .6).clamp(0.0, 1.0);
    canvas.drawCircle(
        c, r, Paint()..color = color.withValues(alpha: .24 * ringT));
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * ringT,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color,
    );
    final checkT = ((t - .4) / .6).clamp(0.0, 1.0);
    if (checkT == 0) return;
    final w = s.width;
    final path = Path()
      ..moveTo(w * .31, w * .51)
      ..lineTo(w * .44, w * .64)
      ..lineTo(w * .71, w * .37);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * checkT),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t;
}

/// Types [text] out one character at a time when it first appears.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration perChar;

  const TypewriterText(
    this.text, {
    super.key,
    required this.style,
    this.perChar = const Duration(milliseconds: 40),
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final List<String> _chars = widget.text.characters.toList();
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.perChar * _chars.length,
  )..addListener(() => setState(() {}));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.value > 0) return;
    if (AppMotion.isFull(context)) {
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = (_chars.length * _c.value).ceil();
    return Text(_chars.take(n).join(), style: widget.style);
  }
}

/// Title swap: when [text] changes the old text slides out to the left and
/// fades, then the new text drops in letter by letter.
class NameplateSwap extends StatefulWidget {
  final String text;
  final TextStyle style;

  const NameplateSwap(this.text, {super.key, required this.style});

  @override
  State<NameplateSwap> createState() => _NameplateSwapState();
}

class _NameplateSwapState extends State<NameplateSwap>
    with SingleTickerProviderStateMixin {
  final _mountedAt = DateTime.now();
  static const _outMs = 200.0, _letterMs = 300.0, _stagger = 35.0;
  late final AnimationController _c = AnimationController(vsync: this)
    ..addListener(() => setState(() {}));
  String? _old;

  @override
  void didUpdateWidget(NameplateSwap old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text ||
        !AppMotion.isFull(context) ||
        !_settled(_mountedAt)) {
      return;
    }
    _old = old.text;
    final n = widget.text.characters.length;
    _c.duration = Duration(
        milliseconds: (_outMs + _letterMs + (n - 1) * _stagger).round());
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.isAnimating || _old == null) {
      return Text(widget.text,
          style: widget.style, overflow: TextOverflow.ellipsis);
    }
    final ms = _c.value * _c.duration!.inMilliseconds;
    if (ms < _outMs) {
      final p = Curves.easeIn.transform(ms / _outMs);
      return Opacity(
        opacity: 1 - p,
        child: Transform.translate(
          offset: Offset(-24 * p, 0),
          child: Text(_old!, style: widget.style, maxLines: 1),
        ),
      );
    }
    final chars = widget.text.characters.toList();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chars.length; i++)
          Builder(builder: (_) {
            final p =
                ((ms - _outMs - i * _stagger) / _letterMs).clamp(0.0, 1.0);
            final e = Curves.easeOutBack.transform(p);
            return Opacity(
              opacity: p.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, -12 * (1 - e)),
                child: Transform.rotate(
                  angle: -.2 * (1 - p),
                  child: Text(chars[i], style: widget.style),
                ),
              ),
            );
          }),
      ],
    );
  }
}
