import 'dart:math' as math;
import 'dart:collection';
import '../models/city.dart';
import '../config/ferry_routes.dart';

class PathResult {
  final List<int> cityIds;
  final double totalDistanceKm;
  final double estimatedTimeHours;

  const PathResult({
    required this.cityIds,
    required this.totalDistanceKm,
    required this.estimatedTimeHours,
  });
}

class PathFinder {
  static const List<List<int>> roadNetwork = [
    // ─── Original 15 cities ───
    [1, 5], [1, 4], [1, 2],       // London↔Brussels, London↔Amsterdam, London↔Paris
    [2, 5], [2, 8], [2, 6], [2, 7], // Paris↔Brussels, Paris↔Madrid, Paris↔Frankfurt, Paris↔Zurich
    [4, 5], [4, 3],                 // Amsterdam↔Brussels, Amsterdam↔Berlin
    [5, 6],                          // Brussels↔Frankfurt
    [6, 3], [6, 7], [6, 12],        // Frankfurt↔Berlin, Frankfurt↔Zurich, Frankfurt↔Prague
    [7, 9], [7, 11],                // Zurich↔Rome, Zurich↔Vienna
    [12, 11], [12, 10], [12, 3],    // Prague↔Vienna, Prague↔Warsaw, Prague↔Berlin
    [11, 13],                        // Vienna↔Budapest
    [10, 3], [10, 13],              // Warsaw↔Berlin, Warsaw↔Budapest
    [15, 14], [14, 10],              // Oslo↔Stockholm, Stockholm↔Warsaw
    [8, 9], [13, 9],                // Madrid↔Rome, Budapest↔Rome
    // ─── New cities (16-30) ───
    [16, 3], [16, 4], [16, 21],     // Hamburg↔Berlin, Hamburg↔Amsterdam, Hamburg↔Copenhagen
    [17, 6], [17, 7], [17, 11], [17, 12], // Munich↔Frankfurt, Munich↔Zurich, Munich↔Vienna, Munich↔Prague
    [18, 2], [18, 30], [18, 7],     // Lyon↔Paris, Lyon↔Marseille, Lyon↔Zurich
    [19, 8], [19, 30],              // Barcelona↔Madrid, Barcelona↔Marseille
    [20, 9], [20, 7], [20, 17],     // Milan↔Rome, Milan↔Zurich, Milan↔Munich
    [21, 16], [21, 14],             // Copenhagen↔Hamburg, Copenhagen↔Stockholm
    [22, 1],                         // Dublin↔London (ferry)
    [23, 13], [23, 24], [23, 25],    // Bucharest↔Budapest, Bucharest↔Sofia, Bucharest↔Belgrade
    [24, 25], [24, 28],              // Sofia↔Belgrade, Sofia↔Athens
    [25, 13], [25, 26],              // Belgrade↔Budapest, Belgrade↔Zagreb
    [26, 11], [26, 13],              // Zagreb↔Vienna, Zagreb↔Budapest
    [27, 14],                        // Helsinki↔Stockholm (ferry)
    [28, 24], [28, 29],              // Athens↔Sofia, Athens↔Istanbul
    [29, 23],                        // Istanbul↔Bucharest
  ];

  /// Build adjacency list from the road network (bidirectional).
  static Map<int, List<int>> buildAdjacency() {
    final adj = <int, List<int>>{};
    for (final pair in roadNetwork) {
      final a = pair[0];
      final b = pair[1];
      adj.putIfAbsent(a, () => <int>[]).add(b);
      adj.putIfAbsent(b, () => <int>[]).add(a);
    }
    return adj;
  }

  /// BFS shortest path by number of hops. Returns ordered list of city IDs
  /// from [fromCityId] to [toCityId], or empty list if no path exists.
  static List<int> findPath(int fromCityId, int toCityId) {
    if (fromCityId == toCityId) return [fromCityId];
    final adj = buildAdjacency();
    final visited = <int>{fromCityId};
    final queue = Queue<List<int>>();
    queue.add([fromCityId]);

    while (queue.isNotEmpty) {
      final path = queue.removeFirst();
      final current = path.last;
      final neighbors = adj[current];
      if (neighbors == null) continue;
      for (final next in neighbors) {
        if (next == toCityId) {
          return [...path, toCityId];
        }
        if (!visited.contains(next)) {
          visited.add(next);
          queue.add([...path, next]);
        }
      }
    }
    // No path found — cities are disconnected
    return [];
  }

  /// Haversine distance between two coordinates in km.
  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Calculate the total haversine distance (km) of a path through cities.
  /// Uses ferry route distance when an edge is a ferry connection.
  static double pathDistanceKm(List<City> cities, List<int> path) {
    final cityMap = <int, City>{};
    for (final c in cities) {
      cityMap[c.id] = c;
    }
    double total = 0;
    for (int i = 0; i < path.length - 1; i++) {
      // Use ferry distance if this segment is a ferry
      final ferry = FerryRoutes.getFerryRoute(path[i], path[i + 1]);
      if (ferry != null) {
        total += ferry.distanceKm;
        continue;
      }
      final a = cityMap[path[i]];
      final b = cityMap[path[i + 1]];
      if (a != null && b != null) {
        total += _haversineKm(a.latitude, a.longitude, b.latitude, b.longitude);
      }
    }
    return total;
  }

  /// Full pathfinding result: path, distance, estimated time.
  /// Ferry segments use their defined duration (ferry speed) instead of truck speed.
  static PathResult findRoute(List<City> cities, int fromCityId, int toCityId,
      {double avgSpeedKmh = 80}) {
    final path = findPath(fromCityId, toCityId);
    if (path.isEmpty) {
      return const PathResult(
        cityIds: [],
        totalDistanceKm: 0,
        estimatedTimeHours: 0,
      );
    }
    final dist = pathDistanceKm(cities, path);

    // Calculate time: road segments use truck speed, ferry segments use ferry duration
    final cityMap = <int, City>{};
    for (final c in cities) { cityMap[c.id] = c; }
    double totalTimeHours = 0;
    for (int i = 0; i < path.length - 1; i++) {
      final ferry = FerryRoutes.getFerryRoute(path[i], path[i + 1]);
      if (ferry != null) {
        totalTimeHours += ferry.durationMinutes / 60.0;
      } else {
        final a = cityMap[path[i]];
        final b = cityMap[path[i + 1]];
        if (a != null && b != null) {
          final segDist = _haversineKm(a.latitude, a.longitude, b.latitude, b.longitude);
          totalTimeHours += segDist / avgSpeedKmh;
        }
      }
    }

    return PathResult(
      cityIds: path,
      totalDistanceKm: dist,
      estimatedTimeHours: totalTimeHours,
    );
  }

  /// Interpolate position along a multi-segment route at the given progress [0.0 – 1.0].
  /// Returns (latitude, longitude) at the interpolated point.
  /// If progress is out of bounds, clamps to [0, 1].
  /// Ferry segments interpolate along their curved waypoints instead of straight lines.
  static (double lat, double lng) interpolateAlongPath(
    List<City> cities,
    List<int> path,
    double progress,
  ) {
    final cityMap = <int, City>{};
    for (final c in cities) {
      cityMap[c.id] = c;
    }

    if (path.length < 2) {
      final city = cityMap[path.isNotEmpty ? path.first : 0];
      return (city?.latitude ?? 50.0, city?.longitude ?? 10.0);
    }

    // 1. Compute segment distances (ferry segments use waypoint polyline distance)
    final segDistances = <double>[];
    for (int i = 0; i < path.length - 1; i++) {
      final ferry = FerryRoutes.getFerryRoute(path[i], path[i + 1]);
      if (ferry != null && ferry.waypoints.length >= 2) {
        // Sum waypoint-to-waypoint haversine distances
        double ferryDist = 0;
        for (int j = 0; j < ferry.waypoints.length - 1; j++) {
          ferryDist += _haversineKm(
            ferry.waypoints[j].latitude, ferry.waypoints[j].longitude,
            ferry.waypoints[j + 1].latitude, ferry.waypoints[j + 1].longitude,
          );
        }
        segDistances.add(ferryDist);
      } else {
        final a = cityMap[path[i]];
        final b = cityMap[path[i + 1]];
        if (a != null && b != null) {
          segDistances.add(_haversineKm(a.latitude, a.longitude, b.latitude, b.longitude));
        } else {
          segDistances.add(0);
        }
      }
    }

    final totalDist = segDistances.fold(0.0, (sum, d) => sum + d);
    if (totalDist <= 0) {
      final city = cityMap[path.first];
      return (city?.latitude ?? 50.0, city?.longitude ?? 10.0);
    }

    // 2. Clamp progress
    final t = progress.clamp(0.0, 1.0);
    final targetDist = t * totalDist;

    // 3. Find which segment the target distance falls on
    double accum = 0;
    for (int i = 0; i < segDistances.length; i++) {
      final segLen = segDistances[i];
      if (accum + segLen >= targetDist - 1e-9) {
        // We're on segment i
        final segProgress =
            segLen > 0 ? (targetDist - accum) / segLen : 0.0;

        // For ferry segments, interpolate along waypoints
        final ferry = FerryRoutes.getFerryRoute(path[i], path[i + 1]);
        if (ferry != null && ferry.waypoints.length >= 2) {
          return _interpolateAlongWaypoints(ferry.waypoints, segProgress);
        }

        // For road segments, interpolate directly between cities
        final a = cityMap[path[i]];
        final b = cityMap[path[i + 1]];
        if (a != null && b != null) {
          final lat = a.latitude + (b.latitude - a.latitude) * segProgress;
          final lng = a.longitude + (b.longitude - a.longitude) * segProgress;
          return (lat, lng);
        }
        break;
      }
      accum += segLen;
    }

    // Fallback: return last city
    final lastCity = cityMap[path.last];
    return (lastCity?.latitude ?? 50.0, lastCity?.longitude ?? 10.0);
  }

  /// Interpolate along a list of waypoints at the given progress [0.0 – 1.0].
  static (double lat, double lng) _interpolateAlongWaypoints(
    List<LatLng> waypoints, double progress,
  ) {
    if (waypoints.length < 2) {
      final p = waypoints.first;
      return (p.latitude, p.longitude);
    }

    // Build cumulative distance array
    final dists = <double>[0];
    for (int i = 1; i < waypoints.length; i++) {
      final prev = waypoints[i - 1];
      final curr = waypoints[i];
      dists.add(dists.last + _haversineKm(
        prev.latitude, prev.longitude,
        curr.latitude, curr.longitude,
      ));
    }

    final total = dists.last;
    if (total <= 0) return (waypoints.first.latitude, waypoints.first.longitude);

    final target = (progress.clamp(0.0, 1.0) * total);

    for (int i = 1; i < dists.length; i++) {
      if (dists[i] >= target - 1e-9) {
        final segLen = dists[i] - dists[i - 1];
        final segProg = segLen > 0 ? (target - dists[i - 1]) / segLen : 0.0;
        final prev = waypoints[i - 1];
        final curr = waypoints[i];
        return (
          prev.latitude + (curr.latitude - prev.latitude) * segProg,
          prev.longitude + (curr.longitude - prev.longitude) * segProg,
        );
      }
    }

    final last = waypoints.last;
    return (last.latitude, last.longitude);
  }

  /// Check if an edge between two city IDs is a ferry route.
  static bool isFerryEdge(int a, int b) {
    return FerryRoutes.isFerryRoute(a, b);
  }

  /// Get ferry route data for an edge, or null if not a ferry.
  static FerryRoute? getFerryEdge(int a, int b) {
    return FerryRoutes.getFerryRoute(a, b);
  }

  /// Find the segment index along the path at a given progress [0.0 – 1.0].
  /// Used for splitting route polylines into "traveled" and "remaining" portions.
  /// Returns the index of the segment the truck is currently on.
  static int findSegmentIndex(
    List<City> cities,
    List<int> path,
    double progress,
  ) {
    final cityMap = <int, City>{};
    for (final c in cities) {
      cityMap[c.id] = c;
    }

    if (path.length < 2) return 0;

    final segDistances = <double>[];
    for (int i = 0; i < path.length - 1; i++) {
      final a = cityMap[path[i]];
      final b = cityMap[path[i + 1]];
      if (a != null && b != null) {
        segDistances.add(_haversineKm(a.latitude, a.longitude, b.latitude, b.longitude));
      } else {
        segDistances.add(0);
      }
    }

    final totalDist = segDistances.fold(0.0, (sum, d) => sum + d);
    if (totalDist <= 0) return 0;

    final t = progress.clamp(0.0, 1.0);
    final targetDist = t * totalDist;

    double accum = 0;
    for (int i = 0; i < segDistances.length; i++) {
      if (accum + segDistances[i] >= targetDist - 1e-9) {
        return i;
      }
      accum += segDistances[i];
    }

    return segDistances.length - 1;
  }
}
