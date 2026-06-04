import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class MapMainScreen extends StatefulWidget {
  const MapMainScreen({super.key});

  @override
  State<MapMainScreen> createState() => MapMainScreenState();
}

class MapMainScreenState extends State<MapMainScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  Timer? _shipUpdateTimer;
  bool _sidebarExpanded = true;
  String? _selectedPortId;
  String? _selectedShipId;
  bool _showRoutes = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _shipUpdateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _refreshShips();
      }
    });
  }

  @override
  void dispose() {
    _shipUpdateTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final game = context.read<GameProvider>();
    await game.loadPorts();
    await game.loadDashboard();
    final auth = context.read<AuthProvider>();
    await auth.loadProfile();
  }

  Future<void> _refreshShips() async {
    final game = context.read<GameProvider>();
    await game.loadMyShips();
    await game.loadMyVoyages();
  }

  void _onPortTap(String portId) {
    setState(() {
      _selectedPortId = portId;
      _selectedShipId = null;
    });
    final port = GameConstants.findPort(portId);
    if (port != null) {
      _mapController.move(LatLng(port.latitude, port.longitude), 6);
    }
  }

  void _onShipTap(String shipId) {
    setState(() {
      _selectedShipId = shipId;
      _selectedPortId = null;
    });
    final game = context.read<GameProvider>();
    final ship = game.myShips.where((s) => s.id == shipId).firstOrNull;
    if (ship != null && ship.currentPortId != null) {
      final port = GameConstants.findPort(ship.currentPortId!);
      if (port != null) {
        _mapController.move(LatLng(port.latitude, port.longitude), 7);
      }
    }
  }

  LatLng? _getShipPosition(String shipId) {
    final game = context.read<GameProvider>();
    final ship = game.myShips.where((s) => s.id == shipId).firstOrNull;
    if (ship == null) return null;

    if (ship.currentPortId != null) {
      final port = GameConstants.findPort(ship.currentPortId!);
      if (port != null) return LatLng(port.latitude, port.longitude);
    }

    if (ship.status == 'in_transit') {
      final voyage = game.myVoyages
          .where((v) => v.shipId == shipId && v.isActive)
          .firstOrNull;
      if (voyage != null) {
        final originPort = GameConstants.findPort(voyage.originPortId);
        final destPort = GameConstants.findPort(voyage.destinationPortId);
        if (originPort != null && destPort != null) {
          final progress = voyage.progress.clamp(0.0, 1.0);
          return _interpolateLatLng(
            LatLng(originPort.latitude, originPort.longitude),
            LatLng(destPort.latitude, destPort.longitude),
            progress,
          );
        }
      }
    }

    final defaultPort = GameConstants.findPort('rotterdam');
    if (defaultPort != null) return LatLng(defaultPort.latitude, defaultPort.longitude);
    return const LatLng(51.92, 4.48);
  }

  LatLng _interpolateLatLng(LatLng start, LatLng end, double t) {
    // Great circle interpolation (simplified)
    final lat1 = start.latitude * math.pi / 180;
    final lat2 = end.latitude * math.pi / 180;
    final dLon = (end.longitude - start.longitude) * math.pi / 180;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x);

    final d = 2 * math.asin(math.sqrt(
      math.pow(math.sin((lat2 - lat1) / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2),
    ));

    final lat = math.asin(
      math.sin(lat1) * math.cos(d * t) + math.cos(lat1) * math.sin(d * t) * math.cos(bearing)
    );
    final lon = (start.longitude * math.pi / 180) +
        math.atan2(
          math.sin(bearing) * math.sin(d * t) * math.cos(lat1),
          math.cos(d * t) - math.sin(lat1) * math.sin(lat)
        );

    return LatLng(lat * 180 / math.pi, lon * 180 / math.pi);
  }

  void _zoomToWorld() {
    _mapController.move(const LatLng(20, 30), 2);
  }

  void _zoomToFleet() {
    final game = context.read<GameProvider>();
    if (game.myShips.isEmpty) return;

    double minLat = 90, maxLat = -90, minLon = 180, maxLon = -180;
    for (final ship in game.myShips) {
      final pos = _getShipPosition(ship.id);
      if (pos != null) {
        minLat = math.min(minLat, pos.latitude);
        maxLat = math.max(maxLat, pos.latitude);
        minLon = math.min(minLon, pos.longitude);
        maxLon = math.max(maxLon, pos.longitude);
      }
    }
    final center = LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
    _mapController.move(center, 4);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final profile = auth.profile;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Row(
        children: [
          // === SIDEBAR ===
          _Sidebar(
            expanded: _sidebarExpanded,
            onToggle: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            profile: profile,
            shipCount: game.myShips.length,
            voyageCount: game.myVoyages.where((v) => v.isActive).length,
          ),

          // === MAIN AREA ===
          Expanded(
            child: Stack(
              children: [
                // MAP
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(20, 30),
                    initialZoom: 2.5,
                    minZoom: 2,
                    maxZoom: 18,
                    onTap: (_, __) {
                      setState(() {
                        _selectedPortId = null;
                        _selectedShipId = null;
                      });
                    },
                  ),
                  children: [
                    // Dark map tiles
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      userAgentPackageName: 'com.mannycat.shippingmanager',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      retinaMode: true,
                    ),

                    // Voyage routes
                    if (_showRoutes)
                      _VoyageRoutesLayer(gameProvider: game),

                    // Port markers
                    _PortMarkersLayer(
                      onPortTap: _onPortTap,
                      selectedPortId: _selectedPortId,
                    ),

                    // Ship markers
                    _ShipMarkersLayer(
                      gameProvider: game,
                      getShipPosition: _getShipPosition,
                      onShipTap: _onShipTap,
                      selectedShipId: _selectedShipId,
                    ),
                  ],
                ),

                // TOP BAR
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _TopBar(
                    profile: profile,
                    onRefresh: _loadData,
                  ),
                ),

                // MAP CONTROLS (right side)
                Positioned(
                  top: 70,
                  right: 16,
                  child: Column(
                    children: [
                      _MapControlButton(
                        icon: Icons.public,
                        tooltip: 'Весь мир',
                        onTap: _zoomToWorld,
                      ),
                      const SizedBox(height: 6),
                      _MapControlButton(
                        icon: Icons.directions_boat,
                        tooltip: 'Мой флот',
                        onTap: _zoomToFleet,
                      ),
                      const SizedBox(height: 6),
                      _MapControlButton(
                        icon: _showRoutes ? Icons.route : Icons.route_outlined,
                        tooltip: 'Маршруты',
                        onTap: () => setState(() => _showRoutes = !_showRoutes),
                        active: _showRoutes,
                      ),
                    ],
                  ),
                ),

                // INFO PANEL (port or ship)
                if (_selectedPortId != null)
                  Positioned(
                    top: 70,
                    left: 16,
                    child: _PortInfoPanel(
                      portId: _selectedPortId!,
                      gameProvider: game,
                      onClose: () => setState(() => _selectedPortId = null),
                      onNavigate: (route) {
                        setState(() => _selectedPortId = null);
                        context.go(route);
                      },
                    ),
                  ),

                if (_selectedShipId != null)
                  Positioned(
                    top: 70,
                    left: 16,
                    child: _ShipInfoPanel(
                      shipId: _selectedShipId!,
                      gameProvider: game,
                      onClose: () => setState(() => _selectedShipId = null),
                      onNavigate: (route) {
                        setState(() => _selectedShipId = null);
                        context.go(route);
                      },
                    ),
                  ),

                // BOTTOM STATS BAR
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _BottomStatsBar(gameProvider: game),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SIDEBAR
// ============================================================
class _Sidebar extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final dynamic profile;
  final int shipCount;
  final int voyageCount;

  const _Sidebar({
    required this.expanded,
    required this.onToggle,
    required this.profile,
    required this.shipCount,
    required this.voyageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? 220 : 60,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          right: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            height: 56,
            padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_boat, color: AppTheme.accentBlue, size: 28),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'SHIPPING\nMANAGER',
                      style: AppTheme.labelSmall.copyWith(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),

          // Nav items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _SidebarItem(
                    icon: Icons.map_outlined,
                    iconFilled: Icons.map,
                    label: 'Карта',
                    route: '/',
                    expanded: expanded,
                    isCurrent: true,
                  ),
                  _SidebarItem(
                    icon: Icons.anchor_outlined,
                    iconFilled: Icons.anchor,
                    label: 'Порты',
                    route: '/ports',
                    expanded: expanded,
                  ),
                  _SidebarItem(
                    icon: Icons.directions_boat_outlined,
                    iconFilled: Icons.directions_boat,
                    label: 'Флот',
                    route: '/fleet',
                    expanded: expanded,
                    badge: shipCount > 0 ? '$shipCount' : null,
                  ),
                  _SidebarItem(
                    icon: Icons.route_outlined,
                    iconFilled: Icons.route,
                    label: 'Рейсы',
                    route: '/voyages',
                    expanded: expanded,
                    badge: voyageCount > 0 ? '$voyageCount' : null,
                  ),
                  const SizedBox(height: 4),
                  _SidebarDivider(expanded: expanded),
                  _SidebarItem(
                    icon: Icons.store_outlined,
                    iconFilled: Icons.store,
                    label: 'Рынок',
                    route: '/market',
                    expanded: expanded,
                  ),
                  _SidebarItem(
                    icon: Icons.account_balance_outlined,
                    iconFilled: Icons.account_balance,
                    label: 'Финансы',
                    route: '/finance',
                    expanded: expanded,
                  ),
                  _SidebarItem(
                    icon: Icons.factory_outlined,
                    iconFilled: Icons.factory,
                    label: 'Производство',
                    route: '/production',
                    expanded: expanded,
                  ),
                  _SidebarItem(
                    icon: Icons.people_outlined,
                    iconFilled: Icons.people,
                    label: 'Персонал',
                    route: '/personnel',
                    expanded: expanded,
                  ),
                  const SizedBox(height: 4),
                  _SidebarDivider(expanded: expanded),
                  _SidebarItem(
                    icon: Icons.business_outlined,
                    iconFilled: Icons.business,
                    label: 'Профиль',
                    route: '/profile',
                    expanded: expanded,
                  ),
                  _SidebarItem(
                    icon: Icons.settings_outlined,
                    iconFilled: Icons.settings,
                    label: 'Настройки',
                    route: '/settings',
                    expanded: expanded,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),

          // Collapse button
          Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              icon: Icon(
                expanded ? Icons.chevron_left : Icons.chevron_right,
                color: AppTheme.textGray,
                size: 20,
              ),
              onPressed: onToggle,
              tooltip: expanded ? 'Свернуть' : 'Развернуть',
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData iconFilled;
  final String label;
  final String route;
  final bool expanded;
  final bool isCurrent;
  final String? badge;

  const _SidebarItem({
    required this.icon,
    required this.iconFilled,
    required this.label,
    required this.route,
    required this.expanded,
    this.isCurrent = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    String currentLocation = '/';
    try {
      currentLocation = GoRouterState.of(context).matchedLocation;
    } catch (_) {
      // Fallback if not inside a GoRouter
    }
    final active = isCurrent || currentLocation == route ||
        (route != '/' && currentLocation.startsWith(route));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go(route),
        child: Container(
          height: 42,
          padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0),
          decoration: BoxDecoration(
            color: active ? AppTheme.accentBlue.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                active ? iconFilled : icon,
                color: active ? AppTheme.accentBlue : AppTheme.textGray,
                size: 20,
              ),
              if (expanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? AppTheme.textWhite : AppTheme.textGray,
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  final bool expanded;
  const _SidebarDivider({required this.expanded});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 12, vertical: 4),
      child: const Divider(height: 1, color: AppTheme.dividerColor),
    );
  }
}

// ============================================================
// TOP BAR
// ============================================================
class _TopBar extends StatelessWidget {
  final dynamic profile;
  final VoidCallback onRefresh;

  const _TopBar({required this.profile, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final money = (profile?.money as int?) ?? 0;
    final companyName = (profile?.companyName as String?) ?? '...';

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Company name
          Text(companyName, style: AppTheme.labelMedium),
          const Spacer(),
          // Money
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.profitGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.profitGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.attach_money, color: AppTheme.profitGreen, size: 16),
                const SizedBox(width: 4),
                Text(
                  '\$${_formatMoney(money)}',
                  style: AppTheme.monoNumber.copyWith(
                    color: AppTheme.profitGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textGray, size: 20),
            onPressed: onRefresh,
            tooltip: 'Обновить',
          ),
        ],
      ),
    );
  }

  String _formatMoney(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toString();
  }
}

// ============================================================
// MAP CONTROL BUTTON
// ============================================================
class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: active
            ? AppTheme.accentBlue.withValues(alpha: 0.3)
            : AppTheme.surfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? AppTheme.accentBlue : AppTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: active ? AppTheme.accentBlue : AppTheme.textGrayLight,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PORT MARKERS LAYER
// ============================================================
class _PortMarkersLayer extends StatelessWidget {
  final void Function(String) onPortTap;
  final String? selectedPortId;

  const _PortMarkersLayer({required this.onPortTap, this.selectedPortId});

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    for (final port in GameConstants.ports) {
      final isSelected = port.id == selectedPortId;
      markers.add(
        Marker(
          point: LatLng(port.latitude, port.longitude),
          width: isSelected ? 40 : 28,
          height: isSelected ? 40 : 28,
          child: GestureDetector(
            onTap: () => onPortTap(port.id),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppTheme.accentBlue
                    : AppTheme.accentBlue.withValues(alpha: 0.7),
                border: Border.all(
                  color: isSelected ? Colors.white : AppTheme.accentBlue.withValues(alpha: 0.4),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentBlue.withValues(alpha: 0.5),
                    blurRadius: isSelected ? 10 : 4,
                    spreadRadius: isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.anchor,
                  size: isSelected ? 18 : 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return MarkerLayer(markers: markers);
  }
}

// ============================================================
// SHIP MARKERS LAYER
// ============================================================
class _ShipMarkersLayer extends StatelessWidget {
  final GameProvider gameProvider;
  final LatLng? Function(String) getShipPosition;
  final void Function(String) onShipTap;
  final String? selectedShipId;

  const _ShipMarkersLayer({
    required this.gameProvider,
    required this.getShipPosition,
    required this.onShipTap,
    this.selectedShipId,
  });

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    for (final ship in gameProvider.myShips) {
      final pos = getShipPosition(ship.id);
      if (pos == null) continue;

      final isSelected = ship.id == selectedShipId;
      final isInTransit = ship.status == 'in_transit';
      final color = isInTransit ? AppTheme.warningAmber : AppTheme.profitGreen;

      markers.add(
        Marker(
          point: pos,
          width: isSelected ? 44 : 32,
          height: isSelected ? 44 : 32,
          child: GestureDetector(
            onTap: () => onShipTap(ship.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: isSelected ? Colors.white : color.withValues(alpha: 0.4),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: isSelected ? 12 : 5,
                    spreadRadius: isSelected ? 3 : 0,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  isInTransit ? Icons.sailing : Icons.directions_boat,
                  size: isSelected ? 20 : 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return MarkerLayer(markers: markers);
  }
}

// ============================================================
// VOYAGE ROUTES LAYER
// ============================================================
class _VoyageRoutesLayer extends StatelessWidget {
  final GameProvider gameProvider;

  const _VoyageRoutesLayer({required this.gameProvider});

  @override
  Widget build(BuildContext context) {
    final polylines = <Polyline>[];
    for (final voyage in gameProvider.myVoyages) {
      if (!voyage.isActive) continue;
      final origin = GameConstants.findPort(voyage.originPortId);
      final dest = GameConstants.findPort(voyage.destinationPortId);
      if (origin == null || dest == null) continue;

      polylines.add(
        Polyline(
          points: [
            LatLng(origin.latitude, origin.longitude),
            LatLng(dest.latitude, dest.longitude),
          ],
          color: AppTheme.accentBlue.withValues(alpha: 0.4),
          strokeWidth: 2,
          borderStrokeWidth: 4,
          borderColor: AppTheme.accentBlue.withValues(alpha: 0.15),
        ),
      );
    }
    return PolylineLayer(polylines: polylines);
  }
}

// ============================================================
// PORT INFO PANEL
// ============================================================
class _PortInfoPanel extends StatelessWidget {
  final String portId;
  final GameProvider gameProvider;
  final VoidCallback onClose;
  final void Function(String) onNavigate;

  const _PortInfoPanel({
    required this.portId,
    required this.gameProvider,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final port = GameConstants.findPort(portId);
    if (port == null) return const SizedBox.shrink();

    final shipsHere = gameProvider.myShips
        .where((s) => s.currentPortId == portId && s.status == 'idle')
        .toList();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.anchor, color: AppTheme.accentBlue, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(port.name, style: AppTheme.labelMedium),
                      Text('${port.country}  •  ${port.region}', style: AppTheme.bodyTextSmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textGray, size: 18),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Координаты', value: '${port.latitude.toStringAsFixed(2)}, ${port.longitude.toStringAsFixed(2)}'),
                _InfoRow(label: 'Налог', value: '${(port.taxRate * 100).toStringAsFixed(0)}%'),
                _InfoRow(label: 'Топливо', value: port.hasFuel ? 'Да' : 'Нет'),
                _InfoRow(label: 'Док', value: port.hasDock ? 'Есть' : 'Нет'),
                const SizedBox(height: 8),
                Text('Корабли в порту: ${shipsHere.length}', style: AppTheme.labelSmall),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onNavigate('/ports/$portId'),
                    child: const Text('Открыть порт'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onNavigate('/ports'),
                    child: const Text('Все порты'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyTextSmall),
          Text(value, style: AppTheme.monoNumberSmall),
        ],
      ),
    );
  }
}

// ============================================================
// SHIP INFO PANEL
// ============================================================
class _ShipInfoPanel extends StatelessWidget {
  final String shipId;
  final GameProvider gameProvider;
  final VoidCallback onClose;
  final void Function(String) onNavigate;

  const _ShipInfoPanel({
    required this.shipId,
    required this.gameProvider,
    required this.onClose,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final ship = gameProvider.myShips.where((s) => s.id == shipId).firstOrNull;
    if (ship == null) return const SizedBox.shrink();

    final shipType = GameConstants.findShipType(ship.shipTypeId);
    final activeVoyage = gameProvider.myVoyages
        .where((v) => v.shipId == shipId && v.isActive)
        .firstOrNull;

    final statusColor = switch (ship.status) {
      'in_transit' => AppTheme.warningAmber,
      'idle' => AppTheme.profitGreen,
      _ => AppTheme.textGray,
    };
    final statusText = switch (ship.status) {
      'in_transit' => 'В пути',
      'idle' => 'Стоит',
      'in_dock' => 'В доке',
      'maintenance' => 'Ремонт',
      'on_market' => 'На рынке',
      _ => ship.status,
    };

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.directions_boat, color: statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ship.name, style: AppTheme.labelMedium),
                      Text(shipType?.name ?? ship.shipTypeId, style: AppTheme.bodyTextSmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textGray, size: 18),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Status badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(statusText, style: AppTheme.bodyTextSmall.copyWith(color: statusColor)),
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Состояние', value: '${ship.condition}%'),
                _InfoRow(label: 'Топливо', value: '${ship.fuelLevel.toStringAsFixed(0)}'),
                if (shipType != null)
                  _InfoRow(label: 'Скорость', value: '${shipType.speed} уз.'),
              ],
            ),
          ),

          // Voyage info
          if (activeVoyage != null) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Divider(height: 1, color: AppTheme.dividerColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Активный рейс', style: AppTheme.labelSmall),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: activeVoyage.progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppTheme.inputBackground,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(activeVoyage.progress * 100).toStringAsFixed(0)}% пройдено',
                    style: AppTheme.monoNumberSmall,
                  ),
                ],
              ),
            ),
          ],

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: ElevatedButton(
              onPressed: () => onNavigate('/fleet/$shipId'),
              child: const Text('Открыть корабль'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOTTOM STATS BAR
// ============================================================
class _BottomStatsBar extends StatelessWidget {
  final GameProvider gameProvider;

  const _BottomStatsBar({required this.gameProvider});

  @override
  Widget build(BuildContext context) {
    final idle = gameProvider.myShips.where((s) => s.status == 'idle').length;
    final transit = gameProvider.myShips.where((s) => s.status == 'in_transit').length;
    final activeV = gameProvider.myVoyages.where((v) => v.isActive).length;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: AppTheme.dividerColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatChip(icon: Icons.directions_boat, label: 'Всего: ${gameProvider.myShips.length}', color: AppTheme.accentBlue),
          const SizedBox(width: 20),
          _StatChip(icon: Icons.check_circle, label: 'Свободны: $idle', color: AppTheme.profitGreen),
          const SizedBox(width: 20),
          _StatChip(icon: Icons.sailing, label: 'В пути: $transit', color: AppTheme.warningAmber),
          const SizedBox(width: 20),
          _StatChip(icon: Icons.route, label: 'Рейсы: $activeV', color: AppTheme.accentBlue),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.bodyTextSmall.copyWith(color: AppTheme.textGrayLight)),
      ],
    );
  }
}
