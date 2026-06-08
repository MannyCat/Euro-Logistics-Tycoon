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

  LatLng? _getTruckPosition(Truck truck, GameProvider game) {
    if (truck.isIdle && truck.currentCityId != null) {
      final city = game.getCityById(truck.currentCityId!);
      if (city != null) return LatLng(city.latitude, city.longitude);
    }
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
    final midLat = (start.latitude + end.latitude) / 2 + (end.longitude - start.longitude) * 0.12 * math.sin(t * math.pi);
    final midLng = (start.longitude + end.longitude) / 2 - (end.latitude - start.latitude) * 0.12 * math.sin(t * math.pi);

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
            if (_isDesktop) Sidebar(onRefresh: _refresh),

            Expanded(
              child: Stack(
                children: [
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
                      // ETS2-style map: Stamen Toner Lite (clean, road-focused)
                      TileLayer(
                        urlTemplate: 'https://tiles.stadiamaps.com/tiles/stamen_toner_lite/{z}/{x}/{y}{r}.png',
                        userAgentPackageName: 'com.elt.logistics',
                        retinaMode: true,
                      ),

                      // Active route polylines (dashed road-style)
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
                            color: const Color(0xFFFF9800),
                            strokeWidth: 3.0,
                            borderColor: const Color(0x55FF9800),
                            borderStrokeWidth: 8.0,
                            pattern: const Pattern.dotted(),
                          );
                        }).toList(),
                      ),

                      // City markers — ETS2-style industrial pins
                      MarkerLayer(
                        markers: game.cities.map((city) {
                          final isSelected = _selectedCityId == city.id;
                          final hasWarehouse = game.myWarehouses.any((w) => w.cityId == city.id);
                          return Marker(
                            point: LatLng(city.latitude, city.longitude),
                            width: isSelected ? 52 : 40,
                            height: isSelected ? 52 : 40,
                            child: GestureDetector(
                              onTap: () => _onCityTap(city),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Glow effect
                                  Container(
                                    width: isSelected ? 44 : 32,
                                    height: isSelected ? 44 : 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color(0xFF2196F3).withOpacity(0.35)
                                          : (hasWarehouse ? const Color(0xFF4CAF50).withOpacity(0.25) : const Color(0xFF78909C).withOpacity(0.2)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? const Color(0xFF2196F3).withOpacity(0.5)
                                              : const Color(0xFF78909C).withOpacity(0.3),
                                          blurRadius: isSelected ? 16 : 10,
                                          spreadRadius: isSelected ? 4 : 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Pin icon
                                  Container(
                                    width: isSelected ? 36 : 26,
                                    height: isSelected ? 36 : 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isSelected
                                            ? [const Color(0xFF42A5F5), const Color(0xFF1565C0)]
                                            : hasWarehouse
                                                ? [const Color(0xFF66BB6A), const Color(0xFF2E7D32)]
                                                : [const Color(0xFF90A4AE), const Color(0xFF546E7A)],
                                      ),
                                      border: Border.all(color: Colors.white, width: isSelected ? 2.5 : 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        hasWarehouse ? Icons.warehouse : Icons.location_city,
                                        size: isSelected ? 16 : 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // City name labels — ETS2 style with background pill
                      MarkerLayer(
                        markers: game.cities.map((city) {
                          return Marker(
                            point: LatLng(city.latitude, city.longitude),
                            width: 100,
                            height: 24,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Transform.translate(
                                offset: const Offset(0, -14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                                  ),
                                  child: Text(
                                    city.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFE0E0E0),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                      shadows: [
                                        Shadow(color: Colors.black, blurRadius: 2),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Truck markers — ETS2 style arrow/directional
                      MarkerLayer(
                        markers: [
                          // Idle trucks
                          ...game.myTrucks.where((t) => t.isIdle).map((truck) {
                            final pos = _getTruckPosition(truck, game);
                            if (pos == null) return const Marker(point: LatLng(0, 0), width: 0, height: 0, child: SizedBox());
                            return Marker(
                              point: pos,
                              width: 32, height: 32,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Transform.translate(
                                  offset: const Offset(0, 6),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.6), blurRadius: 8, spreadRadius: 1),
                                      ],
                                    ),
                                    child: const Icon(Icons.local_shipping, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            );
                          }),
                          // Transit trucks with pulsing effect
                          ...game.myTrucks.where((t) => t.isInTransit).map((truck) {
                            final pos = _getTruckPosition(truck, game);
                            if (pos == null) return const Marker(point: LatLng(0, 0), width: 0, height: 0, child: SizedBox());
                            return Marker(
                              point: pos,
                              width: 40, height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Pulse ring
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFFF9800).withOpacity(0.2),
                                      border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.4)),
                                    ),
                                  ),
                                  // Truck icon
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFFFF9800).withOpacity(0.7), blurRadius: 12, spreadRadius: 2),
                                      ],
                                    ),
                                    child: const Icon(Icons.local_shipping, size: 16, color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),

                  // Top bar — ETS2 dashboard style
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1A2332).withOpacity(0.97),
                            const Color(0xFF0F1923).withOpacity(0.95),
                          ],
                        ),
                        border: const Border(bottom: BorderSide(color: Color(0xFF2A3A4A), width: 1)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(children: [
                        if (!_isDesktop) ...[
                          IconButton(
                            icon: const Icon(Icons.menu, color: Color(0xFF78909C)),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                          const SizedBox(width: 4),
                        ],
                        // Logo
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.local_shipping, color: Color(0xFF2196F3), size: 20),
                        ),
                        const SizedBox(width: 10),
                        // Company name
                        Expanded(
                          child: Text(
                            company?.name ?? '...',
                            style: const TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (company != null) ...[
                          // Money — green euro badge
                          _topBadge(
                            Icons.euro_symbol,
                            company.moneyFormatted,
                            const Color(0xFF4CAF50),
                            const Color(0xFF1B5E20),
                          ),
                          const SizedBox(width: 8),
                          // Level
                          _topBadge(
                            Icons.star,
                            'Lv.${company.level}',
                            const Color(0xFF2196F3),
                            const Color(0xFF0D47A1),
                          ),
                          const SizedBox(width: 8),
                          // XP bar
                          Container(
                            width: 80,
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2332),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF2A3A4A)),
                            ),
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // XP fill
                                FractionallySizedBox(
                                  widthFactor: (company.xp % 1000) / 1000,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2196F3).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                                // Text
                                Center(
                                  child: Text(
                                    '${company.xp % 1000} XP',
                                    style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 9, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 12),
                      ]),
                    ),
                  ),

                  // Map controls — ETS2 style minimal
                  Positioned(
                    top: 64, right: 12,
                    child: Column(children: [
                      _mapBtn(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                      const SizedBox(height: 2),
                      _mapBtn(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                      const SizedBox(height: 2),
                      _mapBtn(Icons.crop_free, () => _mapController.move(const LatLng(50, 10), 4)),
                      const SizedBox(height: 2),
                      _mapBtn(Icons.refresh, _refresh),
                    ]),
                  ),

                  // Bottom bar — ETS2 job market style
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF1A2332).withOpacity(0.97),
                            const Color(0xFF0F1923).withOpacity(0.92),
                          ],
                        ),
                        border: const Border(top: BorderSide(color: Color(0xFF2A3A4A), width: 1)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _bottomStat(
                          '${game.idleTrucks.length}',
                          'Свободных',
                          Icons.check_circle,
                          const Color(0xFF4CAF50),
                        ),
                        _bottomStat(
                          '${game.transitTrucks.length}',
                          'В пути',
                          Icons.local_shipping,
                          const Color(0xFFFF9800),
                        ),
                        _bottomStat(
                          '${game.availableContracts.length}',
                          'Контрактов',
                          Icons.description,
                          const Color(0xFF2196F3),
                        ),
                        _bottomStat(
                          '${game.myDrivers.length}',
                          'Водителей',
                          Icons.person,
                          const Color(0xFF64B5F6),
                        ),
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

  Widget _topBadge(IconData icon, String text, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ]),
    );
  }

  Widget _bottomStat(String val, String label, IconData icon, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 4),
    Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Color(0xFF78909C), fontSize: 11)),
  ]);

  Widget _mapBtn(IconData icon, VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332).withOpacity(0.92),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2A3A4A)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF78909C), size: 18),
      ),
    ),
  );
}
