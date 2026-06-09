import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'game_map_painter.dart';

/// Camera state for the game map.
class GameMapCamera {
  LatLng center;
  double zoom;

  GameMapCamera({this.center = const LatLng(50, 10), this.zoom = 4.0});

  /// Pixels per degree at current zoom level.
  /// At zoom 4, Europe (~50° wide) should fit in ~768px.
  double get scale => 15.0 * math.pow(2, zoom - 4);
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
      _camera!.zoom = zoom.clamp(3.0, 18.0);
    }
  }
}

/// A fully custom interactive map widget.
/// Renders Europe map with cities, roads, truck routes, and country shading.
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
    this.minZoom = 3.0,
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
      _pinchScaleStart = details.scale;
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
    final size = context.size;

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
    final scale = _camera.scale;
    return Offset(
      (point.longitude - _camera.center.longitude) * scale + size.width / 2,
      (_camera.center.latitude - point.latitude) * scale + size.height / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}
