import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/city.dart';
import '../models/truck.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import 'sidebar.dart';
import 'mobile_drawer.dart';
import 'city_detail_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Timer? _refreshTimer;
  Timer? _contractGenTimer;
  int? _selectedCityId;
  bool _isDesktop = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoad();
      _checkPlatform();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    _contractGenTimer = Timer.periodic(const Duration(minutes: 5), (_) => _generateContracts());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _contractGenTimer?.cancel();
    super.dispose();
  }

  void _checkPlatform() {
    final width = MediaQuery.of(context).size.width;
    setState(() => _isDesktop = width >= 768);
  }

  void _initialLoad() {
    final auth = context.read<AuthProvider>();
    final game = context.read<GameProvider>();
    if (auth.companyId != null && auth.companyId!.isNotEmpty) {
      game.loadAll(auth.companyId!);
    }
  }

  void _refresh() {
    final auth = context.read<AuthProvider>();
    final game = context.read<GameProvider>();
    final companyId = auth.companyId;
    if (companyId == null || companyId.isEmpty) return;
    game.refreshAll(companyId);
  }

  void _generateContracts() {
    final auth = context.read<AuthProvider>();
    final game = context.read<GameProvider>();
    if (auth.companyId == null) return;
    game.generateNewContracts();
  }

  void _onCityTap(City city) {
    setState(() => _selectedCityId = city.id);
    _mapController.move(LatLng(city.latitude, city.longitude), 7);
    showDialog(context: context, builder: (_) => CityDetailDialog(city: city)).then((_) {
      setState(() => _selectedCityId = null);
    });
  }

  /// Calculate interpolated truck position between origin and destination
  LatLng? _getTruckPosition(Truck truck, GameProvider game) {
    // Idle truck: show at current city
    if (truck.isIdle && truck.currentCityId != null) {
      final city = game.getCityById(truck.currentCityId!);
      if (city != null) return LatLng(city.latitude, city.longitude);
    }
    // Transit truck: interpolate between origin and destination
    if ((truck.status == 'in_transit' || truck.status == 'loading') &&
        truck.originCityId != null && truck.destinationCityId != null) {
      final origin = game.getCityById(truck.originCityId!);
      final dest = game.getCityById(truck.destinationCityId!);
      if (origin != null && dest != null) {
        double progress = 0.0;
        if (truck.estimatedArrival != null && truck.departureTime != null) {
          final total = truck.estimatedArrival!.difference(truck.departureTime!).inSeconds;
          if (total > 0) {
            final elapsed = DateTime.now().difference(truck.departureTime!).inSeconds;
            progress = (elapsed / total).clamp(0.0, 1.0);
          }
        }
        return _interpolate(
          LatLng(origin.latitude, origin.longitude),
          LatLng(dest.latitude, dest.longitude),
          progress,
        );
      }
    }
    return null;
  }

  LatLng _interpolate(LatLng start, LatLng end, double t) {
    // Add slight curve for realism
    final midLat = (start.latitude + end.latitude) / 2 + (end.longitude - start.longitude) * 0.15 * math.sin(t * math.pi);
    final midLng = (start.longitude + end.longitude) / 2 - (end.latitude - start.latitude) * 0.15 * math.sin(t * math.pi);

    if (t < 0.5) {
      final localT = t * 2;
      return LatLng(
        start.latitude + (midLat - start.latitude) * localT,
        start.longitude + (midLng - start.longitude) * localT,
      );
    } else {
      final localT = (t - 0.5) * 2;
      return LatLng(
        midLat + (end.latitude - midLat) * localT,
        midLng + (end.longitude - midLng) * localT,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final company = game.company;

    // Show loading while initializing
    if (game.isLoading && !game.isInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 3),
            const SizedBox(height: 16),
            Text('Загрузка...', style: AppTheme.body),
          ]),
        ),
      );
    }

    // Show error state
    if (game.error != null && !game.isInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.red),
            const SizedBox(height: 12),
            Text(game.error!, style: AppTheme.body.copyWith(color: AppTheme.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => game.loadAll(auth.companyId ?? ''),
              child: const Text('Повторить'),
            ),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      drawer: _isDesktop ? null : const MobileDrawer(),
      body: SafeArea(
        child: Row(
          children: [
            // Desktop sidebar
            if (_isDesktop) Sidebar(onRefresh: _refresh),

            // Map area
            Expanded(
              child: Stack(
                children: [
                  // Flutter Map
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(50, 10),
                      initialZoom: 4,
                      minZoom: 3,
                      maxZoom: 18,
                      interactionOptions: InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onTap: (_, __) => setState(() => _selectedCityId = null),
                    ),
                    children: [
                      // Dark map tiles (CartoDB dark_all)
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                        userAgentPackageName: 'com.elt.logistics',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        retinaMode: true,
                      ),

                      // Transit route polylines
                      PolylineLayer(
                        polylines: game.transitTrucks.map((truck) {
                          final origin = truck.originCityId != null ? game.getCityById(truck.originCityId!) : null;
                          final dest = truck.destinationCityId != null ? game.getCityById(truck.destinationCityId!) : null;
                          if (origin == null || dest == null) return Polyline(points: []);
                          final pos = _getTruckPosition(truck, game);
                          if (pos == null) return Polyline(points: []);
                          return Polyline(
                            points: [
                              LatLng(origin.latitude, origin.longitude),
                              pos,
                            ],
                            color: AppTheme.amber.withOpacity(0.7),
                            strokeWidth: 3,
                            borderColor: AppTheme.amber.withOpacity(0.3),
                            borderStrokeWidth: 7,
                          );
                        }).toList(),
                      ),

                      // City markers layer
                      MarkerLayer(
                        markers: game.cities.map((city) {
                          final isSelected = _selectedCityId == city.id;
                          return Marker(
                            point: LatLng(city.latitude, city.longitude),
                            width: isSelected ? 42 : 28,
                            height: isSelected ? 42 : 28,
                            child: GestureDetector(
                              onTap: () => _onCityTap(city),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppTheme.accent : AppTheme.accent.withOpacity(0.8),
                                  border: Border.all(color: Colors.white, width: isSelected ? 2.5 : 1.5),
                                  boxShadow: [
                                    BoxShadow(color: AppTheme.accent.withOpacity(0.4), blurRadius: isSelected ? 12 : 8, spreadRadius: isSelected ? 3 : 1),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(Icons.location_city, size: isSelected ? 18 : 13, color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // City name labels
                      MarkerLayer(
                        markers: game.cities.map((city) {
                          return Marker(
                            point: LatLng(city.latitude, city.longitude),
                            width: 80,
                            height: 20,
                            child: Text(
                              city.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Truck markers layer (transit + idle at cities)
                      MarkerLayer(
                        markers: [
                          // Idle trucks at their cities
                          ...game.myTrucks.where((t) => t.isIdle).map((truck) {
                            final pos = _getTruckPosition(truck, game);
                            if (pos == null) return Marker(point: const LatLng(0, 0), width: 0, height: 0, child: const SizedBox());
                            return Marker(
                              point: pos,
                              width: 28, height: 28,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.green,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [BoxShadow(color: AppTheme.green.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)],
                                ),
                                child: const Center(child: Icon(Icons.local_shipping, size: 13, color: Colors.white)),
                              ),
                            );
                          }),
                          // Transit trucks
                          ...game.myTrucks.where((t) => t.isInTransit).map((truck) {
                            final pos = _getTruckPosition(truck, game);
                            if (pos == null) return Marker(point: const LatLng(0, 0), width: 0, height: 0, child: const SizedBox());
                            return Marker(
                              point: pos,
                              width: 34, height: 34,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.amber,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [BoxShadow(color: AppTheme.amber.withOpacity(0.7), blurRadius: 12, spreadRadius: 2)],
                                ),
                                child: const Center(child: Icon(Icons.local_shipping, size: 16, color: Colors.white)),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),

                  // Top bar with company info
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withOpacity(0.95),
                        border: Border(bottom: BorderSide(color: AppTheme.divider)),
                      ),
                      child: Row(children: [
                        if (!_isDesktop) ...[
                          IconButton(
                            icon: const Icon(Icons.menu, color: AppTheme.textDim),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Icon(Icons.local_shipping, color: AppTheme.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(company?.name ?? '...', style: AppTheme.label, overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        if (company != null) ...[
                          // Money badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.green.withOpacity(0.3))),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.euro, color: AppTheme.green, size: 16),
                              const SizedBox(width: 4),
                              Text(company.moneyFormatted, style: AppTheme.mono.copyWith(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 14)),
                            ]),
                          ),
                          const SizedBox(width: 8),
                          // Level badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.accent.withOpacity(0.3))),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.star, color: AppTheme.accent, size: 14),
                              const SizedBox(width: 4),
                              Text('Lv.${company.level}', style: AppTheme.mono.copyWith(color: AppTheme.accent, fontSize: 13)),
                            ]),
                          ),
                          const SizedBox(width: 8),
                          // Reputation
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.accentLight.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppTheme.accentLight.withOpacity(0.3))),
                            child: Text('Rep.${company.reputation}', style: AppTheme.monoSm.copyWith(color: AppTheme.accentLight)),
                          ),
                        ],
                        const SizedBox(width: 12),
                      ]),
                    ),
                  ),

                  // Zoom controls
                  Positioned(
                    top: 64, right: 12,
                    child: Column(children: [
                      _mapBtn(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                      const SizedBox(height: 4),
                      _mapBtn(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                      const SizedBox(height: 4),
                      _mapBtn(Icons.public, () => _mapController.move(const LatLng(50, 10), 4)),
                      const SizedBox(height: 4),
                      _mapBtn(Icons.refresh, _refresh),
                    ]),
                  ),

                  // Bottom stats bar
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: AppTheme.surface.withOpacity(0.95), border: Border(top: BorderSide(color: AppTheme.divider))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _stat('${game.idleTrucks.length}', 'Свободных', Icons.check_circle, AppTheme.green),
                        _stat('${game.transitTrucks.length}', 'В пути', Icons.local_shipping, AppTheme.amber),
                        _stat('${game.availableContracts.length}', 'Контрактов', Icons.description, AppTheme.accent),
                        _stat('${game.myDrivers.length}', 'Водителей', Icons.person, AppTheme.accentLight),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String val, String label, IconData icon, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 4),
    Text(val, style: AppTheme.mono.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    const SizedBox(width: 3),
    Text(label, style: AppTheme.bodySm),
  ]);

  Widget _mapBtn(IconData icon, VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Icon(icon, color: AppTheme.textDim, size: 18),
      ),
    ),
  );
}
