import 'dart:math' as math;
import 'dart:ui' show PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'game_map_painter.dart';

/// Camera state for the game map.
/// Supports zoom levels from 1.0 (full world) to 18.0 (street-level Europe).
class GameMapCamera {
  LatLng center;
  double zoom;

  GameMapCamera({this.center = const LatLng(50, 10), this.zoom = 4.0});

  /// Pixels per degree at current zoom level.
  /// At zoom 4, Europe (~50° wide) fits in ~768px.
  /// At zoom 1.5, the full world (~360° wide) fits in ~768px.
  double get scale => 15.0 * math.pow(2, zoom - 4);

  /// Calculate visible bounds with margin.
  VisibleBounds getVisibleBounds(double screenWidth, double screenHeight) {
    final s = scale;
    final halfLat = screenHeight / 2 / s;
    final halfLng = screenWidth / 2 / s;
    return VisibleBounds(
      minLat: center.latitude - halfLat,
      maxLat: center.latitude + halfLat,
      minLng: center.longitude - halfLng,
      maxLng: center.longitude + halfLng,
    );
  }
}

/// Visible geographic bounds.
class VisibleBounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const VisibleBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
}

/// Controller for the game map — replaces flutter_map MapController.
class GameMapController {
  GameMapCamera? _camera;

  GameMapCamera get camera => _camera ?? GameMapCamera();

  void attach(GameMapCamera camera) => _camera = camera;

  /// Move camera to a specific center and zoom instantly.
  void move(LatLng center, double zoom) {
    if (_camera != null) {
      _camera!.center = center;
      _camera!.zoom = zoom.clamp(1.2, 18.0);
    }
  }

  /// Smooth zoom toward/away from a point (used for scroll wheel).
  /// [focalPoint] is in screen pixels, [delta] is the zoom change.
  void zoomAtPoint(Offset focalPoint, double delta, Size screenSize) {
    if (_camera == null) return;

    final oldZoom = _camera!.zoom;
    final newZoom = (oldZoom + delta).clamp(1.2, 18.0);

    if (newZoom == oldZoom) return;

    final oldScale = _camera!.scale;
    // Temporarily set new zoom to compute new scale
    _camera!.zoom = newZoom;
    final newScale = _camera!.scale;

    // Adjust center so the point under the cursor stays fixed
    final focalLat = _camera!.center.latitude - (focalPoint.dy - screenSize.height / 2) / oldScale;
    final focalLng = _camera!.center.longitude + (focalPoint.dx - screenSize.width / 2) / oldScale;

    _camera!.center = LatLng(
      focalLat - (focalPoint.dy - screenSize.height / 2) / newScale,
      focalLng + (focalPoint.dx - screenSize.width / 2) / newScale,
    );
  }
}

/// A fully custom interactive map widget.
/// Renders a world map with cities, roads, truck routes, and country shading.
/// Supports pan (drag), zoom (scroll wheel + pinch), and tap on markers.
class GameMap extends StatefulWidget {
  final GameMapController controller;
  final GameMapPainterData painterData;
  final void Function(Offset screenPosition, LatLng latLng)? onMapTap;
  final void Function(String cityId)? onCityTap;
  final void Function(String truckId)? onTruckTap;
  final double minZoom;
  final double maxZoom;

  const GameMap({
    super.key,
    required this.controller,
    required this.painterData,
    this.onMapTap,
    this.onCityTap,
    this.onTruckTap,
    this.minZoom = 1.2,
    this.maxZoom = 18.0,
  });

  @override
  State<GameMap> createState() => _GameMapState();
}

class _GameMapState extends State<GameMap> {
  late GameMapCamera _camera;
  Offset? _dragStart;
  LatLng? _dragCenterStart;
  double? _pinchZoomBase;
  double? _pinchScaleStart;

  @override
  void initState() {
    super.initState();
    _camera = GameMapCamera(
      center: widget.controller.camera.center,
      zoom: widget.controller.camera.zoom,
    );
    widget.controller.attach(_camera);
  }

  @override
  void didUpdateWidget(covariant GameMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      widget.controller.attach(_camera);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (details.pointerCount == 1) {
      _dragStart = details.localFocalPoint;
      _dragCenterStart = _camera.center;
    } else if (details.pointerCount >= 2) {
      _pinchZoomBase = _camera.zoom;
      _pinchScaleStart = 1.0;
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount == 1 && _dragStart != null && _dragCenterStart != null) {
      final dx = details.localFocalPoint.dx - _dragStart!.dx;
      final dy = details.localFocalPoint.dy - _dragStart!.dy;
      final scale = _camera.scale;
      setState(() {
        _camera.center = LatLng(
          _dragCenterStart!.latitude - dy / scale,
          _dragCenterStart!.longitude + dx / scale,
        );
      });
    } else if (details.pointerCount >= 2 && _pinchZoomBase != null && _pinchScaleStart != null) {
      setState(() {
        _camera.zoom = (_pinchZoomBase! * details.scale / _pinchScaleStart!).clamp(
          widget.minZoom,
          widget.maxZoom,
        );
      });
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _dragStart = null;
    _dragCenterStart = null;
    _pinchZoomBase = null;
    _pinchScaleStart = null;
  }

  void _handleTap(TapUpDetails details) {
    final tapPos = details.localPosition;
    final scale = _camera.scale;
    final size = MediaQuery.of(context).size;

    // Check if tapped on a truck marker
    for (final tm in widget.painterData.truckMarkers) {
      final pos = _latLngToScreen(tm.position, size);
      final dist = (tapPos - pos).distance;
      if (dist < 20) {
        widget.onTruckTap?.call(tm.truckId);
        return;
      }
    }

    // Check if tapped on a city marker
    for (final cm in widget.painterData.cityMarkers) {
      final pos = _latLngToScreen(cm.position, size);
      final dist = (tapPos - pos).distance;
      if (dist < 18) {
        widget.onCityTap?.call(cm.cityId);
        return;
      }
    }

    // Tapped on empty map area
    final lat = _camera.center.latitude - (tapPos.dy - size.height / 2) / scale;
    final lng = _camera.center.longitude + (tapPos.dx - size.width / 2) / scale;
    widget.onMapTap?.call(tapPos, LatLng(lat, lng));
  }

  Offset _latLngToScreen(LatLng point, Size size) {
    final s = size;
    final scale = _camera.scale;
    return Offset(
      (point.longitude - _camera.center.longitude) * scale + s.width / 2,
      (_camera.center.latitude - point.latitude) * scale + s.height / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          // Scroll wheel zoom: zoom toward cursor position
          final delta = event.scrollDelta.dy > 0 ? -0.5 : 0.5;
          final oldZoom = _camera.zoom;
          widget.controller.zoomAtPoint(event.localPosition, delta, MediaQuery.of(context).size);
          if (_camera.zoom != oldZoom) {
            setState(() {});
          }
        }
      },
      child: GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onScaleEnd: _handleScaleEnd,
        onTapUp: _handleTap,
        child: ClipRect(
          child: CustomPaint(
            painter: GameMapPainter(
              camera: _camera,
              data: widget.painterData,
              screenSize: MediaQuery.of(context).size,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}
