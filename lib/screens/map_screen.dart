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

/// ETS2-style road network connections between cities (city id pairs).
/// These mirror the approximate highway connections from Euro Truck Simulator 2.
const List<List<int>> _roadNetwork = [
  // UK / Northern France
  [1, 5],   // London – Brussels
  [1, 4],   // London – Amsterdam
  [1, 2],   // London – Paris
  // France / Benelux
  [2, 5],   // Paris – Brussels
  [2, 8],   // Paris – Madrid
  [2, 6],   // Paris – Frankfurt
  [2, 7],   // Paris – Zurich
  // Benelux / Germany
  [4, 5],   // Amsterdam – Brussels
  [4, 3],   // Amsterdam – Berlin
  [5, 6],   // Brussels – Frankfurt
  // Germany / Switzerland
  [6, 3],   // Frankfurt – Berlin
  [6, 7],   // Frankfurt – Zurich
  [6, 12],  // Frankfurt – Prague
  [7, 9],   // Zurich – Rome
  [7, 11],  // Zurich – Vienna
  // Central Europe
  [12, 11], // Prague – Vienna
  [12, 10], // Prague – Warsaw
  [12, 3],  // Prague – Berlin
  [11, 13], // Vienna – Budapest
  [11, 14], // Vienna – Stockholm (long highway)
  [10, 3],  // Warsaw – Berlin
  [10, 13], // Warsaw – Budapest
  // Scandinavia
  [15, 14], // Oslo – Stockholm
  [14, 10], // Stockholm – Warsaw (long highway)
  // Southern Europe
  [8, 9],   // Madrid – Rome (long highway)
  [13, 9],  // Budapest – Rome
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Timer? _refreshTimer;
  Timer? _contractGenTimer;
  Timer? _truckAnimTimer;
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
    _truckAnimTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {}); // Repaint truck positions
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _contractGenTimer?.cancel();
    _truckAnimTimer?.cancel();
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

  /// Build road network polylines between cities (ETS2 highway grid).
  List<Polyline> _buildRoadNetwork(GameProvider game) {
    final roads = <Polyline>[];
    final cityMap = <int, City>{};
    for (final c in game.cities) {
      cityMap[c.id] = c;
    }

    for (final pair in _roadNetwork) {
      final a = cityMap[pair[0]];
      final b = cityMap[pair[1]];
      if (a == null || b == null) continue;

      // Main road: subtle dark gray line (highway)
      roads.add(Polyline(
        points: [LatLng(a.latitude, a.longitude), LatLng(b.latitude, b.longitude)],
        color: const Color(0xFF546E7A).withOpacity(0.35),
        strokeWidth: 2.5,
        borderStrokeWidth: 1.0,
        borderColor: const Color(0xFF37474F).withOpacity(0.3),
      ));
    }
    return roads;
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
                  // ===== FLUTTER MAP =====
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(50, 10),
                      initialZoom: 4,
                      minZoom: 3,
                      maxZoom: 18,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onTap: (_, __) => setState(() => _selectedCityId = null),
                    ),
                    children: [
                      // ETS2-style map tiles: CartoDB Voyager (clean road atlas look, no API key needed)
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        userAgentPackageName: 'com.elt.logistics',
                        retinaMode: true,
                      ),

                      // Road network (ETS2 highway grid)
                      PolylineLayer(polylines: _buildRoadNetwork(game)),

                      // Active truck routes — solid orange/yellow (ETS2 GPS style)
                      PolylineLayer(
                        polylines: game.transitTrucks.map((truck) {
                          final origin = truck.originCityId != null ? game.getCityById(truck.originCityId!) : null;
                          final dest = truck.destinationCityId != null ? game.getCityById(truck.destinationCityId!) : null;
                          if (origin == null || dest == null) return Polyline(points: []);
                          final pos = _getTruckPosition(truck, game);
                          // Completed part of route (origin → truck position)
                          final completedPolyline = Polyline(
                            points: [
                              LatLng(origin.latitude, origin.longitude),
                              pos ?? LatLng(origin.latitude, origin.longitude),
                            ],
                            color: const Color(0xFFFFC107), // Yellow: completed
                            strokeWidth: 4.0,
                            borderStrokeWidth: 2.0,
                            borderColor: const Color(0xFFF57F17).withOpacity(0.6),
                          );
                          // Remaining part of route (truck position → destination)
                          final remainingPolyline = Polyline(
                            points: [
                              pos ?? LatLng(origin.latitude, origin.longitude),
                              LatLng(dest.latitude, dest.longitude),
                            ],
                            color: const Color(0xFF42A5F5).withOpacity(0.6), // Blue: remaining
                            strokeWidth: 3.0,
                            borderStrokeWidth: 1.5,
                            borderColor: const Color(0xFF1565C0).withOpacity(0.3),
                          );
                          return completedPolyline; // We return first, remaining added below
                        }).toList()
                          ..addAll(game.transitTrucks.map((truck) {
                            final origin = truck.originCityId != null ? game.getCityById(truck.originCityId!) : null;
                            final dest = truck.destinationCityId != null ? game.getCityById(truck.destinationCityId!) : null;
                            if (origin == null || dest == null) return Polyline(points: []);
                            final pos = _getTruckPosition(truck, game);
                            return Polyline(
                              points: [
                                pos ?? LatLng(origin.latitude, origin.longitude),
                                LatLng(dest.latitude, dest.longitude),
                              ],
                              color: const Color(0xFF42A5F5).withOpacity(0.6),
                              strokeWidth: 3.0,
                              borderStrokeWidth: 1.5,
                              borderColor: const Color(0xFF1565C0).withOpacity(0.3),
                            );
                          })),
                      ),

                      // City markers — ETS2-style industrial/discovery pins
                      MarkerLayer(
                        markers: game.cities.map((city) {
                          final isSelected = _selectedCityId == city.id;
                          final hasWarehouse = game.myWarehouses.any((w) => w.cityId == city.id);
                          final hasTruck = game.myTrucks.any((t) => t.currentCityId == city.id && t.isIdle);

                          return Marker(
                            point: LatLng(city.latitude, city.longitude),
                            width: isSelected ? 56 : 44,
                            height: isSelected ? 56 : 44,
                            child: GestureDetector(
                              onTap: () => _onCityTap(city),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer glow ring
                                  Container(
                                    width: isSelected ? 50 : 38,
                                    height: isSelected ? 50 : 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: hasTruck
                                          ? const Color(0xFFFF9800).withOpacity(0.2)
                                          : isSelected
                                              ? const Color(0xFF2196F3).withOpacity(0.25)
                                              : const Color(0xFFFFFFFF).withOpacity(0.08),
                                      border: Border.all(
                                        color: hasTruck
                                            ? const Color(0xFFFF9800).withOpacity(0.5)
                                            : isSelected
                                                ? const Color(0xFF2196F3).withOpacity(0.6)
                                                : const Color(0xFFFFFFFF).withOpacity(0.15),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  // Inner pin circle
                                  Container(
                                    width: isSelected ? 32 : 24,
                                    height: isSelected ? 32 : 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: hasWarehouse
                                            ? [const Color(0xFF66BB6A), const Color(0xFF2E7D32)]
                                            : hasTruck
                                                ? [const Color(0xFFFFB74D), const Color(0xFFF57C00)]
                                                : [const Color(0xFFE0E0E0), const Color(0xFF9E9E9E)],
                                      ),
                                      border: Border.all(color: Colors.white, width: isSelected ? 2.5 : 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.5),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        hasWarehouse
                                            ? Icons.warehouse
                                            : hasTruck
                                                ? Icons.local_shipping
                                                : Icons.location_city,
                                        size: isSelected ? 14 : 10,
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

                      // City name labels — ETS2 style: semi-transparent dark pill
                      MarkerLayer(
                        markers: game.cities.map((city) {
                          return Marker(
                            point: LatLng(city.latitude, city.longitude),
                            width: 120,
                            height: 26,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Transform.translate(
                                offset: const Offset(0, -16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF263238).withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFFFFFFF).withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        city.name,
                                        style: const TextStyle(
                                          color: Color(0xFFECEFF1),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        city.country,
                                        style: TextStyle(
                                          color: const Color(0xFF90A4AE).withOpacity(0.8),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Truck markers
                      MarkerLayer(
                        markers: [
                          // Idle trucks — green badge
                          ...game.myTrucks.where((t) => t.isIdle).map((truck) {
                            final pos = _getTruckPosition(truck, game);
                            if (pos == null) return const Marker(point: LatLng(0, 0), width: 0, height: 0, child: SizedBox());
                            return Marker(
                              point: pos,
                              width: 34, height: 34,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Transform.translate(
                                  offset: const Offset(0, 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4CAF50).withOpacity(0.6),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.local_shipping, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            );
                          }),
                          // Transit trucks — orange pulsing badge
                          ...game.myTrucks.where((t) => t.isInTransit).map((truck) {
                            final pos = _getTruckPosition(truck, game);
                            if (pos == null) return const Marker(point: LatLng(0, 0), width: 0, height: 0, child: SizedBox());
                            return Marker(
                              point: pos,
                              width: 44, height: 44,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Pulse ring (ETS2 waypoint marker style)
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFFF9800).withOpacity(0.15),
                                      border: Border.all(
                                        color: const Color(0xFFFF9800).withOpacity(0.4),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  // Truck icon container
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF9800).withOpacity(0.8),
                                          blurRadius: 14,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.local_shipping, size: 18, color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),

                  // ===== TOP BAR — ETS2 dashboard =====
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1A2332).withOpacity(0.98),
                            const Color(0xFF0F1923).withOpacity(0.96),
                          ],
                        ),
                        border: const Border(bottom: BorderSide(color: Color(0xFF2A3A4A), width: 1)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3)),
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
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_shipping, color: Color(0xFF2196F3), size: 22),
                        ),
                        const SizedBox(width: 10),
                        // Company name
                        Expanded(
                          child: Text(
                            company?.name ?? '...',
                            style: const TextStyle(
                              color: Color(0xFFECEFF1),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (company != null) ...[
                          // Money badge
                          _topBadge(
                            Icons.euro_symbol,
                            company.moneyFormatted,
                            const Color(0xFF4CAF50),
                            const Color(0xFF1B5E20),
                          ),
                          const SizedBox(width: 8),
                          // Level badge
                          _topBadge(
                            Icons.star,
                            'Lv.${company.level}',
                            const Color(0xFF2196F3),
                            const Color(0xFF0D47A1),
                          ),
                          const SizedBox(width: 8),
                          // XP progress bar
                          Container(
                            width: 90,
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2332),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFF2A3A4A)),
                            ),
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                FractionallySizedBox(
                                  widthFactor: (company.xp % 1000) / 1000,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2196F3).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    '${company.xp % 1000} XP',
                                    style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 10, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 14),
                      ]),
                    ),
                  ),

                  // ===== MAP CONTROLS — ETS2 minimal =====
                  Positioned(
                    top: 66, right: 12,
                    child: Column(children: [
                      _mapBtn(Icons.add, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                      const SizedBox(height: 3),
                      _mapBtn(Icons.remove, () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                      const SizedBox(height: 3),
                      _mapBtn(Icons.crop_free, () => _mapController.move(const LatLng(50, 10), 4)),
                      const SizedBox(height: 3),
                      _mapBtn(Icons.my_location, () {
                        // Center on first idle truck if available
                        final firstTruck = game.myTrucks.where((t) => t.isIdle).firstOrNull;
                        if (firstTruck != null && firstTruck.currentCityId != null) {
                          final city = game.getCityById(firstTruck.currentCityId!);
                          if (city != null) {
                            _mapController.move(LatLng(city.latitude, city.longitude), 7);
                          }
                        }
                      }),
                      const SizedBox(height: 3),
                      _mapBtn(Icons.refresh, _refresh),
                    ]),
                  ),

                  // ===== BOTTOM BAR — ETS2 job market / quick stats =====
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF1A2332).withOpacity(0.98),
                            const Color(0xFF0F1923).withOpacity(0.93),
                          ],
                        ),
                        border: const Border(top: BorderSide(color: Color(0xFF2A3A4A), width: 1)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, -2)),
                        ],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _bottomStat(
                          '${game.idleTrucks.length}',
                          'Свободных',
                          Icons.check_circle_outline,
                          const Color(0xFF4CAF50),
                        ),
                        _bottomDivider(),
                        _bottomStat(
                          '${game.transitTrucks.length}',
                          'В пути',
                          Icons.local_shipping,
                          const Color(0xFFFF9800),
                        ),
                        _bottomDivider(),
                        _bottomStat(
                          '${game.availableContracts.length}',
                          'Контрактов',
                          Icons.description_outlined,
                          const Color(0xFF2196F3),
                        ),
                        _bottomDivider(),
                        _bottomStat(
                          '${game.myDrivers.length}',
                          'Водителей',
                          Icons.person_outline,
                          const Color(0xFF64B5F6),
                        ),
                      ]),
                    ),
                  ),

                  // ===== MINIMAP / COMPASS (ETS2 style) =====
                  Positioned(
                    bottom: 60, left: 12,
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2A3A4A)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('N', style: TextStyle(color: Color(0xFFEF5350), fontSize: 14, fontWeight: FontWeight.w800)),
                          SizedBox(height: 1),
                          Icon(Icons.navigation, color: Color(0xFF78909C), size: 14),
                        ],
                      ),
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

  // ===== UI HELPER WIDGETS =====

  Widget _topBadge(IconData icon, String text, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor, size: 15),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: iconColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.4,
          ),
        ),
      ]),
    );
  }

  Widget _bottomStat(String val, String label, IconData icon, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 16, color: color),
    const SizedBox(width: 5),
    Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(color: Color(0xFF78909C), fontSize: 11, fontWeight: FontWeight.w500)),
  ]);

  Widget _bottomDivider() => Container(
    width: 1, height: 24,
    decoration: BoxDecoration(
      color: const Color(0xFF2A3A4A),
      borderRadius: BorderRadius.circular(1),
    ),
  );

  Widget _mapBtn(IconData icon, VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332).withOpacity(0.94),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A3A4A)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF90A4AE), size: 19),
      ),
    ),
  );
}
