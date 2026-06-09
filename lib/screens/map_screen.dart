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
import '../config/ferry_routes.dart';
import '../utils/pathfinder.dart';
import 'achievements_screen.dart';
import 'leaderboard_screen.dart';
import 'clan_screen.dart';
import 'event_log_screen.dart';
import '../widgets/achievement_toast.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/map_markers.dart';
import 'market_screen.dart';
import 'analytics_screen.dart';
import '../models/seasonal_event.dart';
import '../config/app_icons.dart';
import '../config/map_config.dart';
import '../config/country_boundaries.dart';
import '../widgets/country_flag.dart';
import '../widgets/notification_panel.dart';
import '../widgets/context_pane.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/keyboard_shortcuts_overlay.dart';
import '../widgets/delivery_timeline.dart';

/// Tile builder that darkens label tiles for subtler text overlay
Widget darkLabelTileBuilder(BuildContext context, Widget tile, TileLayer layer) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix([
      0.5, 0, 0, 0, 0,
      0, 0.5, 0, 0, 0,
      0, 0, 0.5, 0, 0,
      0, 0, 0, 0.7, 0,
    ]),
    child: tile,
  );
}

/// ETS2 road network — highway connections between cities (city id pairs).
const List<List<int>> _roadNetwork = [
  // ─── Original 15 cities ───
  [1, 5], [1, 4], [1, 2], [2, 5], [2, 8], [2, 6], [2, 7],
  [4, 5], [4, 3], [5, 6], [6, 3], [6, 7], [6, 12],
  [7, 9], [7, 11], [12, 11], [12, 10], [12, 3], [11, 13],
  [10, 3], [10, 13], [15, 14], [14, 10], [8, 9], [13, 9],
  // ─── New cities (16-30) ───
  [16, 3], [16, 4], [16, 21],         // Hamburg
  [17, 6], [17, 7], [17, 11], [17, 12], // Munich
  [18, 2], [18, 30], [18, 7],         // Lyon
  [19, 8], [19, 30],                  // Barcelona
  [20, 9], [20, 7], [20, 17],         // Milan
  [21, 16], [21, 14],                 // Copenhagen
  [22, 1],                            // Dublin
  [23, 13], [23, 24], [23, 25],       // Bucharest
  [24, 25], [24, 28],                 // Sofia
  [25, 13], [25, 26],                 // Belgrade
  [26, 11], [26, 13],                 // Zagreb
  [27, 14],                           // Helsinki
  [28, 24], [28, 29],                 // Athens
  [29, 23],                           // Istanbul
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
  Timer? _clockTimer;
  int? _selectedCityId;
  bool _isDesktop = true;
  final FocusNode _mapFocus = FocusNode();
  final GlobalKey<AchievementToastOverlayState> _achievementToastKey =
      GlobalKey<AchievementToastOverlayState>();
  Truck? _selectedTruck;
  bool _eventBannerDismissed = false;
  Timer? _eventBannerTimer;

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
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _mapFocus.requestFocus();
  }
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _contractGenTimer?.cancel();
    _truckAnimTimer?.cancel();
    _clockTimer?.cancel();
    _eventBannerTimer?.cancel();
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

  void _openNotificationPanel(BuildContext context) {
    final game = context.read<GameProvider>();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: NotificationPanel(
            notifications: game.eventLog.map((e) => NotificationItem(
              id: e.id,
              title: e.title,
              body: e.description,
              icon: e.icon,
              color: e.color,
              timestamp: e.createdAt,
            )).toList().reversed.take(20).toList(),
            onClose: () => Navigator.of(context).pop(),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
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
    _showContextPane(context, city);
  }

  void _showContextPane(BuildContext context, City city) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: ContextPane(
            city: city,
            onClose: () {
              Navigator.of(context).pop();
              setState(() => _selectedCityId = null);
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
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

  double _calcHeading(Truck truck, GameProvider game) {
    if (truck.originCityId == null || truck.destinationCityId == null) return 0;
    final origin = game.getCityById(truck.originCityId!);
    final dest = game.getCityById(truck.destinationCityId!);
    if (origin == null || dest == null) return 0;
    final dx = dest.longitude - origin.longitude;
    final dy = dest.latitude - origin.latitude;
    var deg = math.atan2(dx, -dy) * 180 / math.pi;
    if (deg < 0) deg += 360;
    return deg;
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

  /// Build road network polylines (excluding ferry connections).
  List<Polyline> _buildRoadNetwork(GameProvider game) {
    final roads = <Polyline>[];
    final cityMap = <int, City>{};
    for (final c in game.cities) { cityMap[c.id] = c; }
    for (final pair in _roadNetwork) {
      // Skip ferry connections — they are drawn separately as dashed lines
      if (FerryRoutes.isFerryRoute(pair[0], pair[1])) continue;
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

  /// Build ferry route polylines (dashed cyan lines across water).
  List<Polyline> _buildFerryPolylines() {
    final polylines = <Polyline>[];
    for (final route in FerryRoutes.all) {
      polylines.add(Polyline(
        points: route.waypoints,
        color: const Color(0xFF29B6F6).withOpacity(0.6),
        strokeWidth: 2.0,
        borderStrokeWidth: 3.0,
        borderColor: const Color(0xFF29B6F6).withOpacity(0.3),
        pattern: const StrokePattern.dashed(segments: [8, 6]),
        borderPattern: const StrokePattern.dashed(segments: [8, 6]),
      ));
    }
    return polylines;
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
        final pulse = 0.3 + 0.1 * math.sin(DateTime.now().millisecondsSinceEpoch / 500);
        routes.add(Polyline(
          points: [truckPos, LatLng(dest.latitude, dest.longitude)],
          color: const Color(0xFFF5C542).withOpacity(pulse),
          strokeWidth: 3.0,
          borderStrokeWidth: 1.5,
          borderColor: const Color(0xFFD4A017).withOpacity(pulse * 0.7),
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

      // Remaining portion: from truck position to end (dim, pulsing)
      final remainingPoints = <LatLng>[
        truckPos,
        if (segIdx + 1 < pathPoints.length) ...pathPoints.skip(segIdx + 1),
      ];
      if (remainingPoints.length >= 2) {
        final pulse = 0.3 + 0.1 * math.sin(DateTime.now().millisecondsSinceEpoch / 500);
        routes.add(Polyline(
          points: remainingPoints,
          color: const Color(0xFFF5C542).withOpacity(pulse),
          strokeWidth: 3.0,
          borderStrokeWidth: 1.5,
          borderColor: const Color(0xFFD4A017).withOpacity(pulse * 0.7),
        ));
      }
    }
    return routes;
  }

  /// Builds subtle country shading polygons from CountryBoundaries data.
  /// Each country occupied by an in-game city gets a semi-transparent fill.
  List<Polygon> _buildCountryShading(GameProvider game) {
    final polygons = <Polygon>[];
    // Collect unique countries present in the game's city list.
    final seenCountries = <String>{};
    for (final city in game.cities) {
      if (seenCountries.add(city.country.toLowerCase())) {
        final verts = CountryBoundaries.polygonFor(city.country);
        final color = CountryBoundaries.colorFor(city.country);
        if (verts != null && color != null) {
          polygons.add(Polygon(
            points: verts,
            color: color.withOpacity(0.35),
            borderColor: color.withOpacity(0.5),
            borderStrokeWidth: 1.0,
            isFilled: true,
          ));
        }
      }
    }
    return polygons;
  }

  void _showEventDetailsDialog(BuildContext context, SeasonalEvent event) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: const Color(0xFFF5C542).withOpacity(0.3)),
        ),
        title: Text(event.title, style: const TextStyle(color: Color(0xFFF5C542), fontWeight: FontWeight.w700)),
        content: Text(
          event.description,
          style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть', style: TextStyle(color: Color(0xFF999999))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final company = game.company;

    // Loading — skeleton placeholders
    if (game.isLoading && !game.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton top bar
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C2C2C),
                    border: Border(bottom: BorderSide(color: Color(0xFF444444), width: 1)),
                  ),
                  child: Row(
                    children: [
                      const SkeletonBox(width: 20, height: 20, borderRadius: 4),
                      const SizedBox(width: 6),
                      const Expanded(child: SkeletonBox(height: 14, width: 200)),
                      const SkeletonBox(width: 70, height: 20, borderRadius: 3),
                      const SizedBox(width: 6),
                      const SkeletonBox(width: 50, height: 20, borderRadius: 3),
                    ],
                  ),
                ),
                // Skeleton map placeholder
                Container(
                  height: 300,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF5C542), strokeWidth: 2),
                  ),
                ),
                // Skeleton list items
                const SkeletonCard(),
                const SkeletonCard(),
                const SkeletonCard(),
                const SkeletonCard(),
                const SizedBox(height: 38), // bottom bar space
              ],
            ),
          ),
        ),
      );
    }

    // Error
    if (game.error != null && !game.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(AppIcons.error, size: 48, color: Color(0xFFEF5350)),
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
        // Handle Ctrl+/ for keyboard shortcuts overlay
        if (HardwareKeyboard.instance.isControlPressed && event.logicalKey == LogicalKeyboardKey.slash) {
          showDialog(context: context, barrierColor: Colors.black.withOpacity(0.6), builder: (_) => const KeyboardShortcutsOverlay());
          return KeyEventResult.handled;
        }
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
          case LogicalKeyboardKey.keyM:
            _openModal(const MarketScreen());
            return KeyEventResult.handled;
          case LogicalKeyboardKey.keyB:
            _openModal(const AnalyticsScreen());
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
        child: TutorialOverlay(
          onComplete: () { /* tutorial done */ },
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
                        // Dark map tiles (configurable via MapConfig)
                        TileLayer(
                          urlTemplate: MapConfig.baseTileUrl,
                          userAgentPackageName: MapConfig.userAgent,
                          retinaMode: MapConfig.retinaMode,
                        ),
                        if (MapConfig.useSeparateLabels)
                          TileLayer(
                            urlTemplate: MapConfig.labelTileUrl,
                            userAgentPackageName: MapConfig.userAgent,
                            retinaMode: MapConfig.retinaMode,
                            tileBuilder: darkLabelTileBuilder,
                          ),
                        // Country shading polygons
                        PolygonLayer(
                          polygons: _buildCountryShading(game),
                        ),
                        PolylineLayer(polylines: _buildRoadNetwork(game)),
                        PolylineLayer(polylines: _buildFerryPolylines()),
                        PolylineLayer(polylines: _buildTruckRoutes(game)),

                        // City markers
                        MarkerLayer(
                          markers: game.cities.map((city) {
                            final hasWarehouse = game.myWarehouses.any((w) => w.cityId == city.id);
                            final hasGarage = game.hasGarageInCity(city.id);
                            final hasTruck = game.myTrucks.any((t) => t.currentCityId == city.id && t.isIdle);
                            return Marker(
                              point: LatLng(city.latitude, city.longitude),
                              width: 48,
                              height: 48,
                              child: CityMarker(
                                hasWarehouse: hasWarehouse,
                                hasGarage: hasGarage,
                                hasTruck: hasTruck,
                                isSelected: _selectedCityId == city.id,
                                onTap: () => _onCityTap(city),
                              ),
                            );
                          }).toList(),
                        ),

                        // City labels with country flags
                        MarkerLayer(
                          markers: game.cities.map((city) {
                            return Marker(
                              point: LatLng(city.latitude, city.longitude),
                              width: 130, height: 22,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Transform.translate(
                                  offset: const Offset(0, -12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A).withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CountryFlag(countryCode: city.countryCode, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
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
                            ...game.myTrucks.map((truck) {
                              final pos = _getTruckPosition(truck, game);
                              if (pos == null) return const Marker(point: LatLng(0, 0), width: 0, height: 0, child: SizedBox());
                              final isDistressed = truck.fuelLevel < truck.maxFuel * 0.15 || truck.condition < 20;
                              final heading = _calcHeading(truck, game);
                              return Marker(
                                point: pos,
                                width: 36,
                                height: 36,
                                child: TruckMarker(
                                  isIdle: truck.isIdle,
                                  isDistressed: isDistressed,
                                  isLoading: truck.status == 'loading',
                                  heading: heading,
                                  onTap: truck.isIdle
                                      ? () => setState(() { _selectedTruck = null; _onCityTap(game.getCityById(truck.currentCityId!)!); })
                                      : () => setState(() { _selectedCityId = null; _selectedTruck = truck; }),
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

                  // ===== VIGNETTE OVERLAY — premium edge darkening =====
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.7,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.15),
                            ],
                          ),
                        ),
                      ),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
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
                                icon: const Icon(AppIcons.menu, color: Color(0xFF999999)),
                                onPressed: () => Scaffold.of(context).openDrawer(),
                              ),
                              const SizedBox(width: 2),
                            ],
                            const Icon(AppIcons.truck, color: Color(0xFFF5C542), size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                company?.name ?? '...',
                                style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Clock + weather indicator
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  DateTime.now().toUtc().toString().substring(11, 16),
                                  style: const TextStyle(color: Color(0xFF666666), fontSize: 11, fontFamily: 'JetBrains Mono'),
                                ),
                                const Text(' UTC', style: TextStyle(color: Color(0xFF444444), fontSize: 9)),
                                const SizedBox(width: 8),
                                Icon(GameConstants.weatherIcon, color: GameConstants.weatherColor, size: 14),
                              ],
                            ),
                            const SizedBox(width: 8),
                            if (company != null) ...[
                              _ets2Badge(company.moneyFormatted, const Color(0xFFF5C542)),
                              const SizedBox(width: 6),
                              _ets2Badge('Lv.${company.level}${company.prestigeDisplay}', const Color(0xFF66BB6A)),
                              if (game.isInClan && game.myClan != null) ...[
                                const SizedBox(width: 6),
                                _ets2Badge('[${game.myClan!.tag}]', const Color(0xFFCE93D8)),
                              ],
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(AppIcons.eventLog, color: Color(0xFF999999), size: 18),
                                tooltip: 'Уведомления',
                                onPressed: () => _openNotificationPanel(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              ),
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
                        // ===== SEASONAL EVENT BANNER =====
                        if (game.activeEvents.isNotEmpty && !_eventBannerDismissed)
                          _SeasonalEventBanner(
                            events: game.activeEvents,
                            onDismiss: () {
                              setState(() => _eventBannerDismissed = true);
                              _eventBannerTimer?.cancel();
                            },
                            onShowDetails: (event) => _showEventDetailsDialog(context, event),
                          ),
                      ],
                    ),
                  ),

                  // ===== MAP CONTROLS =====
                  Positioned(
                    top: 58 + (game.activeEvents.isNotEmpty && !_eventBannerDismissed ? 38 : 0), right: 10,
                    child: Column(children: [
                      _ets2MapBtn(AppIcons.add, 'Приблизить (+)', () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                      const SizedBox(height: 2),
                      _ets2MapBtn(AppIcons.zoomOut, 'Отдалить (-)', () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                      const SizedBox(height: 2),
                      _ets2MapBtn(AppIcons.public, 'Обзор мира', () => _mapController.move(const LatLng(25, 15), 1.8)),
                      const SizedBox(height: 2),
                      _ets2MapBtn(AppIcons.cropFree, 'Обзор Европы', () => _mapController.move(const LatLng(50, 10), 4)),
                      const SizedBox(height: 2),
                      _ets2MapBtn(AppIcons.myLocation, 'К первому грузовику', () {
                        final firstTruck = game.myTrucks.where((t) => t.isIdle).firstOrNull;
                        if (firstTruck != null && firstTruck.currentCityId != null) {
                          final city = game.getCityById(firstTruck.currentCityId!);
                          if (city != null) _mapController.move(LatLng(city.latitude, city.longitude), 7);
                        }
                      }),
                      const SizedBox(height: 2),
                      _ets2MapBtn(AppIcons.refreshCw, 'Обновить (R)', _refresh),
                      const SizedBox(height: 2),
                      _ets2MapBtn(AppIcons.info, 'Горячие клавиши (Ctrl+/)', () {
                        showDialog(context: context, barrierColor: Colors.black.withOpacity(0.6), builder: (_) => const KeyboardShortcutsOverlay());
                      }),
                    ]),
                  ),

                  // Bottom bar stats — compact HUD style
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E).withOpacity(0.85),
                        border: Border(top: BorderSide(color: const Color(0xFF333333).withOpacity(0.8))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _hudItem(AppIcons.truck, '${game.idleTrucks.length}', const Color(0xFF66BB6A)),
                          _hudDivider(),
                          _hudItem(AppIcons.truck, '${game.transitTrucks.length}', const Color(0xFFF5C542)),
                          _hudDivider(),
                          _hudItem(AppIcons.description, '${game.availableContracts.length}', const Color(0xFF42A5F5)),
                          _hudDivider(),
                          _hudItem(AppIcons.users, '${game.myDrivers.length}', const Color(0xFF90CAF9)),
                          _hudDivider(),
                          _hudItem(AppIcons.weatherIcon, GameConstants.weatherLabel.split(' ').last, GameConstants.weatherColor),
                          _hudDivider(),
                          _hudItem(AppIcons.fuel, '${GameConstants.currentFuelPricePerLiter.toStringAsFixed(1)}',
                            GameConstants.currentFuelPricePerLiter > 1.8 ? const Color(0xFFEF5350) : const Color(0xFF66BB6A)),
                        ],
                      ),
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

  Widget _hudItem(IconData icon, String value, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'JetBrains Mono')),
    ],
  );

  Widget _hudDivider() => Container(width: 1, height: 18, color: const Color(0xFF333333), margin: const EdgeInsets.symmetric(horizontal: 2));

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

// ===== SEASONAL EVENT BANNER =====
class _SeasonalEventBanner extends StatelessWidget {
  final List<SeasonalEvent> events;
  final VoidCallback onDismiss;
  final void Function(SeasonalEvent) onShowDetails;

  const _SeasonalEventBanner({
    required this.events,
    required this.onDismiss,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final event = events.first;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(bottom: BorderSide(color: const Color(0xFFF5C542).withOpacity(0.3))),
      ),
      child: Row(
        children: [
          const Icon(AppIcons.emojiEvents, color: Color(0xFFF5C542), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => onShowDetails(event),
              child: Text(
                '${event.title}: ${event.description}',
                style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(AppIcons.close, color: Color(0xFF666666), size: 14),
          ),
        ],
      ),
    );
  }
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
              child: Icon(AppIcons.truck, size: 16, color: truck.isInTransit ? const Color(0xFFF5C542) : isDistressed ? const Color(0xFFEF5350) : const Color(0xFF66BB6A)),
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
              child: const Icon(AppIcons.close, color: Color(0xFF999999), size: 16),
            ),
          ]),

          // Transit info
          if (truck.isInTransit && origin != null && dest != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(AppIcons.tripOrigin, size: 14, color: Color(0xFF66BB6A)),
              const SizedBox(width: 4),
              Text(origin.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12)),
              const SizedBox(width: 8),
              const Icon(AppIcons.arrowForward, size: 12, color: Color(0xFF888888)),
              const SizedBox(width: 8),
              const Icon(AppIcons.location, size: 14, color: Color(0xFFEF5350)),
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

            // Ferry segment info for in-transit trucks
            if (truck.status == 'in_transit' && truck.originCityId != null && truck.destinationCityId != null)
              Builder(builder: (context) {
                final path = PathFinder.findPath(truck.originCityId!, truck.destinationCityId!);
                final ferrySegs = FerryRoutes.ferrySegmentsInPath(path);
                if (ferrySegs.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF29B6F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF29B6F6).withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(AppIcons.anchor, size: 14, color: Color(0xFF29B6F6)),
                          const SizedBox(width: 4),
                          Text('Паром: ${ferrySegs.first.name}', style: const TextStyle(color: Color(0xFF29B6F6), fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      const SizedBox(height: 2),
                      for (final seg in ferrySegs)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 1),
                          child: Text(
                            '${seg.operator} · ${seg.seaName} · €${seg.costEur} · ~${(seg.durationMinutes / 60).round()}ч',
                            style: TextStyle(color: Color(0xFF29B6F6).withOpacity(0.7), fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                );
              }),

            // Delivery timeline for in-transit trucks
            if (truck.status == 'in_transit')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: DeliveryTimeline(
                  steps: [
                    TimelineStep(
                      label: origin?.name ?? 'Отправление',
                      timestamp: truck.departureTime != null ? '${truck.departureTime!.hour.toString().padLeft(2, '0')}:${truck.departureTime!.minute.toString().padLeft(2, '0')}' : null,
                      icon: AppIcons.tripOrigin,
                      color: const Color(0xFF66BB6A),
                      isComplete: true,
                    ),
                    TimelineStep(
                      label: 'В пути',
                      timestamp: '${(progress * 100).round()}%',
                      icon: AppIcons.truck,
                      color: const Color(0xFFF5C542),
                      isCurrent: true,
                    ),
                    TimelineStep(
                      label: dest?.name ?? 'Назначение',
                      timestamp: etaText,
                      icon: AppIcons.location,
                      color: const Color(0xFFEF5350),
                    ),
                  ],
                ),
              ),
          ],

          // Idle: current city
          if (truck.isIdle && currentCity != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(AppIcons.location, size: 14, color: Color(0xFF42A5F5)),
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
                const Icon(AppIcons.wrench, size: 12, color: Color(0xFF888888)),
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
                const Icon(AppIcons.fuel, size: 12, color: Color(0xFF888888)),
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
        ],
      ),
    );
  }
}

/// Top-level helper so it can be used inside the private _TruckInfoPopup widget.
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
