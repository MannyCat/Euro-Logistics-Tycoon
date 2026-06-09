import 'package:latlong2/latlong.dart';

/// Represents a ferry route connection between two cities across water.
///
/// Ferry routes are visually distinct from regular roads on the map
/// (dashed cyan lines) and incur additional cost and time penalties.
class FerryRoute {
  final int fromCityId;
  final int toCityId;
  final String name;
  final String operator;
  final double distanceKm;
  final int costEur; // ferry ticket cost per truck
  final int durationMinutes; // base crossing time
  final List<LatLng> waypoints; // curved route across water
  final String seaName; // which sea / body of water

  const FerryRoute({
    required this.fromCityId,
    required this.toCityId,
    required this.name,
    required this.operator,
    required this.distanceKm,
    required this.costEur,
    required this.durationMinutes,
    required this.waypoints,
    required this.seaName,
  });
}

/// Static configuration and lookup helpers for all ferry routes.
class FerryRoutes {
  FerryRoutes._();

  /// All defined ferry routes in the game.
  static const List<FerryRoute> all = [
    // ── Dublin (22) ↔ London (1) — Irish Sea Express ──
    FerryRoute(
      fromCityId: 22,
      toCityId: 1,
      name: 'Irish Sea Express',
      operator: 'Stena Line',
      distanceKm: 300,
      costEur: 800,
      durationMinutes: 180,
      seaName: 'Irish Sea',
      waypoints: [
        LatLng(53.35, -6.26), // Dublin
        LatLng(53.0, -5.8),
        LatLng(52.6, -5.5),
        LatLng(52.2, -5.2),
        LatLng(51.8, -4.5),
        LatLng(51.5, -3.5),
        LatLng(51.5, -2.0),
        LatLng(51.5, -0.12), // London
      ],
    ),

    // ── Helsinki (27) ↔ Stockholm (14) — Baltic Ferry ──
    FerryRoute(
      fromCityId: 27,
      toCityId: 14,
      name: 'Baltic Ferry',
      operator: 'Viking Line',
      distanceKm: 280,
      costEur: 700,
      durationMinutes: 240,
      seaName: 'Baltic Sea',
      waypoints: [
        LatLng(60.17, 24.94), // Helsinki
        LatLng(60.1, 24.0),
        LatLng(59.8, 23.5),
        LatLng(59.5, 22.5),
        LatLng(59.2, 21.5),
        LatLng(59.0, 20.5),
        LatLng(58.8, 19.5),
        LatLng(58.7, 18.5),
        LatLng(58.9, 18.0),
        LatLng(59.2, 18.1),
        LatLng(59.33, 18.07), // Stockholm
      ],
    ),

    // ── Athens (28) ↔ Istanbul (29) — Aegean Ferry ──
    FerryRoute(
      fromCityId: 28,
      toCityId: 29,
      name: 'Aegean Ferry',
      operator: 'GNM Ferries',
      distanceKm: 350,
      costEur: 900,
      durationMinutes: 300,
      seaName: 'Aegean Sea',
      waypoints: [
        LatLng(37.98, 23.73), // Athens
        LatLng(38.2, 24.2),
        LatLng(38.6, 25.0),
        LatLng(39.0, 25.8),
        LatLng(39.4, 26.2),
        LatLng(39.8, 26.8),
        LatLng(40.2, 27.5),
        LatLng(40.6, 28.2),
        LatLng(41.01, 28.98), // Istanbul
      ],
    ),
  ];

  /// Lookup a ferry route by city pair (either direction).
  /// Returns null if no ferry route exists between the two cities.
  static FerryRoute? getFerryRoute(int cityA, int cityB) {
    for (final r in all) {
      if ((r.fromCityId == cityA && r.toCityId == cityB) ||
          (r.fromCityId == cityB && r.toCityId == cityA)) {
        return r;
      }
    }
    return null;
  }

  /// Check if a road edge between two cities is a ferry route.
  static bool isFerryRoute(int cityA, int cityB) {
    return getFerryRoute(cityA, cityB) != null;
  }

  /// Set of all city IDs that have ferry port connections.
  static Set<int> get portCityIds {
    final ids = <int>{};
    for (final r in all) {
      ids.add(r.fromCityId);
      ids.add(r.toCityId);
    }
    return ids;
  }

  /// Get all ferry routes departing from or arriving at a given city.
  static List<FerryRoute> routesForCity(int cityId) {
    return all.where((r) =>
      r.fromCityId == cityId || r.toCityId == cityId
    ).toList();
  }

  /// Calculate total ferry cost for a given path.
  static int getFerryCost(List<int> path) {
    int total = 0;
    for (int i = 0; i < path.length - 1; i++) {
      final route = getFerryRoute(path[i], path[i + 1]);
      if (route != null) total += route.costEur;
    }
    return total;
  }

  /// Calculate total ferry duration (minutes) for a given path.
  static int getFerryDuration(List<int> path) {
    int total = 0;
    for (int i = 0; i < path.length - 1; i++) {
      final route = getFerryRoute(path[i], path[i + 1]);
      if (route != null) total += route.durationMinutes;
    }
    return total;
  }

  /// Check if any segment in a path is a ferry.
  static bool pathHasFerry(List<int> path) {
    for (int i = 0; i < path.length - 1; i++) {
      if (isFerryRoute(path[i], path[i + 1])) return true;
    }
    return false;
  }

  /// Get all ferry route segments in a path with their details.
  static List<FerryRoute> ferrySegmentsInPath(List<int> path) {
    final segments = <FerryRoute>[];
    for (int i = 0; i < path.length - 1; i++) {
      final route = getFerryRoute(path[i], path[i + 1]);
      if (route != null) segments.add(route);
    }
    return segments;
  }
}
