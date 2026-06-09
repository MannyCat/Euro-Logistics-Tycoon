import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../config/world_boundaries.dart';
import '../config/country_boundaries.dart';
import 'game_map.dart' show GameMapCamera, VisibleBounds;

/// Data passed to the map painter each frame.
class CityMarkerData {
  final String cityId;
  final LatLng position;
  final bool hasWarehouse;
  final bool hasGarage;
  final bool hasTruck;
  final bool isSelected;
  final bool hasFerryPort;
  final String cityName;
  final String countryCode;

  const CityMarkerData({
    required this.cityId,
    required this.position,
    this.hasWarehouse = false,
    this.hasGarage = false,
    this.hasTruck = false,
    this.isSelected = false,
    this.hasFerryPort = false,
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

/// Data for a ferry route edge, drawn as dashed cyan lines.
class FerryEdgeData {
  final LatLng from;
  final LatLng to;
  final List<LatLng> waypoints; // curved path across water
  final String name;
  final String seaName;

  const FerryEdgeData({
    required this.from,
    required this.to,
    required this.waypoints,
    required this.name,
    required this.seaName,
  });
}

class GameMapPainterData {
  final List<CityMarkerData> cityMarkers;
  final List<TruckMarkerData> truckMarkers;
  final List<RoadEdge> roads;
  final List<FerryEdgeData> ferryEdges;
  final List<RouteSegment> routes;
  final Set<String> countryNames;

  const GameMapPainterData({
    this.cityMarkers = const [],
    this.truckMarkers = const [],
    this.roads = const [],
    this.ferryEdges = const [],
    this.routes = const [],
    this.countryNames = const {},
  });
}

/// The main map painter — renders a full world map with zoom-dependent detail.
///
/// Rendering layers (in order):
///   1. Ocean background (dark blue-black)
///   2. Latitude / longitude grid (zoom ≤ 2.5)
///   3. World continent / country polygons
///   4. Country shading polygons (game countries, zoom ≥ 3.5)
///   5. Water bodies (seas, zoom ≥ 3)
///   6. Road network (zoom ≥ 4)
///   7. Truck routes (all zoom levels, only if trucks exist)
///   8. City markers (game cities)
///   9. Truck markers (all zoom levels)
///  10. World city dots (zoom ≥ 3, non-game cities)
///  11. World city labels (zoom ≥ 4.5)
///  12. Region labels (zoom ≤ 2.5)
///  13. City labels (game cities, zoom ≥ 4.5)
///  14. Zoom indicator + coordinates display
class GameMapPainter extends CustomPainter {
  final GameMapCamera camera;
  final GameMapPainterData data;
  final Size screenSize;

  // Cached data to avoid recomputing every frame
  List<LandmassPolygon>? _visibleLandmasses;
  List<WorldCity>? _visibleWorldCities;
  VisibleBounds? _bounds;
  double? _lastZoom;

  GameMapPainter({
    required this.camera,
    required this.data,
    required this.screenSize,
  });

  double get scale => camera.scale;
  double get zoom => camera.zoom;

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

  /// Get or compute visible geographic bounds.
  VisibleBounds _getBounds() {
    return camera.getVisibleBounds(screenSize.width, screenSize.height);
  }

  /// Cache visible landmass and world city lookups.
  void _ensureCached() {
    if (_lastZoom == zoom) return;
    _lastZoom = zoom;
    _bounds = _getBounds();
    final b = _bounds!;
    _visibleLandmasses = WorldBoundaries.getVisibleLandmasses(
      minLat: b.minLat, maxLat: b.maxLat,
      minLng: b.minLng, maxLng: b.maxLng,
    );
    _visibleWorldCities = WorldBoundaries.getVisibleWorldCities(
      minLat: b.minLat, maxLat: b.maxLat,
      minLng: b.minLng, maxLng: b.maxLng,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _ensureCached();

    // 1. Ocean background
    _drawOcean(canvas, size);

    // 2. Lat/lng grid
    _drawGrid(canvas, size);

    // 3. World continent polygons
    _drawContinents(canvas);

    // 4. Game country shading (higher detail for known countries)
    if (zoom >= 3.5) {
      _drawCountryShading(canvas);
    }

    // 5. Water bodies
    if (zoom >= 3.0) {
      _drawWaterBodies(canvas);
    }

    // 6. Road network (only visible when zoomed into Europe)
    if (zoom >= 4.0) {
      _drawRoads(canvas);
      // 6b. Ferry routes (drawn on top of roads, dashed cyan)
      _drawFerryRoutes(canvas);
    }

    // 7. Truck routes
    if (data.routes.isNotEmpty) {
      _drawRoutes(canvas);
    }

    // 8. Game city markers
    _drawCities(canvas);

    // 9. Truck markers
    if (data.truckMarkers.isNotEmpty) {
      _drawTrucks(canvas);
    }

    // 10. World city dots (non-game cities)
    if (zoom >= 3.0) {
      _drawWorldCityDots(canvas);
    }

    // 11. World city labels
    if (zoom >= 4.5) {
      _drawWorldCityLabels(canvas);
    }

    // 12. Region labels (very low zoom)
    if (zoom <= 2.5) {
      _drawRegionLabels(canvas);
    }

    // 13. Game city labels
    if (zoom >= 4.5) {
      _drawCityLabels(canvas);
    }

    // 14. Coordinates + zoom indicator
    _drawCoordinates(canvas);
  }

  // ══════════════════════════════════════════════════════════════════════
  // LAYER IMPLEMENTATIONS
  // ══════════════════════════════════════════════════════════════════════

  void _drawOcean(Canvas canvas, Size size) {
    // Dark ocean background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0D1117),
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    // Show grid at zoom ≤ 5, with adaptive spacing
    double gridSpacing;
    if (zoom <= 1.5) {
      gridSpacing = 30.0; // Every 30°
    } else if (zoom <= 2.5) {
      gridSpacing = 15.0; // Every 15°
    } else if (zoom <= 4.0) {
      gridSpacing = 5.0; // Every 5°
    } else {
      return; // No grid at higher zooms
    }

    final gridPaint = Paint()
      ..color = const Color(0xFF1A2030)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final b = _bounds!;

    // Longitude lines (vertical)
    final startLng = (b.minLng / gridSpacing).floor() * gridSpacing;
    for (var lng = startLng; lng <= b.maxLng + gridSpacing; lng += gridSpacing) {
      final top = _toScreen(LatLng(b.maxLat + 5, lng));
      final bottom = _toScreen(LatLng(b.minLat - 5, lng));
      canvas.drawLine(top, bottom, gridPaint);
    }

    // Latitude lines (horizontal)
    final startLat = (b.minLat / gridSpacing).floor() * gridSpacing;
    for (var lat = startLat; lat <= b.maxLat + gridSpacing; lat += gridSpacing) {
      final left = _toScreen(LatLng(lat, b.minLng - 5));
      final right = _toScreen(LatLng(lat, b.maxLng + 5));
      canvas.drawLine(left, right, gridPaint);
    }

    // Draw equator slightly brighter
    if (b.minLat <= 0 && b.maxLat >= 0) {
      final equatorPaint = Paint()
        ..color = const Color(0xFF253040)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      final left = _toScreen(const LatLng(0, -180));
      final right = _toScreen(const LatLng(0, 180));
      canvas.drawLine(left, right, equatorPaint);
    }

    // Prime meridian
    if (b.minLng <= 0 && b.maxLng >= 0) {
      final meridianPaint = Paint()
        ..color = const Color(0xFF253040)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      final top = _toScreen(const LatLng(85, 0));
      final bottom = _toScreen(const LatLng(-85, 0));
      canvas.drawLine(top, bottom, meridianPaint);
    }
  }

  void _drawContinents(Canvas canvas) {
    final landmasses = _visibleLandmasses!;
    if (landmasses.isEmpty) return;

    for (final poly in landmasses) {
      final screenVerts = poly.vertices.map(_toScreen).toList();

      // Quick visibility check
      bool anyVisible = false;
      for (final p in screenVerts) {
        if (_isVisible(p, margin: 300)) {
          anyVisible = true;
          break;
        }
      }
      if (!anyVisible) continue;

      // Build path
      final path = ui.Path()..moveTo(screenVerts.first.dx, screenVerts.first.dy);
      for (var i = 1; i < screenVerts.length; i++) {
        path.lineTo(screenVerts[i].dx, screenVerts[i].dy);
      }
      path.close();

      // Fill with continent color
      final fillColor = Color(poly.color);
      canvas.drawPath(path, Paint()..color = fillColor);

      // Border stroke — slightly lighter than fill
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.fromARGB(
            fillColor.alpha,
            (fillColor.red + 15).clamp(0, 255),
            (fillColor.green + 10).clamp(0, 255),
            (fillColor.blue + 10).clamp(0, 255),
          )
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawCountryShading(Canvas canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final countryName in data.countryNames) {
      final verts = CountryBoundaries.polygonFor(countryName);
      final color = CountryBoundaries.colorFor(countryName);
      if (verts == null || color == null) continue;

      final screenVerts = verts.map(_toScreen).toList();
      if (screenVerts.every((p) => !_isVisible(p, margin: 200))) continue;

      final path = ui.Path()..moveTo(screenVerts.first.dx, screenVerts.first.dy);
      for (var i = 1; i < screenVerts.length; i++) {
        path.lineTo(screenVerts[i].dx, screenVerts[i].dy);
      }
      path.close();

      paint.color = color.withOpacity(0.5);
      canvas.drawPath(path, paint);

      borderPaint.color = color.withOpacity(0.7);
      canvas.drawPath(path, borderPaint);
    }
  }

  void _drawWaterBodies(Canvas canvas) {
    final waterPaint = Paint()
      ..color = const Color(0xFF0D1117)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF1A2535)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (final body in WorldBoundaries.waterBodies) {
      final screenVerts = body.vertices.map(_toScreen).toList();
      if (screenVerts.every((p) => !_isVisible(p, margin: 200))) continue;

      final path = ui.Path()..moveTo(screenVerts.first.dx, screenVerts.first.dy);
      for (var i = 1; i < screenVerts.length; i++) {
        path.lineTo(screenVerts[i].dx, screenVerts[i].dy);
      }
      path.close();

      canvas.drawPath(path, waterPaint);
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

  /// Draw ferry routes as dashed cyan lines with glow, port anchors, and ship icons.
  void _drawFerryRoutes(Canvas canvas) {
    if (data.ferryEdges.isEmpty) return;

    const ferryColor = Color(0xFF29B6F6);

    for (final ferry in data.ferryEdges) {
      // Build screen-space polyline from waypoints
      final screenPoints = ferry.waypoints.map(_toScreen).toList();
      if (screenPoints.length < 2) continue;

      // Quick visibility check
      bool anyVisible = false;
      for (final p in screenPoints) {
        if (_isVisible(p, margin: 200)) {
          anyVisible = true;
          break;
        }
      }
      if (!anyVisible) continue;

      // Subtle glow along ferry route
      final glowPaint = Paint()
        ..color = ferryColor.withOpacity(0.12)
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final glowPath = ui.Path()..moveTo(screenPoints.first.dx, screenPoints.first.dy);
      for (var i = 1; i < screenPoints.length; i++) {
        glowPath.lineTo(screenPoints[i].dx, screenPoints[i].dy);
      }
      canvas.drawPath(glowPath, glowPaint);

      // Dashed cyan line for ferry
      final dashPaint = Paint()
        ..color = ferryColor.withOpacity(0.7)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      _drawDashedPolyline(canvas, screenPoints, dashPaint);

      // Draw anchor/port indicators at each end
      _drawPortAnchor(canvas, screenPoints.first);
      _drawPortAnchor(canvas, screenPoints.last);

      // Draw small ship icon (▲) at midpoint of the route
      final midIdx = screenPoints.length ~/ 2;
      final mid = screenPoints[midIdx];
      if (_isVisible(mid)) {
        // Small upward-pointing triangle (ship)
        final s = 6.0;
        final shipPath = ui.Path()
          ..moveTo(mid.dx, mid.dy - s)
          ..lineTo(mid.dx + s * 0.6, mid.dy + s * 0.4)
          ..lineTo(mid.dx - s * 0.6, mid.dy + s * 0.4)
          ..close();
        canvas.drawPath(shipPath, Paint()..color = ferryColor.withOpacity(0.8));
        // Small "wake" line below ship
        canvas.drawLine(
          Offset(mid.dx - s * 0.8, mid.dy + s * 0.5),
          Offset(mid.dx + s * 0.8, mid.dy + s * 0.5),
          Paint()..color = ferryColor.withOpacity(0.3)..strokeWidth = 1.5,
        );
      }
    }
  }

  /// Draw a small anchor icon (circle + vertical line) at a ferry port location.
  void _drawPortAnchor(Canvas canvas, Offset pos) {
    const anchorColor = Color(0xFF29B6F6);
    const r = 4.0;
    // Outer circle
    canvas.drawCircle(pos, r, Paint()
      ..color = const Color(0xFF0D1117).withOpacity(0.8)
      ..style = PaintingStyle.fill);
    canvas.drawCircle(pos, r, Paint()
      ..color = anchorColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    // Vertical anchor line inside
    canvas.drawLine(
      Offset(pos.dx, pos.dy - r * 0.6),
      Offset(pos.dx, pos.dy + r * 0.6),
      Paint()..color = anchorColor.withOpacity(0.6)..strokeWidth = 1.2..style = PaintingStyle.stroke,
    );
    // Horizontal bar at top
    canvas.drawLine(
      Offset(pos.dx - r * 0.5, pos.dy - r * 0.4),
      Offset(pos.dx + r * 0.5, pos.dy - r * 0.4),
      Paint()..color = anchorColor.withOpacity(0.6)..strokeWidth = 1.0..style = PaintingStyle.stroke,
    );
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

      final path = ui.Path()..moveTo(screenPoints.first.dx, screenPoints.first.dy);
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

      // Adapt dot size based on zoom
      final dotRadius = city.isSelected
          ? (8.0 + (zoom - 4).clamp(0, 6))
          : (6.0 + (zoom - 4).clamp(0, 4));

      final dotColor = city.hasWarehouse
          ? const Color(0xFF66BB6A)
          : city.hasGarage
              ? const Color(0xFFFF9800)
              : city.hasTruck
                  ? const Color(0xFFF5C542)
                  : const Color(0xFF8B9A46);

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

      // Ferry port badge (small cyan circle)
      if (city.hasFerryPort && !city.hasGarage) {
        canvas.drawCircle(Offset(pos.dx + 8, pos.dy + 8), 5,
            Paint()..color = const Color(0xFF29B6F6)..style = PaintingStyle.fill);
        canvas.drawCircle(Offset(pos.dx + 8, pos.dy + 8), 5,
            Paint()..color = const Color(0xFF1A1A1A)..style = PaintingStyle.stroke..strokeWidth = 1.2);
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

      final s = 14.0;

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

      final path = ui.Path()
        ..moveTo(0, -s)
        ..lineTo(s * 0.35, -s * 0.3)
        ..lineTo(s * 0.5, s * 0.15)
        ..lineTo(s * 0.45, s * 0.6)
        ..lineTo(s * 0.3, s)
        ..lineTo(-s * 0.3, s)
        ..lineTo(-s * 0.45, s * 0.6)
        ..lineTo(-s * 0.5, s * 0.15)
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

  void _drawWorldCityDots(Canvas canvas) {
    final cities = _visibleWorldCities!;
    if (cities.isEmpty) return;

    // Small neutral dots for non-game cities
    final dotPaint = Paint()
      ..color = const Color(0xFF4A5568)
      ..style = PaintingStyle.fill;

    final dotRadius = zoom >= 6.0 ? 3.0 : 2.0;

    for (final city in cities) {
      final pos = _toScreen(LatLng(city.lat, city.lng));
      if (!_isVisible(pos, margin: 50)) continue;

      canvas.drawCircle(pos, dotRadius, dotPaint);

      // Subtle border
      canvas.drawCircle(pos, dotRadius,
        Paint()
          ..color = const Color(0xFF5A6578)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);
    }
  }

  void _drawWorldCityLabels(Canvas canvas) {
    final cities = _visibleWorldCities!;
    if (cities.isEmpty) return;

    final textStyle = TextStyle(
      color: const Color(0xFF7A8599),
      fontSize: (9 + (zoom - 4.5) * 1.5).clamp(8.0, 11.0),
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    );

    for (final city in cities) {
      final pos = _toScreen(LatLng(city.lat, city.lng));
      if (!_isVisible(pos)) continue;

      final tp = TextPainter(
        text: TextSpan(text: city.name, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      // Small background pill
      final padding = 3.0;
      final bgRect = Rect.fromLTWH(
        pos.dx - tp.width / 2 - padding,
        pos.dy + 5, // below the dot
        tp.width + padding * 2,
        tp.height + padding * 2,
      );

      final bgPaint = Paint()..color = const Color(0xFF0D1117).withOpacity(0.7);
      canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(2)), bgPaint);

      // Text
      tp.paint(canvas, Offset(bgRect.left + padding, bgRect.top + padding));
    }
  }

  void _drawRegionLabels(Canvas canvas) {
    final labels = WorldBoundaries.regionLabels;

    final textStyle = TextStyle(
      color: const Color(0xFF3A4558),
      fontSize: (16 + (2.5 - zoom) * 6).clamp(14.0, 28.0),
      fontWeight: FontWeight.w800,
      letterSpacing: 3.0,
    );

    for (final label in labels) {
      if (zoom < label.minZoom || zoom > label.maxZoom) continue;

      final pos = _toScreen(LatLng(label.lat, label.lng));
      if (!_isVisible(pos, margin: 200)) continue;

      final tp = TextPainter(
        text: TextSpan(text: label.name, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(
        pos.dx - tp.width / 2,
        pos.dy - tp.height / 2,
      ));
    }
  }

  void _drawCityLabels(Canvas canvas) {
    final textStyle = TextStyle(
      color: const Color(0xFFD0D0D0),
      fontSize: (10 + (zoom - 4.5) * 2).clamp(8.0, 14.0),
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
        pos.dx - tp.width / 2 - padding - 8,
        pos.dy - tp.height / 2 - padding - 14,
        tp.width + padding * 2 + 8,
        tp.height + padding * 2,
      );

      final bgPaint = Paint()..color = const Color(0xFF0D1117).withOpacity(0.8);
      canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(3)), bgPaint);

      // Country flag indicator
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

  void _drawCoordinates(Canvas canvas) {
    // Bottom-right corner: coordinates + zoom level
    final lat = camera.center.latitude;
    final lng = camera.center.longitude;
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';

    final coordText = '${lat.abs().toStringAsFixed(1)}°$latDir ${lng.abs().toStringAsFixed(1)}°$lngDir  z${zoom.toStringAsFixed(1)}';

    final textStyle = TextStyle(
      color: const Color(0xFF4A5568),
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );

    final tp = TextPainter(
      text: TextSpan(text: coordText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final x = screenSize.width - tp.width - 12;
    final y = screenSize.height - tp.height - 46;

    // Background
    final bgPaint = Paint()..color = const Color(0xFF0D1117).withOpacity(0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 4, y - 2, tp.width + 8, tp.height + 4),
        const Radius.circular(3),
      ),
      bgPaint,
    );

    tp.paint(canvas, Offset(x, y));
  }

  /// Draw a dashed polyline manually (no setPathEffect needed).
  void _drawDashedPolyline(Canvas canvas, List<Offset> points, Paint paint, {double dashLen = 10, double gapLen = 6}) {
    for (var i = 0; i < points.length - 1; i++) {
      final from = points[i];
      final to = points[i + 1];
      final dx = to.dx - from.dx;
      final dy = to.dy - from.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist <= 0) continue;
      final ux = dx / dist;
      final uy = dy / dist;
      double pos = 0;
      while (pos < dist) {
        final segEnd = (pos + dashLen).clamp(0.0, dist);
        canvas.drawLine(
          Offset(from.dx + ux * pos, from.dy + uy * pos),
          Offset(from.dx + ux * segEnd, from.dy + uy * segEnd),
          paint,
        );
        pos += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant GameMapPainter oldDelegate) => true;
}
