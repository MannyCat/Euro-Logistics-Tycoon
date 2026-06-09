import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom map marker widgets for trucks and cities.
/// Uses top-down truck silhouette rotated in the direction of travel,
/// and styled city pins with country-aware coloring.
class TruckMarker extends StatelessWidget {
  final bool isIdle;
  final bool isDistressed;
  final bool isLoading;
  final double heading; // 0=north, 90=east, 180=south, 270=west
  final double size;
  final VoidCallback? onTap;

  const TruckMarker({
    this.isIdle = false,
    this.isDistressed = false,
    this.isLoading = false,
    this.heading = 0,
    this.size = 28,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (isLoading) {
      color = const Color(0xFF42A5F5);
    } else if (isDistressed) {
      color = const Color(0xFFEF5350);
    } else if (isIdle) {
      color = const Color(0xFF66BB6A);
    } else {
      color = const Color(0xFFF5C542);
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 8,
        height: size + 8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring for transit/distressed trucks
            if (!isIdle || isDistressed)
              Container(
                width: size + 8,
                height: size + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.35), width: 1.5),
                ),
              ),
            // Truck body — diamond/arrow shape pointing in heading direction
            Transform.rotate(
              angle: heading * math.pi / 180,
              child: CustomPaint(
                size: Size(size, size),
                painter: _TruckShapePainter(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a top-down truck silhouette as a diamond/arrow shape.
class _TruckShapePainter extends CustomPainter {
  final Color color;
  _TruckShapePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final s = size.width / 2;

    // Arrow/truck shape: pointed front (top), wide body, narrow back
    final path = Path()
      ..moveTo(center.dx, center.dy - s) // nose
      ..lineTo(center.dx + s * 0.35, center.dy - s * 0.3)
      ..lineTo(center.dx + s * 0.5, center.dy + s * 0.15) // right mirror
      ..lineTo(center.dx + s * 0.45, center.dy + s * 0.6) // right body
      ..lineTo(center.dx + s * 0.3, center.dy + s) // right tail
      ..lineTo(center.dx - s * 0.3, center.dy + s) // left tail
      ..lineTo(center.dx - s * 0.45, center.dy + s * 0.6) // left body
      ..lineTo(center.dx - s * 0.5, center.dy + s * 0.15) // left mirror
      ..lineTo(center.dx - s * 0.35, center.dy - s * 0.3)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path.shift(const Offset(1, 2)), shadowPaint);

    // Body
    canvas.drawPath(path, paint);

    // Cabin window line
    final cabinPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx - s * 0.25, center.dy - s * 0.15),
      Offset(center.dx + s * 0.25, center.dy - s * 0.15),
      cabinPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TruckShapePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Styled city marker with optional badges for warehouse/garage.
class CityMarker extends StatelessWidget {
  final bool hasWarehouse;
  final bool hasGarage;
  final bool hasTruck;
  final bool isSelected;
  final double size;
  final VoidCallback? onTap;

  const CityMarker({
    this.hasWarehouse = false,
    this.hasGarage = false,
    this.hasTruck = false,
    this.isSelected = false,
    this.size = 36,
    this.onTap,
  });

  Color get _dotColor {
    if (hasWarehouse) return const Color(0xFF66BB6A);
    if (hasGarage) return const Color(0xFFFF9800);
    if (hasTruck) return const Color(0xFFF5C542);
    return const Color(0xFF8B9A46);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: isSelected ? size + 12 : size + 4,
        height: isSelected ? size + 12 : size + 4,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Selection ring
            if (isSelected)
              Container(
                width: size + 8,
                height: size + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5C542).withOpacity(0.12),
                  border: Border.all(
                    color: const Color(0xFFF5C542).withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
            // Main dot
            Container(
              width: isSelected ? 16 : 12,
              height: isSelected ? 16 : 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dotColor,
                border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _dotColor.withOpacity(0.5),
                    blurRadius: isSelected ? 12 : 6,
                    spreadRadius: isSelected ? 3 : 1,
                  ),
                ],
              ),
            ),
            // Garage badge
            if (hasGarage && !hasWarehouse)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
