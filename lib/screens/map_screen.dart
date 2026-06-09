import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'contracts_screen.dart';
import 'fleet_screen.dart';
import 'drivers_screen.dart';
import 'warehouses_screen.dart';
import 'transactions_screen.dart';
import 'settings_screen.dart';
import '../config/game_constants.dart';
import '../utils/pathfinder.dart';
import 'achievements_screen.dart';
import 'leaderboard_screen.dart';
import 'clan_screen.dart';
import 'event_log_screen.dart';
import '../widgets/achievement_toast.dart';

/// ETS2 road network — highway connections between cities (city id pairs).
const List<List<int>> _roadNetwork = [
  [1, 5], [1, 4], [1, 2], [2, 5], [2, 8], [2, 6], [2, 7],
  [4, 5], [4, 3], [5, 6], [6, 3], [6, 7], [6, 12],
  [7, 9], [7, 11], [12, 11], [12, 10], [12, 3], [11, 13],
  [10, 3], [10, 13], [15, 14], [14, 10], [8, 9], [13, 9],
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
  final FocusNode _mapFocus = FocusNode();
  final GlobalKey<AchievementToastOverlayState> _achievementToastKey =
      GlobalKey<AchievementToastOverlayState>();
  Truck? _selectedTruck;

  @override
  void initState() {
    super.initState();
    GameConstants.updateWeather();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoad();
      _checkPlatform();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refresh();
      // Also update weather every 5 minutes
      if (DateTime.now().minute % 5 == 0 && DateTime.now().second < 6) {
        GameConstants.updateWeather();
      }
    });
    _contractGenTimer = Timer.periodic(const Duration(minutes: 5), (_) => _generateContracts());
    _truckAnimTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _mapFocus.requestFocus();
  }
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _contractGenTimer?.cancel();
    _truckAnimTimer?.cancel();
    _mapFocus.dispose();
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
    game.refreshAll(companyId).then((_) {
      // After refresh, check for newly unlocked achievements and show toasts.
      game.checkAchievements(companyId).then((newIds) {
        if (newIds.isNotEmpty) {
          _achievementToastKey.currentState?.enqueue(newIds);
        }
      });
    });
  }

  void _generateContracts() {
    final auth = context.read<AuthProvider>();
    final game = context.read<GameProvider>();
    if (auth.companyId == null) return;
    game.generateNewContracts();
  }

  void _openModal(Widget screen) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => screen,
    );
  }

  void _onCityTap(City city) {
    setState(() {
      _selectedCityId = city.id;
      _selectedTruck = null;
    });
    _mapController.move(LatLng(city.latitude, city.longitude), 7);
    showDialog(context: context, builder: (_) => CityDetailDialog(city: city)).then((_) {
      setState(() => _selectedCityId = null);
    });
  }

  double _calcProgress(Truck truck) {
    if (truck.estimatedArrival != null && truck.departureTime != null) {
      final total = truck.estimatedArrival!.difference(truck.departureTime!).inSeconds;
      if (total > 0) {
        final elapsed = DateTime.now().difference(truck.departureTime!).inSeconds;
        return (elapsed / total).clamp(0.0, 1.0);
      }
    }
    return 0.0;
  }

  LatLng? _getTruckPosition(Truck truck, GameProvider game) {
    if (truck.isIdle && truck.currentCityId != null) {
      final city = game.getCityById(truck.currentCityId!);
      if (city != null) return LatLng(city.latitude, city.longitude);
    }
    if ((truck.status == 'in_transit' || truck.status == 'loading') &&
        truck.originCityId != null && truck.destinationCityId != null) {
      // Use pathfinding for in-transit trucks
      final path = PathFinder.findPath(truck.originCityId!, truck.destinationCityId!);
      if (path.isNotEmpty) {
        final progress = _calcProgress(truck);
        final (lat, lng) = PathFinder.interpolateAlongPath(game.cities, path, progress);
        return LatLng(lat, lng);
      }
      // Fallback: direct line interpolation
      final origin = game.getCityById(truck.originCityId!);
      final dest = game.getCityById(truck.destinationCityId!);
      if (origin != null && dest != null) {
        final progress = _calcProgress(truck);
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
    final midLat = (start.latitude + end.latitude) / 2 +
        (end.longitude - start.longitude) * 0.12 * math.sin(t * math.pi);
    final midLng = (start.longitude + end.longitude) / 2 -
        (end.latitude - start.latitude) * 0.12 * math.sin(t * math.pi);
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

  List<Polyline> _buildRoadNetwork(GameProvider game) {
    final roads = <Polyline>[];
    final cityMap = <int, City>{};
    for (final c in game.cities) { cityMap[c.id] = c; }
    for (final pair in _roadNetwork) {
      final a = cityMap[pair[0]];
      final b = cityMap[pair[1]];
      if (a == null || b == null) continue;
      roads.add(Polyline(
        points: [LatLng(a.latitude, a.longitude), LatLng(b.latitude, b.longitude)],
        color: const Color(0xFF8B9A46).withOpacity(0.55),
        strokeWidth: 2.5,
        borderStrokeWidth: 4.0,
        borderColor: const Color(0xFF37474F).withOpacity(0.5),
      ));
    }
    return roads;
  }

  List<Polyline> _buildTruckRoutes(GameProvider game) {
    final routes = <Polyline>[];
    for (final truck in game.transitTrucks) {
      final origin = truck.originCityId != null ? game.getCityById(truck.originCityId!) : null;
      final dest = truck.destinationCityId != null ? game.getCityById(truck.destinationCityId!) : null;
      if (origin == null || dest == null) continue;

      final path = PathFinder.findPath(truck.originCityId!, truck.destinationCityId!);

      if (path.length < 2) {
        // Fallback: draw direct line
        final pos = _getTruckPosition(truck, game);
        final truckPos = pos ?? LatLng(origin.latitude, origin.longitude);
        routes.add(Polyline(
          points: [LatLng(origin.latitude, origin.longitude), truckPos],
          color: const Color(0xFFF5C542),
          strokeWidth: 4.5,
          borderStrokeWidth: 2.0,
          borderColor: const Color(0xFFD4A017).withOpacity(0.7),
        ));
        routes.add(Polyline(
          points: [truckPos, LatLng(dest.latitude, dest.longitude)],
          color: const Color(0xFFF5C542).withOpacity(0.35),
          strokeWidth: 3.0,
          borderStrokeWidth: 1.5,
          borderColor: const Color(0xFFD4A017).withOpacity(0.25),
        ));
        continue;
      }

      // Build polyline points from path cities
      final pathPoints = path.map((id) {
        final city = game.getCityById(id);
        if (city == null) return null;
        return LatLng(city.latitude, city.longitude);
 }).whereType<LatLng>().toList();

      final progress = _calcProgress(truck);
      final segIdx = PathFinder.findSegmentIndex(game.cities, path, progress);
      final truckPos = _getTruckPosition(truck, game) ?? pathPoints.first;

      // Traveled portion: from start to truck position (bright)
      final traveledPoints = <LatLng>[
        ...pathPoints.take(segIdx),
        truckPos,
      ];
      if (traveledPoints.length >= 2) {
        routes.add(Polyline(
          points: traveledPoints,
          color: const Color(0xFFF5C542),
          strokeWidth: 4.5,
          borderStrokeWidth: 2.0,
          borderColor: const Color(0xFFD4A017).withOpacity(0.7),
        ));
      }

      // Remaining portion: from truck position to end (dim)
      final remainingPoints = <LatLng>[
        truckPos,
        if (segIdx + 1 < pathPoints.length) ...pathPoints.skip(segIdx + 1),
      ];
      if (remainingPoints.length >= 2) {
        routes.add(Polyline(
          points: remainingPoints,
          color: const Color(0xFFF5C542).withOpacity(0.35),
          strokeWidth: 3.0,
          borderStrokeWidth: 1.5,
          borderColor: const Color(0xFFD4A017).withOpacity(0.25),
        ));
      }
    }
    return routes;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final company = game.company;

    // Loading
    if (game.isLoading && !game.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF5C542).withOpacity(0.3), width: 3),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: Color(0xFFF5C542), strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 20),
            Text('Загрузка карты...', style: AppTheme.body.copyWith(color: const Color(0xFF90A4AE), fontSize: 13)),
          ]),
        ),
      );
    }

    // Error
    if (game.error != null && !game.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF5350)),
            const SizedBox(height: 12),
            Text(game.error!, style: AppTheme.body.copyWith(color: const Color(0xFFEF5350))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => game.loadAll(auth.companyId ?? ''),
              child: const Text('Повторить'),
            ),
          ]),
        ),
      );
    }

    // ===== MAIN SCREEN =====
    return Focus(
      focusNode: _mapFocus,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (HardwareKeyboard.instance.isControlPressed) return KeyEventResult.ignored;
        switch (event.logicalKey) {
          case LogicalKeyboardKey.keyC:
            _openModal(const ContractsScreen());
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyF:
            _openModal(const FleetScreen());
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyD:
            _openModal(const DriversScreen());
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyW:
            _openModal(const WarehousesScreen());
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyT:
            _openModal(const TransactionsScreen());
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyH:
            _openModal(const EventLogScreen());
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyL:
            _openModal(const LeaderboardScreen());
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyA:
            _openModal(const AchievementsScreen());
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyG:
            _openModal(const ClanScreen());
            return KeyEventResult.handled;
          case LogicalKeyboardKey.escape:
            Navigator.of(context).popUntil((route) => route is PopupRoute && Navigator.of(context).canPop() ? false : true);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyR:
            _refresh();
            return KeyEventResult.handled;
          default:
            return KeyEventResult.ignored;
        }
      },
      child: AchievementToastOverlay(
        key: _achievementToastKey,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        drawer: _isDesktop ? null : MobileDrawer(onOpenModal: _openModal),
        body: Row(
          children: [
            if (_isDesktop) Sidebar(onRefresh: _refresh, onOpenModal: _openModal),

            // ===== MAP AREA =====
            Expanded(
              child: Stack(
                children: [
                  // Dark background behind map tiles (prevents white flash)
                  Container(
                    color: const Color(0xFF1A1A1A),
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: const LatLng(50, 10),
                        initialZoom: 4,
                        minZoom: 3,
                        maxZoom: 18,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                        onTap: (_, __) => setState(() { _selectedCityId = null; _selectedTruck = null; }),
                      ),
                      children: [
                        // ETS2 dark map tiles
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                          userAgentPackageName: 'com.elt.logistics',
                          retinaMode: true,
                        ),
                        PolylineLayer(polylines: _buildRoadNetwork(game)),
                        PolylineLayer(polylines: _buildTruckRoutes(game)),

                        // City markers
                        MarkerLayer(
                          markers: game.cities.map((city) {
                            final isSelected = _selectedCityId == city.id;
                            final hasWarehouse = game.myWarehouses.any((w) => w.cityId == city.id);
                            final hasGarage = game.hasGarageInCity(city.id);
                            final hasTruck = game.myTrucks.any((t) => t.currentCityId == city.id && t.isIdle);
                            Color dotColor;
                            if (hasWarehouse) {
                              dotColor = const Color(0xFF66BB6A);
                            } else if (hasGarage) {
                              dotColor = const Color(0xFFFF9800);
                            } else if (hasTruck) {
                              dotColor = const Color(0xFFF5C542);
                            } else {
                              dotColor = const Color(0xFF8B9A46);
                            }
                            return Marker(
                              point: LatLng(city.latitude, city.longitude),
                              width: isSelected ? 48 : 36,
                              height: isSelected ? 48 : 36,
                              child: GestureDetector(
                                onTap: () => _onCityTap(city),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isSelected)
                                      Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFF5C542).withOpacity(0.15),
                                          border: Border.all(color: const Color(0xFFF5C542).withOpacity(0.5), width: 2),
                                        ),
                                      ),
                                    Container(
                                      width: isSelected ? 18 : 12,
                                      height: isSelected ? 18 : 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: dotColor,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(color: dotColor.withOpacity(0.6), blurRadius: isSelected ? 12 : 8, spreadRadius: isSelected ? 3 : 1),
                                        ],
                                      ),
                                    ),
                                    // Garage indicator badge
                                    if (hasGarage && !hasWarehouse)
                                      Positioned(
                                        right: 0, bottom: 0,
                                        child: Container(
                                          width: 12, height: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF9800),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
                                          ),
                                          child: const Icon(Icons.garage, size: 7, color: Color(0xFF1A1A1A)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        // City labels
                        MarkerLayer(
                          markers: game.cities.map((city) {
                            return Marker(
                              point: LatLng(city.latitude, city.longitude),
                              width: 110, height: 22,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Transform.translate(
                                  offset: const Offset(0, -12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A).withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      city.name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFD0D0D0),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                        shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))],
                                      ),
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
                            // Idle trucks — green circles
                            ...game.myTrucks.where((t) => t.isIdle).map((truck) {
                              final pos = _getTruckPosition(truck, game);
                              if (pos == null) return const Marker(point: LatLng(0, 0), width: 0, height: 0, child: SizedBox());
                              final isDistressed = truck.fuelLevel < truck.maxFuel * 0.15 || truck.condition < 20;
                              return Marker(
                                point: pos, width: 28, height: 28,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Transform.translate(
                                    offset: const Offset(0, 6),
                                    child: GestureDetector(
                                      onTap: () => setState(() { _selectedTruck = null; _onCityTap(game.getCityById(truck.currentCityId!)!); }),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (isDistressed)
                                            Container(
                                              width: 30, height: 30,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFFEF5350).withOpacity(0.15),
                                                border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.4), width: 1.5),
                                              ),
                                            ),
                                          Container(
                                            width: 20, height: 20,
                                            decoration: BoxDecoration(
                                              color: isDistressed ? const Color(0xFFEF5350) : const Color(0xFF66BB6A),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                              boxShadow: [BoxShadow(color: (isDistressed ? const Color(0xFFEF5350) : const Color(0xFF66BB6A)).withOpacity(0.5), blurRadius: 8, spreadRadius: 1)],
                                            ),
                                            child: const Icon(Icons.local_shipping, size: 10, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            // Loading trucks — blue pulsing
                            ...game.myTrucks.where((t) => t.status == 'loading').map((truck) {
                              final pos = _getTruckPosition(truck, game);
                              if (pos == null) return const Marker(point: LatLng(0, 0), width: 0, height: 0, child: SizedBox());
                              return Marker(
                                point: pos, width: 38, height: 38,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 34, height: 34,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF42A5F5).withOpacity(0.12),
                                        border: Border.all(color: const Color(0xFF42A5F5).withOpacity(0.3), width: 1.5),
                                      ),
                                    ),
                                    Container(
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF42A5F5),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [BoxShadow(color: const Color(0xFF42A5F5).withOpacity(0.6), blurRadius: 10, spreadRadius: 2)],
                                      ),
                                      child: const Icon(Icons.hourglass_top, size: 11, color: Colors.white),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            // In-transit trucks — amber
                            ...game.myTrucks.where((t) => t.status == 'in_transit').map((truck) {
                              final pos = _getTruckPosition(truck, game);
                              if (pos == null) return const Marker(point: LatLng(0, 0), width: 0, height: 0, child: SizedBox());
                              final isDistressed = truck.fuelLevel < truck.maxFuel * 0.15 || truck.condition < 20;
                              return Marker(
                                point: pos, width: 36, height: 36,
                                child: GestureDetector(
                                  onTap: () => setState(() { _selectedCityId = null; _selectedTruck = truck; }),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (isDistressed)
                                        Container(
                                          width: 42, height: 42,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFEF5350).withOpacity(0.12),
                                            border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.35), width: 1.5),
                                          ),
                                        ),
                                      Container(
                                        width: 32, height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: (isDistressed ? const Color(0xFFEF5350) : const Color(0xFFF5C542)).withOpacity(0.15),
                                          border: Border.all(color: (isDistressed ? const Color(0xFFEF5350) : const Color(0xFFF5C542)).withOpacity(0.4), width: 1.5),
                                        ),
                                      ),
                                      Container(
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(
                                          color: isDistressed ? const Color(0xFFEF5350) : const Color(0xFFF5C542),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [BoxShadow(color: (isDistressed ? const Color(0xFFEF5350) : const Color(0xFFF5C542)).withOpacity(0.7), blurRadius: 12, spreadRadius: 2)],
                                        ),
                                        child: const Icon(Icons.local_shipping, size: 11, color: Color(0xFF1A1A1A)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ===== WEATHER OVERLAY =====
                  if (GameConstants.currentWeather != 'clear')
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(color: GameConstants.weatherOverlayColor),
                      ),
                    ),

                  // ===== NIGHT OVERLAY =====
                  if (GameConstants.isNightTime)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(color: Colors.black.withOpacity(0.05)),
                      ),
                    ),

                  // ===== TRUCK INFO POPUP =====
                  if (_selectedTruck != null)
                    Positioned(
                      top: 60, left: _isDesktop ? 250 : 10, right: 10,
                      child: _TruckInfoPopup(
                        truck: _selectedTruck!,
                        game: game,
                        onClose: () => setState(() => _selectedTruck = null),
                      ),
                    ),

                  // ===== TOP BAR — ETS2 Route Advisor =====
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2C2C2C),
                        border: Border(bottom: BorderSide(color: Color(0xFF444444), width: 1)),
                        boxShadow: [BoxShadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: Row(children: [
                        if (!_isDesktop) ...[
                          IconButton(
                            icon: const Icon(Icons.menu, color: Color(0xFF999999)),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                          const SizedBox(width: 2),
                        ],
                        const Icon(Icons.local_shipping, color: Color(0xFFF5C542), size: 20),
                        const SizedBox(width: 6),
                        Icon(GameConstants.weatherIcon, color: GameConstants.weatherColor, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            company?.name ?? '...',
                            style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (company != null) ...[
                          _ets2Badge(company.moneyFormatted, const Color(0xFFF5C542)),
                          const SizedBox(width: 6),
                          _ets2Badge('Lv.${company.level}', const Color(0xFF66BB6A)),
                          if (game.isInClan && game.myClan != null) ...[
                            const SizedBox(width: 6),
                            _ets2Badge('[${game.myClan!.tag}]', const Color(0xFFCE93D8)),
                          ],
                          const SizedBox(width: 6),
                          Container(
                            width: 80, height: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: const Color(0xFF444444), width: 0.5),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                FractionallySizedBox(
                                  widthFactor: (company.xp % GameConstants.xpPerLevel) / GameConstants.xpPerLevel,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5C542).withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Text('${company.xp % GameConstants.xpPerLevel} XP',
                                      style: const TextStyle(color: Color(0xFF999999), fontSize: 9, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 10),
                      ]),
                    ),
                  ),

                  // ===== MAP CONTROLS =====
                  Positioned(
                    top: 58, right: 10,
                    child: Column(children: [
                      _ets2MapBtn(Icons.add, 'Приблизить (+)', () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                      const SizedBox(height: 2),
                      _ets2MapBtn(Icons.remove, 'Отдалить (-)', () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                      const SizedBox(height: 2),
                      _ets2MapBtn(Icons.crop_free, 'Обзор Европы', () => _mapController.move(const LatLng(50, 10), 4)),
                      const SizedBox(height: 2),
                      _ets2MapBtn(Icons.my_location, 'К первому грузовику', () {
                        final firstTruck = game.myTrucks.where((t) => t.isIdle).firstOrNull;
                        if (firstTruck != null && firstTruck.currentCityId != null) {
                          final city = game.getCityById(firstTruck.currentCityId!);
                          if (city != null) _mapController.move(LatLng(city.latitude, city.longitude), 7);
                        }
                      }),
                      const SizedBox(height: 2),
                      _ets2MapBtn(Icons.refresh, 'Обновить (R)', _refresh),
                    ]),
                  ),

                  // ===== BOTTOM BAR — ETS2 Route Advisor =====
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2C2C2C),
                        border: Border(top: BorderSide(color: Color(0xFF444444), width: 1)),
                        boxShadow: [BoxShadow(color: Colors.black, blurRadius: 6, offset: Offset(0, -2))],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _ets2Stat('${game.idleTrucks.length}', 'Свободных', const Color(0xFF66BB6A)),
                        _ets2Divider(),
                        _ets2Stat('${game.transitTrucks.length}', 'В пути', const Color(0xFFF5C542)),
                        _ets2Divider(),
                        _ets2Stat('${game.availableContracts.length}', 'Контрактов', const Color(0xFF42A5F5)),
                        _ets2Divider(),
                        _ets2Stat('${game.myDrivers.length}', 'Водителей', const Color(0xFF90CAF9)),
                        _ets2Divider(),
                        _ets2Stat('${game.myGarages.length}', 'Гаражей', const Color(0xFFFF9800)),
                        _ets2Divider(),
                        _ets2Stat(GameConstants.weatherLabel, 'Погода', GameConstants.weatherColor),
                        _ets2Divider(),
                        _ets2Stat('€${GameConstants.currentFuelPricePerLiter.toStringAsFixed(2)}/л', 'Топливо',
                          GameConstants.currentFuelPricePerLiter > 1.8 ? const Color(0xFFEF5350) : const Color(0xFF66BB6A)),
                      ])),
                    ),
                  ),

                  // ===== Real-time clock + time of day =====
                  Positioned(
                    bottom: 50, left: 10,
                    child: Container(
                      width: 58, height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF444444), width: 0.5),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(GameConstants.timeOfDayIcon, color: GameConstants.timeOfDayColor, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            GameConstants.isNightTime ? 'Ночь' : 'День',
                            style: TextStyle(color: GameConstants.timeOfDayColor, fontSize: 8, fontWeight: FontWeight.w600),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text(
                          '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Color(0xFF999999), fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
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
      ),
      ),
    );
  }

  // ===== UI HELPERS =====
  Widget _ets2Badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF444444), width: 0.5),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3)),
    );
  }

  Widget _ets2Stat(String val, String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.4)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
  ]);

  Widget _ets2Divider() => Container(width: 1, height: 20, decoration: BoxDecoration(color: const Color(0xFF444444), borderRadius: BorderRadius.circular(1)));

  Widget _ets2MapBtn(IconData icon, String tooltip, VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF444444), width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Icon(icon, color: const Color(0xFF999999), size: 17),
        ),
      ),
    ),
  );
}

// ===== TRUCK INFO POPUP =====
class _TruckInfoPopup extends StatelessWidget {
  final Truck truck;
  final GameProvider game;
  final VoidCallback onClose;

  const _TruckInfoPopup({required this.truck, required this.game, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final truckType = GameConstants.findTruckType(truck.truckType);
    final typeLabel = truckType?.name ?? truck.truckType;
    final origin = truck.originCityId != null ? game.getCityById(truck.originCityId!) : null;
    final dest = truck.destinationCityId != null ? game.getCityById(truck.destinationCityId!) : null;
    final currentCity = truck.currentCityId != null ? game.getCityById(truck.currentCityId!) : null;
    final fuelPct = truck.maxFuel > 0 ? (truck.fuelLevel / truck.maxFuel * 100).round() : 0;
    final progress = _calcProgress(truck);
    final isDistressed = truck.fuelLevel < truck.maxFuel * 0.15 || truck.condition < 20;

    String? etaText;
    if (truck.estimatedArrival != null) {
      final diff = truck.estimatedArrival!.difference(DateTime.now());
      if (!diff.isNegative) {
        etaText = '${diff.inHours}ч ${diff.inMinutes % 60}м';
      } else {
        etaText = 'Прибыл!';
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDistressed ? const Color(0xFFEF5350).withOpacity(0.5) : const Color(0xFF444444)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: (truck.isInTransit ? const Color(0xFFF5C542) : isDistressed ? const Color(0xFFEF5350) : const Color(0xFF66BB6A)).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.local_shipping, size: 16, color: truck.isInTransit ? const Color(0xFFF5C542) : isDistressed ? const Color(0xFFEF5350) : const Color(0xFF66BB6A)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(truck.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 14, fontWeight: FontWeight.w700)),
              Text(typeLabel, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
            ])),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (truck.isInTransit ? const Color(0xFFF5C542) : isDistressed ? const Color(0xFFEF5350) : const Color(0xFF66BB6A)).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: (truck.isInTransit ? const Color(0xFFF5C542) : isDistressed ? const Color(0xFFEF5350) : const Color(0xFF66BB6A)).withOpacity(0.3)),
              ),
              child: Text(truck.statusDisplay, style: TextStyle(color: truck.isInTransit ? const Color(0xFFF5C542) : isDistressed ? const Color(0xFFEF5350) : const Color(0xFF66BB6A), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close, color: Color(0xFF999999), size: 16),
            ),
          ]),

          // Transit info
          if (truck.isInTransit && origin != null && dest != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.trip_origin, size: 14, color: Color(0xFF66BB6A)),
              const SizedBox(width: 4),
              Text(origin.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 12, color: Color(0xFF888888)),
              const SizedBox(width: 8),
              const Icon(Icons.location_on, size: 14, color: Color(0xFFEF5350)),
              const SizedBox(width: 4),
              Text(dest.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12)),
              if (etaText != null) ...[
                const Spacer(),
                Text('ETA: $etaText', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
              ],
            ]),
            // Progress bar
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Stack(children: [
                  Container(decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(3))),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5C542),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            Text('${(progress * 100).round()}% пройдено', style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
          ],

          // Idle: current city
          if (truck.isIdle && currentCity != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFF42A5F5)),
              const SizedBox(width: 4),
              Text('Город: ${currentCity.name}', style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12)),
            ]),
          ],

          // Condition & Fuel bars
          const SizedBox(height: 10),
          Row(children: [
            // Condition
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.build, size: 12, color: Color(0xFF888888)),
                const SizedBox(width: 4),
                Text('Состояние', style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
                const Spacer(),
                Text('${truck.condition}%', style: TextStyle(
                  color: truck.condition < 20 ? const Color(0xFFEF5350) : truck.condition < 50 ? const Color(0xFFF5C542) : const Color(0xFF66BB6A),
                  fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace',
                )),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: Stack(children: [
                    Container(decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(2))),
                    FractionallySizedBox(
                      widthFactor: (truck.condition / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: truck.condition < 20 ? const Color(0xFFEF5350) : truck.condition < 50 ? const Color(0xFFF5C542) : const Color(0xFF66BB6A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ])),
            const SizedBox(width: 16),
            // Fuel
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.local_gas_station, size: 12, color: Color(0xFF888888)),
                const SizedBox(width: 4),
                Text('Топливо', style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
                const Spacer(),
                Text('$fuelPct%', style: TextStyle(
                  color: fuelPct < 15 ? const Color(0xFFEF5350) : fuelPct < 30 ? const Color(0xFFF5C542) : const Color(0xFF42A5F5),
                  fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace',
                )),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: Stack(children: [
                    Container(decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(2))),
                    FractionallySizedBox(
                      widthFactor: (fuelPct / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: fuelPct < 15 ? const Color(0xFFEF5350) : fuelPct < 30 ? const Color(0xFFF5C542) : const Color(0xFF42A5F5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ])),
          ]),

          // Distressed warning
          if (isDistressed) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.warning, size: 14, color: Color(0xFFEF5350)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    truck.fuelLevel < truck.maxFuel * 0.15 && truck.condition < 20
                        ? 'Низкое топливо и плохое состояние!'
                        : truck.fuelLevel < truck.maxFuel * 0.15
                            ? 'Мало топлива — заправьте грузовик!'
                            : 'Плохое состояние — отремонтируйте!',
                    style: const TextStyle(color: Color(0xFFEF5350), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  double _calcProgress(Truck truck) {
    if (truck.estimatedArrival != null && truck.departureTime != null) {
      final total = truck.estimatedArrival!.difference(truck.departureTime!).inSeconds;
      if (total > 0) {
        final elapsed = DateTime.now().difference(truck.departureTime!).inSeconds;
        return (elapsed / total).clamp(0.0, 1.0);
      }
    }
    return 0.0;
  }
}

