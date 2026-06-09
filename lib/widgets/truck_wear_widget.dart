import 'package:flutter/material.dart';

/// Visual representation of truck wear by part.
/// Each part (tires, cabin, body, engine) has a wear level 0-100.
class TruckWearWidget extends StatelessWidget {
  final int tireCondition;    // 0-100
  final int cabinCondition;   // 0-100
  final int bodyCondition;     // 0-100
  final int engineCondition;   // 0-100
  final double size;

  const TruckWearWidget({
    this.tireCondition = 100,
    this.cabinCondition = 100,
    this.bodyCondition = 100,
    this.engineCondition = 100,
    this.size = 100,
    super.key,
  });

  Color _wearColor(int condition) {
    if (condition >= 70) return const Color(0xFF66BB6A);   // Green — good
    if (condition >= 40) return const Color(0xFFF5C542);   // Yellow — warning
    return const Color(0xFFEF5350);                          // Red — critical
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.65,
      child: CustomPaint(
        size: Size(size, size * 0.65),
        painter: _TruckWearPainter(
          tireColor: _wearColor(tireCondition),
          cabinColor: _wearColor(cabinCondition),
          bodyColor: _wearColor(bodyCondition),
          engineColor: _wearColor(engineCondition),
        ),
      ),
    );
  }
}

class _TruckWearPainter extends CustomPainter {
  final Color tireColor;
  final Color cabinColor;
  final Color bodyColor;
  final Color engineColor;

  _TruckWearPainter({
    required this.tireColor,
    required this.cabinColor,
    required this.bodyColor,
    required this.engineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Truck body (trailer) — right portion
    final bodyPaint = Paint()..color = bodyColor..style = PaintingStyle.fill;
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.42, h * 0.15, w * 0.52, h * 0.55),
      bottomRight: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Cabin — left portion
    final cabinPaint = Paint()..color = cabinColor..style = PaintingStyle.fill;
    final cabinRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.12, h * 0.1, w * 0.3, h * 0.65),
      topLeft: const Radius.circular(6),
      bottomLeft: const Radius.circular(4),
    );
    canvas.drawRRect(cabinRect, cabinPaint);

    // Engine area (front of cabin)
    final enginePaint = Paint()..color = engineColor..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.04, h * 0.2, w * 0.08, h * 0.45),
      enginePaint,
    );

    // Wheels (tires) — 3 pairs
    final tirePaint = Paint()..color = tireColor..style = PaintingStyle.fill;
    // Front wheel
    canvas.drawCircle(Offset(w * 0.18, h * 0.85), w * 0.06, tirePaint);
    // Rear wheel 1
    canvas.drawCircle(Offset(w * 0.55, h * 0.85), w * 0.06, tirePaint);
    // Rear wheel 2
    canvas.drawCircle(Offset(w * 0.72, h * 0.85), w * 0.06, tirePaint);
    // Rear wheel 3
    canvas.drawCircle(Offset(w * 0.87, h * 0.85), w * 0.06, tirePaint);

    // Outlines
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(bodyRect, outlinePaint);
    canvas.drawRRect(cabinRect, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _TruckWearPainter oldDelegate) =>
      oldDelegate.tireColor != tireColor ||
      oldDelegate.cabinColor != cabinColor ||
      oldDelegate.bodyColor != bodyColor ||
      oldDelegate.engineColor != engineColor;
}
