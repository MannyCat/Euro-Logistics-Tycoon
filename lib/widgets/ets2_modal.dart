import 'package:flutter/material.dart';
import '../config/app_icons.dart';
import '../services/sound_manager.dart';
import '../config/world_boundaries.dart';

/// Shared ETS2-style modal dialog wrapper.
/// All modal screens use this as their root widget instead of Scaffold.
class ETS2Modal extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final List<Widget>? actions;

  const ETS2Modal({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 8,
        vertical: isDesktop ? 40 : 20,
      ),
      child: Container(
        width: isDesktop ? 620 : size.width * 0.94,
        height: isDesktop ? 620 : size.height * 0.78,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF444444)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C2C2C),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF444444), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: const Color(0xFFF5C542), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFFD0D0D0),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (actions != null) ...actions!,
                      IconButton(
                        icon: const Icon(AppIcons.close, color: Color(0xFF999999), size: 20),
                        onPressed: () { SoundManager.instance.tap(); Navigator.pop(context); },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: Container(
                    color: const Color(0xFF1A1A1A),
                    child: child,
                  ),
                ),
              ],
            ),
            // Mini-map inset — world outline mini map
            Positioned(
              top: 56,
              right: 8,
              child: Container(
                width: 160,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF333333)),
                  color: const Color(0xFF0D1117),
                ),
                child: CustomPaint(
                  painter: _MiniWorldMapPainter(),
                  size: const Size(160, 90),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini world map painter for the ETS2 modal inset.
/// Draws simplified world continents as filled polygons.
class _MiniWorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark ocean background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0D1117),
    );

    // Equirectangular projection for mini map
    // x = (lng + 180) / 360 * width
    // y = (90 - lat) / 180 * height
    Offset _project(double lat, double lng) {
      return Offset(
        (lng + 180) / 360 * size.width,
        (90 - lat) / 180 * size.height,
      );
    }

    final landPaint = Paint()
      ..color = const Color(0xFF1E2A3A)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF2A3A4A)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw all world landmasses as mini polygons
    for (final poly in WorldBoundaries.allLandmasses) {
      final points = poly.vertices.map((v) => _project(v.latitude, v.longitude)).toList();
      if (points.isEmpty) continue;

      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.close();

      canvas.drawPath(path, landPaint);
      canvas.drawPath(path, borderPaint);
    }

    // Highlight Europe area slightly
    final euPaint = Paint()
      ..color = const Color(0xFF8B9A46).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final euOutline = Paint()
      ..color = const Color(0xFF8B9A46).withOpacity(0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final europePoints = [
      _project(70, -10), _project(70, 40), _project(35, 40),
      _project(35, -10),
    ];
    final euPath = Path()..moveTo(europePoints[0].dx, europePoints[0].dy);
    for (var i = 1; i < europePoints.length; i++) {
      euPath.lineTo(europePoints[i].dx, europePoints[i].dy);
    }
    euPath.close();
    canvas.drawPath(euPath, euPaint);
    canvas.drawPath(euPath, euOutline);
  }

  @override
  bool shouldRepaint(covariant _MiniWorldMapPainter oldDelegate) => false;
}
