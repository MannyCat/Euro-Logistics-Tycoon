import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../config/country_boundaries.dart';
import 'game_map.dart' show GameMapCamera;

/// Data passed to the map painter each frame.
class CityMarkerData {
  final String cityId;
  final LatLng position;
  final bool hasWarehouse;
  final bool hasGarage;
  final bool hasTruck;
  final bool isSelected;
  final String cityName;
  final String countryCode;

  const CityMarkerData({
    required this.cityId,
    required this.position,
    this.hasWarehouse = false,
    this.hasGarage = false,
    this.hasTruck = false,
    this.isSelected = false,
    required this.cityName,
    required this.countryCode,
  });
}

class TruckMarkerData {
  final String truckId;
  final LatLng position;
  final bool isIdle;
  final bool isDistressed;
  final bool isLoading;
  final double heading;

  const TruckMarkerData({
    required this.truckId,
    required this.position,
    this.isIdle = false,
    this.isDistressed = false,
    this.isLoading = false,
    this.heading = 0,
  });
}

class RoadEdge {
  final LatLng from;
  final LatLng to;
  const RoadEdge({required this.from, required this.to});
}

class RouteSegment {
  final List<LatLng> points;
  final bool isTraveled;
  final Color color;
  final Color borderColor;

  const RouteSegment({
    required this.points,
    required this.isTraveled,
    required this.color,
    required this.borderColor,
  });
}

class GameMapPainterData {
  final List<CityMarkerData> cityMarkers;
  final List<TruckMarkerData> truckMarkers;
  final List<RoadEdge> roads;
  final List<RouteSegment> routes;
  final Set<String> countryNames; // unique country names from cities

  const GameMapPainterData({
    this.cityMarkers = const [],
    this.truckMarkers = const [],
    this.roads = const [],
    this.routes = const [],
    this.countryNames = const {},
  });
}

class GameMapPainter extends CustomPainter {
  final GameMapCamera camera;
  final GameMapPainterData data;
  final Size screenSize;

  GameMapPainter({
    required this.camera,
    required this.data,
    required this.screenSize,
  });

  double get scale => camera.scale;

  /// Convert LatLng to screen pixel offset.
  Offset _toScreen(LatLng point) {
    return Offset(
      (point.longitude - camera.center.longitude) * scale + screenSize.width / 2,
      (camera.center.latitude - point.latitude) * scale + screenSize.height / 2,
    );
  }

  /// Check if a screen point is visible (with margin).
  bool _isVisible(Offset p, {double margin = 100}) {
    return p.dx > -margin && p.dx < screenSize.width + margin &&
           p.dy > -margin && p.dy < screenSize.height + margin;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A1A),
    );

    // 2. Country shading polygons
    _drawCountryShading(canvas);

    // 3. Road network
    _drawRoads(canvas);

    // 4. Truck routes
    _drawRoutes(canvas);

    // 5. City markers
    _drawCities(canvas);

    // 6. Truck markers
    _drawTrucks(canvas);

    // 7. City labels
    _drawCityLabels(canvas);
  }

  void _drawCountryShading(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final countryName in data.countryNames) {
      final verts = CountryBoundaries.polygonFor(countryName);
      final color = CountryBoundaries.colorFor(countryName);
      if (verts == null || color == null) continue;

      final screenVerts = verts.map(_toScreen).toList();
      if (screenVerts.every((p) => !_isVisible(p, margin: 200))) continue;

      final path = Path()..moveTo(screenVerts.first.dx, screenVerts.first.dy);
      for (var i = 1; i < screenVerts.length; i++) {
        path.lineTo(screenVerts[i].dx, screenVerts[i].dy);
      }
      path.close();

      paint.color = color.withOpacity(0.35);
      canvas.drawPath(path, paint);

      borderPaint.color = color.withOpacity(0.5);
      canvas.drawPath(path, borderPaint);
    }
  }

  void _drawRoads(Canvas canvas) {
    final borderPaint = Paint()
      ..color = const Color(0xFF37474F).withOpacity(0.5)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roadPaint = Paint()
      ..color = const Color(0xFF8B9A46).withOpacity(0.55)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final road in data.roads) {
      final from = _toScreen(road.from);
      final to = _toScreen(road.to);
      if (!_isVisible(from) && !_isVisible(to)) continue;

      canvas.drawLine(from, to, borderPaint);
      canvas.drawLine(from, to, roadPaint);
    }
  }

  void _drawRoutes(Canvas canvas) {
    for (final route in data.routes) {
      if (route.points.length < 2) continue;

      final screenPoints = route.points.map(_toScreen).toList();

      // Border
      final borderPaint = Paint()
        ..color = route.borderColor
        ..strokeWidth = route.isTraveled ? 2.0 : 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Main line
      final linePaint = Paint()
        ..color = route.color
        ..strokeWidth = route.isTraveled ? 4.5 : 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path()..moveTo(screenPoints.first.dx, screenPoints.first.dy);
      for (var i = 1; i < screenPoints.length; i++) {
        path.lineTo(screenPoints[i].dx, screenPoints[i].dy);
      }

      canvas.drawPath(path, borderPaint);
      canvas.drawPath(path, linePaint);
    }
  }

  void _drawCities(Canvas canvas) {
    for (final city in data.cityMarkers) {
      final pos = _toScreen(city.position);
      if (!_isVisible(pos)) continue;

      final dotColor = city.hasWarehouse
          ? const Color(0xFF66BB6A)
          : city.hasGarage
              ? const Color(0xFFFF9800)
              : city.hasTruck
                  ? const Color(0xFFF5C542)
                  : const Color(0xFF8B9A46);

      final dotRadius = city.isSelected ? 8.0 : 6.0;

      // Glow effect
      final glowPaint = Paint()
        ..color = dotColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pos, dotRadius + 4, glowPaint);

      // White border
      canvas.drawCircle(pos, dotRadius,
          Paint()..color = Colors.white.withOpacity(0.7)..style = PaintingStyle.stroke..strokeWidth = 1.2);

      // Main dot
      canvas.drawCircle(pos, dotRadius, Paint()..color = dotColor);

      // Selection ring
      if (city.isSelected) {
        canvas.drawCircle(pos, dotRadius + 8,
            Paint()..color = const Color(0xFFF5C542).withOpacity(0.12)..style = PaintingStyle.fill);
        canvas.drawCircle(pos, dotRadius + 8,
            Paint()..color = const Color(0xFFF5C542).withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }

      // Garage badge
      if (city.hasGarage && !city.hasWarehouse) {
        canvas.drawCircle(Offset(pos.dx + 8, pos.dy + 8), 6,
            Paint()..color = const Color(0xFFFF9800)..style = PaintingStyle.fill);
        canvas.drawCircle(Offset(pos.dx + 8, pos.dy + 8), 6,
            Paint()..color = const Color(0xFF1A1A1A)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }
  }

  void _drawTrucks(Canvas canvas) {
    for (final truck in data.truckMarkers) {
      final pos = _toScreen(truck.position);
      if (!_isVisible(pos)) continue;

      final color = truck.isLoading
          ? const Color(0xFF42A5F5)
          : truck.isDistressed
              ? const Color(0xFFEF5350)
              : truck.isIdle
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFF5C542);

      final s = 14.0; // half-size

      // Glow ring for non-idle trucks
      if (!truck.isIdle || truck.isDistressed) {
        canvas.drawCircle(pos, s + 4,
          Paint()..color = color.withOpacity(0.12)..style = PaintingStyle.fill);
        canvas.drawCircle(pos, s + 4,
          Paint()..color = color.withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }

      // Arrow/truck shape rotated by heading
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(truck.heading * math.pi / 180);

      final path = Path()
        ..moveTo(0, -s)              // nose
        ..lineTo(s * 0.35, -s * 0.3)
        ..lineTo(s * 0.5, s * 0.15)  // right mirror
        ..lineTo(s * 0.45, s * 0.6)  // right body
        ..lineTo(s * 0.3, s)         // right tail
        ..lineTo(-s * 0.3, s)        // left tail
        ..lineTo(-s * 0.45, s * 0.6) // left body
        ..lineTo(-s * 0.5, s * 0.15) // left mirror
        ..lineTo(-s * 0.35, -s * 0.3)
        ..close();

      // Shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path.shift(const Offset(1, 2)), shadowPaint);

      // Body
      canvas.drawPath(path, Paint()..color = color);

      // Cabin window line
      canvas.drawLine(
        Offset(-s * 0.25, -s * 0.15),
        Offset(s * 0.25, -s * 0.15),
        Paint()..color = Colors.white.withOpacity(0.3)..strokeWidth = 1.5..style = PaintingStyle.stroke,
      );

      canvas.restore();
    }
  }

  void _drawCityLabels(Canvas canvas) {
    // Only show labels when zoomed in enough
    if (camera.zoom < 4.5) return;

    final textStyle = TextStyle(
      color: const Color(0xFFD0D0D0),
      fontSize: (10 + (camera.zoom - 4.5) * 2).clamp(8.0, 14.0),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );

    for (final city in data.cityMarkers) {
      final pos = _toScreen(city.position);
      if (!_isVisible(pos)) continue;

      final tp = TextPainter(
        text: TextSpan(text: city.cityName, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      // Background pill
      final padding = 4.0;
      final bgRect = Rect.fromLTWH(
        pos.dx - tp.width / 2 - padding - 8, // offset for flag indicator
        pos.dy - tp.height / 2 - padding - 14,  // offset above the dot
        tp.width + padding * 2 + 8,
        tp.height + padding * 2,
      );

      final bgPaint = Paint()..color = const Color(0xFF1A1A1A).withOpacity(0.75);
      final radius = Radius.circular(3);
      canvas.drawRRect(RRect.fromRectAndRadius(bgRect, radius), bgPaint);

      // Country flag indicator — small colored square before name
      final flagPaint = Paint()..color = const Color(0xFF666666)..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bgRect.left + 3, bgRect.top + 3, 10, 7),
          const Radius.circular(1.5),
        ),
        flagPaint,
      );

      // Text
      tp.paint(canvas, Offset(bgRect.left + 16, bgRect.top + padding));
    }
  }

  @override
  bool shouldRepaint(covariant GameMapPainter oldDelegate) => true;
}
