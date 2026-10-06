import 'package:flutter/widgets.dart';

// Provider logos drawn in code, not loaded from SVG files, so they are there
// on the very first frame (an SVG asset loads asynchronously and pops in).
// Paths are the ones in assets/auth/.

/// Google's four-colour G.
class GoogleGLogo extends StatelessWidget {
  final double size;
  const GoogleGLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _GooglePainter());
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    canvas.drawPath(
      Path()
          ..moveTo(24.000, 9.500)
          ..cubicTo(27.540, 9.500, 30.710, 10.720, 33.210, 13.100)
          ..lineTo(40.060, 6.250)
          ..cubicTo(35.900, 2.380, 30.470, 0.000, 24.000, 0.000)
          ..cubicTo(14.620, 0.000, 6.510, 5.380, 2.560, 13.220)
          ..lineTo(10.540, 19.410)
          ..cubicTo(12.430, 13.720, 17.740, 9.500, 24.000, 9.500)
          ..close(),
      Paint()..color = const Color(0xFFEA4335),
    );
    canvas.drawPath(
      Path()
          ..moveTo(46.980, 24.550)
          ..cubicTo(46.980, 22.980, 46.830, 21.460, 46.600, 20.000)
          ..lineTo(24.000, 20.000)
          ..lineTo(24.000, 29.020)
          ..lineTo(36.940, 29.020)
          ..cubicTo(36.360, 31.980, 34.680, 34.500, 32.160, 36.200)
          ..lineTo(39.890, 42.200)
          ..cubicTo(44.400, 38.020, 46.980, 31.840, 46.980, 24.550)
          ..close(),
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawPath(
      Path()
          ..moveTo(10.530, 28.590)
          ..cubicTo(10.050, 27.140, 9.770, 25.600, 9.770, 24.000)
          ..cubicTo(9.770, 22.400, 10.040, 20.860, 10.530, 19.410)
          ..lineTo(2.550, 13.220)
          ..cubicTo(0.920, 16.460, 0.000, 20.120, 0.000, 24.000)
          ..cubicTo(0.000, 27.880, 0.920, 31.540, 2.560, 34.780)
          ..lineTo(10.530, 28.590)
          ..close(),
      Paint()..color = const Color(0xFFFBBC05),
    );
    canvas.drawPath(
      Path()
          ..moveTo(24.000, 48.000)
          ..cubicTo(30.480, 48.000, 35.930, 45.870, 39.890, 42.190)
          ..lineTo(32.160, 36.190)
          ..cubicTo(30.010, 37.640, 27.240, 38.490, 24.000, 38.490)
          ..cubicTo(17.740, 38.490, 12.430, 34.270, 10.530, 28.580)
          ..lineTo(2.550, 34.770)
          ..cubicTo(6.510, 42.620, 14.620, 48.000, 24.000, 48.000)
          ..close(),
      Paint()..color = const Color(0xFF34A853),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The Apple logo, cropped tight so it centres exactly. A stand-in: swap for
/// Apple's official artwork before release.
class AppleLogo extends StatelessWidget {
  final double height;
  final Color color;
  const AppleLogo({super.key, this.height = 22, this.color = const Color(0xFF000000)});

  static const _viewBox = Rect.fromLTWH(2.24, 1.41, 14.1, 17.35);

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(height * _viewBox.width / _viewBox.height, height),
        painter: _ApplePainter(color),
      );
}

class _ApplePainter extends CustomPainter {
  final Color color;
  const _ApplePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const box = AppleLogo._viewBox;
    canvas.scale(size.width / box.width, size.height / box.height);
    canvas.translate(-box.left, -box.top);
    canvas.drawPath(
      Path()
          ..moveTo(14.050, 10.630)
          ..cubicTo(14.030, 8.420, 15.850, 7.360, 15.930, 7.310)
          ..cubicTo(14.900, 5.810, 13.310, 5.600, 12.750, 5.580)
          ..cubicTo(11.400, 5.440, 10.110, 6.380, 9.420, 6.380)
          ..cubicTo(8.730, 6.380, 7.680, 5.600, 6.550, 5.620)
          ..cubicTo(5.080, 5.640, 3.720, 6.480, 2.960, 7.800)
          ..cubicTo(1.430, 10.460, 2.570, 14.400, 4.060, 16.560)
          ..cubicTo(4.790, 17.620, 5.660, 18.800, 6.790, 18.760)
          ..cubicTo(7.890, 18.720, 8.300, 18.050, 9.630, 18.050)
          ..cubicTo(10.950, 18.050, 11.330, 18.760, 12.490, 18.740)
          ..cubicTo(13.670, 18.720, 14.420, 17.660, 15.140, 16.600)
          ..cubicTo(15.980, 15.380, 16.320, 14.190, 16.340, 14.130)
          ..cubicTo(16.310, 14.120, 14.040, 13.250, 14.020, 10.630)
          ..close()
          ..moveTo(11.870, 4.170)
          ..cubicTo(12.470, 3.440, 12.880, 2.420, 12.770, 1.410)
          ..cubicTo(11.900, 1.450, 10.850, 1.990, 10.230, 2.710)
          ..cubicTo(9.670, 3.360, 9.180, 4.400, 9.310, 5.390)
          ..cubicTo(10.280, 5.470, 11.270, 4.900, 11.870, 4.170)
          ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ApplePainter oldDelegate) =>
      oldDelegate.color != color;
}
