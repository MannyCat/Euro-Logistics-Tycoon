import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A minimal sparkline chart — just the line, no axes or labels.
/// Used in sidebar/HUD to show earning trends at a glance.
class Sparkline extends StatelessWidget {
  final List<double> data;
  final double width;
  final double height;
  final Color color;
  final bool fill;

  const Sparkline({
    required this.data,
    this.width = 80,
    this.height = 24,
    this.color = const Color(0xFF66BB6A),
    this.fill = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return SizedBox(width: width, height: height);
    }

    final minVal = data.reduce(math.min);
    final maxVal = data.reduce(math.max);
    final range = maxVal - minVal;
    final safeRange = range == 0 ? 1.0 : range;

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * width;
      final y = height - ((data[i] - minVal) / safeRange) * height;
      points.add(Offset(x, y));
    }

    return CustomPaint(
      size: Size(width, height),
      painter: _SparklinePainter(points: points, color: color, fill: fill, height: height),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final bool fill;
  final double height;

  _SparklinePainter({required this.points, required this.color, required this.fill, required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    if (fill) {
      final fillPath = Path()
        ..moveTo(points.first.dx, height)
        ..lineTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(points.last.dx, height);
      fillPath.close();

      final fillPaint = Paint()
        ..color = color.withOpacity(0.1)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
