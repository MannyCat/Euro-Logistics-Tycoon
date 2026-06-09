import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Comprehensive world boundary data for the game map.
///
/// Contains simplified but recognizable polygon outlines for all major
/// landmasses, continents, and countries. Polygons are intentionally
/// simplified (8-25 vertices per country) for performance on Canvas,
/// while still being clearly identifiable at typical zoom levels.
///
/// Usage:
///   - WorldBoundaries.allLandmasses — all continent/country polygons
///   - WorldBoundaries.oceanPolygons    — ocean/water bodies for background
///   - WorldBoundaries.worldCities     — major world cities as landmarks
///   - WorldBoundaries.gridLines       — lat/lng grid for zoomed-out views
///
/// Design: Dark theme ocean (#0D1117) and landmass (#1A1A1A) base colors
/// with per-region tinting. No gradients — flat colors only.

class WorldBoundaries {
  WorldBoundaries._();

  // ══════════════════════════════════════════════════════════════════════
  // CONTINENT / LANDMASS POLYGONS
  // ══════════════════════════════════════════════════════════════════════

  /// All drawable landmass polygons grouped by region.
  static List<LandmassPolygon> get allLandmasses => [
        ..._europe,
        ..._asia,
        ..._africa,
        ..._northAmerica,
        ..._southAmerica,
        ..._oceania,
        ..._antarctica,
      ];

  // ─── EUROPE ──────────────────────────────────────────────────────────

  static const List<LandmassPolygon> _europe = [
    // Nordic countries combined mass (Scandinavia + Finland)
    LandmassPolygon(
      name: 'scandinavia',
      vertices: [
        LatLng(55.5, 12.8), LatLng(56.8, 14.2), LatLng(59.0, 18.0),
        LatLng(60.5, 18.5), LatLng(64.0, 20.0), LatLng(69.1, 20.0),
        LatLng(71.2, 26.0), LatLng(70.0, 28.0), LatLng(70.1, 28.0),
        LatLng(69.6, 20.0), LatLng(66.0, 14.0), LatLng(63.5, 11.5),
        LatLng(62.0, 5.8), LatLng(59.0, 5.3), LatLng(57.9, 7.5),
        LatLng(58.8, 8.7), LatLng(59.0, 11.2),
      ],
      color: 0xFF1B2538,
    ),

    // British Isles
    LandmassPolygon(
      name: 'british_isles',
      vertices: [
        LatLng(50.6, -3.5), LatLng(51.5, -0.5), LatLng(52.5, 1.8),
        LatLng(55.5, 1.3), LatLng(57.5, -1.8), LatLng(58.6, -3.2),
        LatLng(56.5, -6.0), LatLng(55.3, -5.8), LatLng(54.5, -5.5),
        LatLng(53.5, -3.0), LatLng(51.5, -5.0),
      ],
      color: 0xFF1B2833,
    ),

    // Ireland
    LandmassPolygon(
      name: 'ireland',
      vertices: [
        LatLng(52.0, -10.5), LatLng(53.5, -6.0), LatLng(55.3, -6.0),
        LatLng(55.4, -7.0), LatLng(54.3, -10.0), LatLng(51.4, -10.3),
      ],
      color: 0xFF1C2535,
    ),

    // Iceland
    LandmassPolygon(
      name: 'iceland',
      vertices: [
        LatLng(63.4, -22.0), LatLng(66.5, -18.0), LatLng(66.5, -14.0),
        LatLng(64.0, -13.5), LatLng(63.3, -20.0),
      ],
      color: 0xFF1A2530,
    ),

    // Western Europe main mass (France, Benelux, Germany, Switzerland, Austria)
    LandmassPolygon(
      name: 'western_europe',
      vertices: [
        LatLng(36.7, -9.5), LatLng(37.0, -7.9), LatLng(38.7, -9.4),
        LatLng(42.0, -9.3), LatLng(43.6, -7.3), LatLng(43.4, -3.8),
        LatLng(43.8, -1.8), LatLng(42.9, 3.2), LatLng(43.7, 7.0),
        LatLng(46.2, 6.1), LatLng(47.5, 7.0), LatLng(48.6, 7.6),
        LatLng(48.8, 7.6), LatLng(49.0, 6.4), LatLng(50.4, 6.2),
        LatLng(51.8, 6.7), LatLng(53.5, 7.0), LatLng(54.8, 8.6),
        LatLng(55.0, 14.3), LatLng(54.4, 14.8), LatLng(51.0, 15.0),
        LatLng(50.3, 12.2), LatLng(49.6, 22.8), LatLng(49.6, 17.0),
        LatLng(48.9, 16.8), LatLng(48.7, 13.0), LatLng(47.8, 12.6),
        LatLng(47.0, 16.4), LatLng(46.7, 14.0), LatLng(46.6, 10.1),
        LatLng(46.5, 7.9), LatLng(44.1, 10.0), LatLng(43.3, 11.8),
        LatLng(42.0, 14.0), LatLng(41.9, 15.4), LatLng(40.6, 16.5),
        LatLng(39.6, 16.5), LatLng(38.1, 15.6), LatLng(37.5, 15.0),
        LatLng(38.1, 13.0), LatLng(40.0, 15.4), // Italy boot fix - simplified
        LatLng(37.2, -7.4), LatLng(36.7, -4.4), LatLng(36.7, -2.1),
        LatLng(38.0, -0.2), LatLng(40.5, 0.5),
      ],
      color: 0xFF1E2A3A,
    ),

    // Iberian Peninsula (Spain + Portugal)
    LandmassPolygon(
      name: 'iberian_peninsula',
      vertices: [
        LatLng(42.0, -9.3), LatLng(43.6, -7.3), LatLng(43.4, -3.8),
        LatLng(43.8, -1.8), LatLng(42.9, 3.2), LatLng(40.5, 0.5),
        LatLng(38.0, -0.2), LatLng(36.7, -2.1), LatLng(36.7, -4.4),
        LatLng(37.2, -7.4), LatLng(37.0, -7.9), LatLng(38.7, -9.4),
      ],
      color: 0xFF202528,
    ),

    // Italy (boot + Sicily simplified)
    LandmassPolygon(
      name: 'italy',
      vertices: [
        LatLng(46.5, 13.6), LatLng(45.7, 14.6), LatLng(44.2, 12.3),
        LatLng(43.6, 13.0), LatLng(41.9, 15.4), LatLng(40.6, 16.5),
        LatLng(39.6, 16.5), LatLng(38.1, 15.6), LatLng(37.5, 15.0),
        LatLng(38.1, 13.0), LatLng(42.0, 14.0), LatLng(43.3, 11.8),
        LatLng(44.1, 10.0), LatLng(46.0, 8.3), LatLng(46.5, 11.0),
      ],
      color: 0xFF1F2530,
    ),

    // Eastern Europe (Poland, Czech, Slovakia, Hungary, Romania, Bulgaria, Balkans)
    LandmassPolygon(
      name: 'eastern_europe',
      vertices: [
        LatLng(54.4, 14.8), LatLng(55.0, 14.3), LatLng(54.5, 14.3),
        LatLng(54.6, 18.5), LatLng(54.4, 24.1), LatLng(51.3, 23.5),
        LatLng(49.5, 22.8), LatLng(49.6, 17.0), LatLng(51.1, 18.3),
        LatLng(51.1, 12.4), LatLng(50.2, 12.2), LatLng(50.3, 12.2),
        LatLng(48.9, 16.8), LatLng(47.0, 16.4), LatLng(46.7, 14.0),
        LatLng(46.6, 16.2), LatLng(45.7, 18.3), LatLng(45.9, 16.3),
        LatLng(46.0, 21.0), LatLng(47.8, 22.0), LatLng(47.5, 27.0),
        LatLng(48.3, 26.0), LatLng(48.3, 22.0), LatLng(44.0, 28.5),
        LatLng(43.6, 24.0), LatLng(44.2, 22.5), LatLng(45.5, 22.0),
        LatLng(47.0, 22.0), LatLng(48.6, 17.2), LatLng(48.1, 20.0),
        LatLng(48.6, 17.2),
      ],
      color: 0xFF1D2638,
    ),

    // Balkans / Greece
    LandmassPolygon(
      name: 'balkans',
      vertices: [
        LatLng(46.0, 21.0), LatLng(47.8, 22.0), LatLng(47.5, 27.0),
        LatLng(45.5, 30.0), LatLng(42.0, 28.0), LatLng(40.0, 26.0),
        LatLng(38.0, 24.0), LatLng(36.0, 22.0), LatLng(37.0, 20.0),
        LatLng(38.5, 20.5), LatLng(40.0, 22.0), LatLng(41.0, 23.0),
        LatLng(42.5, 21.5), LatLng(44.0, 20.0), LatLng(44.5, 18.0),
        LatLng(45.7, 18.3), LatLng(46.0, 21.0),
      ],
      color: 0xFF1E2830,
    ),

    // Baltic States (Estonia, Latvia, Lithuania)
    LandmassPolygon(
      name: 'baltic_states',
      vertices: [
        LatLng(57.5, 22.0), LatLng(59.5, 28.0), LatLng(58.0, 28.0),
        LatLng(56.5, 24.0), LatLng(54.0, 22.0), LatLng(54.4, 21.0),
        LatLng(56.0, 21.0),
      ],
      color: 0xFF1C2835,
    ),
  ];

  // ─── ASIA ───────────────────────────────────────────────────────────

  static const List<LandmassPolygon> _asia = [
    // Russia (massive - simplified outline)
    LandmassPolygon(
      name: 'russia',
      vertices: [
        LatLng(55.0, 27.0), LatLng(60.0, 30.0), LatLng(65.0, 30.0),
        LatLng(70.0, 40.0), LatLng(70.0, 140.0), LatLng(66.0, 170.0),
        LatLng(64.0, 180.0), LatLng(60.0, 165.0), LatLng(55.0, 160.0),
        LatLng(50.0, 155.0), LatLng(45.0, 140.0), LatLng(44.0, 132.0),
        LatLng(48.0, 135.0), LatLng(50.0, 130.0), LatLng(52.0, 120.0),
        LatLng(55.0, 115.0), LatLng(53.0, 105.0), LatLng(50.0, 90.0),
        LatLng(50.0, 75.0), LatLng(55.0, 65.0), LatLng(50.0, 55.0),
        LatLng(45.0, 50.0), LatLng(42.0, 45.0), LatLng(44.0, 40.0),
        LatLng(47.0, 40.0), LatLng(50.0, 40.0),
      ],
      color: 0xFF1A2530,
    ),

    // Turkey / Anatolia
    LandmassPolygon(
      name: 'turkey',
      vertices: [
        LatLng(42.0, 27.0), LatLng(42.0, 44.0), LatLng(40.0, 44.0),
        LatLng(37.0, 36.0), LatLng(36.0, 30.0), LatLng(36.5, 28.0),
        LatLng(38.0, 26.0), LatLng(39.0, 27.0), LatLng(40.5, 30.0),
        LatLng(41.0, 29.0),
      ],
      color: 0xFF1E2835,
    ),

    // Middle East (Arabian Peninsula, Iraq, Iran)
    LandmassPolygon(
      name: 'middle_east',
      vertices: [
        LatLng(33.0, 35.0), LatLng(37.0, 36.0), LatLng(37.0, 44.0),
        LatLng(40.0, 44.0), LatLng(42.0, 50.0), LatLng(37.0, 56.0),
        LatLng(25.0, 56.0), LatLng(22.0, 55.0), LatLng(15.0, 45.0),
        LatLng(12.5, 44.0), LatLng(14.5, 43.0), LatLng(17.0, 42.0),
        LatLng(20.0, 40.0), LatLng(22.0, 36.0), LatLng(28.0, 34.0),
        LatLng(30.0, 33.0), LatLng(31.0, 35.0),
      ],
      color: 0xFF1F2530,
    ),

    // Central Asia (Kazakhstan, etc.)
    LandmassPolygon(
      name: 'central_asia',
      vertices: [
        LatLng(55.0, 50.0), LatLng(50.0, 55.0), LatLng(45.0, 50.0),
        LatLng(42.0, 50.0), LatLng(40.0, 52.0), LatLng(37.0, 56.0),
        LatLng(35.0, 60.0), LatLng(37.0, 65.0), LatLng(40.0, 68.0),
        LatLng(42.0, 70.0), LatLng(44.0, 75.0), LatLng(45.0, 80.0),
        LatLng(50.0, 80.0), LatLng(52.0, 78.0), LatLng(55.0, 70.0),
      ],
      color: 0xFF1C2635,
    ),

    // India + Sri Lanka
    LandmassPolygon(
      name: 'india',
      vertices: [
        LatLng(35.0, 72.0), LatLng(37.0, 78.0), LatLng(35.0, 85.0),
        LatLng(28.0, 97.0), LatLng(22.0, 97.0), LatLng(20.0, 93.0),
        LatLng(16.0, 82.0), LatLng(8.0, 77.0), LatLng(8.0, 73.0),
        LatLng(12.0, 75.0), LatLng(15.0, 74.0), LatLng(20.0, 73.0),
        LatLng(24.0, 68.0), LatLng(25.0, 62.0), LatLng(28.0, 62.0),
        LatLng(30.0, 67.0), LatLng(33.0, 70.0),
      ],
      color: 0xFF1E2838,
    ),

    // China (simplified)
    LandmassPolygon(
      name: 'china',
      vertices: [
        LatLng(50.0, 80.0), LatLng(52.0, 78.0), LatLng(55.0, 70.0),
        LatLng(55.0, 65.0), LatLng(50.0, 75.0), LatLng(48.0, 87.0),
        LatLng(50.0, 90.0), LatLng(52.0, 100.0), LatLng(48.0, 105.0),
        LatLng(45.0, 110.0), LatLng(40.0, 115.0), LatLng(38.0, 120.0),
        LatLng(35.0, 120.0), LatLng(30.0, 122.0), LatLng(25.0, 110.0),
        LatLng(22.0, 108.0), LatLng(22.0, 100.0), LatLng(28.0, 97.0),
        LatLng(35.0, 85.0), LatLng(37.0, 78.0), LatLng(40.0, 76.0),
        LatLng(42.0, 80.0), LatLng(45.0, 80.0),
      ],
      color: 0xFF1A2838,
    ),

    // Japan (main islands simplified)
    LandmassPolygon(
      name: 'japan',
      vertices: [
        LatLng(45.0, 142.0), LatLng(43.0, 145.0), LatLng(40.0, 140.0),
        LatLng(36.0, 140.0), LatLng(34.0, 132.0), LatLng(33.0, 130.0),
        LatLng(35.0, 136.0), LatLng(38.0, 139.0), LatLng(40.0, 140.0),
      ],
      color: 0xFF1C2535,
    ),

    // Korean Peninsula
    LandmassPolygon(
      name: 'korea',
      vertices: [
        LatLng(43.0, 130.0), LatLng(40.0, 128.0), LatLng(37.0, 127.0),
        LatLng(35.0, 129.0), LatLng(34.5, 126.0), LatLng(36.0, 126.0),
        LatLng(38.0, 128.0),
      ],
      color: 0xFF1D2630,
    ),

    // Southeast Asia mainland
    LandmassPolygon(
      name: 'southeast_asia_mainland',
      vertices: [
        LatLng(22.0, 100.0), LatLng(22.0, 108.0), LatLng(18.0, 107.0),
        LatLng(16.0, 108.0), LatLng(14.0, 109.0), LatLng(10.0, 108.0),
        LatLng(8.0, 105.0), LatLng(6.0, 103.0), LatLng(2.0, 104.0),
        LatLng(1.0, 103.0), LatLng(3.0, 100.0), LatLng(6.0, 100.0),
        LatLng(10.0, 98.0), LatLng(14.0, 99.0), LatLng(18.0, 97.0),
        LatLng(20.0, 97.0), LatLng(22.0, 97.0),
      ],
      color: 0xFF1F2835,
    ),

    // Indonesia archipelago (Sumatra simplified)
    LandmassPolygon(
      name: 'sumatra',
      vertices: [
        LatLng(5.0, 95.0), LatLng(5.0, 98.0), LatLng(2.0, 102.0),
        LatLng(-2.0, 104.0), LatLng(-5.0, 105.0), LatLng(-6.0, 103.0),
        LatLng(-4.0, 100.0), LatLng(-1.0, 98.0), LatLng(2.0, 96.0),
      ],
      color: 0xFF1D2530,
    ),

    // Borneo
    LandmassPolygon(
      name: 'borneo',
      vertices: [
        LatLng(7.0, 117.0), LatLng(5.0, 119.0), LatLng(2.0, 118.0),
        LatLng(0.0, 117.0), LatLng(-2.0, 115.0), LatLng(-3.0, 110.0),
        LatLng(-1.0, 109.0), LatLng(1.0, 109.0), LatLng(4.0, 108.0),
        LatLng(6.0, 112.0),
      ],
      color: 0xFF1E2730,
    ),

    // Philippines (Luzon + Mindanao simplified)
    LandmassPolygon(
      name: 'philippines',
      vertices: [
        LatLng(18.0, 120.0), LatLng(16.0, 121.0), LatLng(14.0, 121.0),
        LatLng(12.0, 124.0), LatLng(10.0, 124.0), LatLng(8.0, 126.0),
        LatLng(7.0, 126.0), LatLng(7.0, 124.0), LatLng(9.0, 122.0),
        LatLng(11.0, 120.0), LatLng(14.0, 120.0), LatLng(16.0, 120.0),
      ],
      color: 0xFF1C2830,
    ),

    // Taiwan
    LandmassPolygon(
      name: 'taiwan',
      vertices: [
        LatLng(25.0, 121.0), LatLng(24.0, 122.0), LatLng(22.5, 121.0),
        LatLng(22.0, 120.0), LatLng(23.5, 120.0),
      ],
      color: 0xFF1D2535,
    ),

    // Sri Lanka
    LandmassPolygon(
      name: 'sri_lanka',
      vertices: [
        LatLng(10.0, 80.0), LatLng(8.0, 82.0), LatLng(6.0, 81.0),
        LatLng(7.0, 80.0),
      ],
      color: 0xFF1E2630,
    ),

    // Pakistan
    LandmassPolygon(
      name: 'pakistan',
      vertices: [
        LatLng(37.0, 70.0), LatLng(36.0, 74.0), LatLng(35.0, 77.0),
        LatLng(28.0, 70.0), LatLng(25.0, 63.0), LatLng(25.0, 62.0),
        LatLng(30.0, 67.0), LatLng(33.0, 70.0),
      ],
      color: 0xFF1C2638,
    ),

    // Afghanistan
    LandmassPolygon(
      name: 'afghanistan',
      vertices: [
        LatLng(37.0, 65.0), LatLng(37.0, 72.0), LatLng(35.0, 72.0),
        LatLng(30.0, 67.0), LatLng(29.0, 64.0), LatLng(33.0, 63.0),
        LatLng(37.0, 65.0),
      ],
      color: 0xFF1D2835,
    ),

    // Mongolia
    LandmassPolygon(
      name: 'mongolia',
      vertices: [
        LatLng(52.0, 90.0), LatLng(50.0, 97.0), LatLng(47.0, 105.0),
        LatLng(50.0, 115.0), LatLng(52.0, 110.0), LatLng(52.0, 100.0),
      ],
      color: 0xFF1E2538,
    ),

    // Nepal + Bhutan
    LandmassPolygon(
      name: 'nepal_bhutan',
      vertices: [
        LatLng(30.0, 80.0), LatLng(28.0, 82.0), LatLng(27.0, 88.0),
        LatLng(28.0, 92.0),
      ],
      color: 0xFF1C2530,
    ),

    // Myanmar
    LandmassPolygon(
      name: 'myanmar',
      vertices: [
        LatLng(28.0, 92.0), LatLng(26.0, 98.0), LatLng(22.0, 98.0),
        LatLng(18.0, 97.0), LatLng(14.0, 98.0), LatLng(16.0, 96.0),
        LatLng(20.0, 93.0), LatLng(22.0, 93.0),
      ],
      color: 0xFF1F2735,
    ),

    // Thailand
    LandmassPolygon(
      name: 'thailand',
      vertices: [
        LatLng(20.0, 97.0), LatLng(18.0, 103.0), LatLng(14.0, 100.0),
        LatLng(10.0, 99.0), LatLng(8.0, 100.0), LatLng(10.0, 98.0),
        LatLng(14.0, 99.0),
      ],
      color: 0xFF1D2838,
    ),

    // Vietnam
    LandmassPolygon(
      name: 'vietnam',
      vertices: [
        LatLng(22.0, 108.0), LatLng(18.0, 106.0), LatLng(16.0, 108.0),
        LatLng(12.0, 109.0), LatLng(10.0, 106.0), LatLng(12.0, 104.0),
        LatLng(16.0, 104.0), LatLng(18.0, 105.0),
      ],
      color: 0xFF1E2635,
    ),

    // Papua New Guinea
    LandmassPolygon(
      name: 'papua_new_guinea',
      vertices: [
        LatLng(-2.0, 141.0), LatLng(-5.0, 143.0), LatLng(-8.0, 148.0),
        LatLng(-10.0, 150.0), LatLng(-8.0, 148.0), LatLng(-5.0, 145.0),
        LatLng(-2.0, 142.0),
      ],
      color: 0xFF1C2535,
    ),

    // Java
    LandmassPolygon(
      name: 'java',
      vertices: [
        LatLng(-6.0, 106.0), LatLng(-7.0, 110.0), LatLng(-8.0, 114.0),
        LatLng(-8.5, 115.0), LatLng(-8.0, 114.0), LatLng(-7.0, 110.0),
      ],
      color: 0xFF1D2630,
    ),
  ];

  // ─── AFRICA ───────────────────────────────────────────────────────────

  static const List<LandmassPolygon> _africa = [
    // North Africa (Morocco to Egypt)
    LandmassPolygon(
      name: 'north_africa',
      vertices: [
        LatLng(37.0, -10.0), LatLng(37.0, 11.0), LatLng(33.0, 13.0),
        LatLng(32.0, 25.0), LatLng(31.0, 32.0), LatLng(30.0, 33.0),
        LatLng(22.0, 36.0), LatLng(20.0, 40.0), LatLng(17.0, 42.0),
        LatLng(15.0, 44.0), LatLng(12.5, 44.0), LatLng(12.0, 42.0),
        LatLng(20.0, 16.0), LatLng(23.0, 12.0), LatLng(27.0, 10.0),
        LatLng(32.0, -2.0), LatLng(35.0, -5.0), LatLng(36.0, -5.0),
      ],
      color: 0xFF1D2530,
    ),

    // West Africa
    LandmassPolygon(
      name: 'west_africa',
      vertices: [
        LatLng(15.0, -17.0), LatLng(12.0, -16.0), LatLng(10.0, -14.0),
        LatLng(5.0, -10.0), LatLng(4.0, 2.0), LatLng(6.0, 2.0),
        LatLng(10.0, 1.0), LatLng(12.0, -5.0), LatLng(12.0, -10.0),
        LatLng(15.0, -16.0),
      ],
      color: 0xFF1E2835,
    ),

    // Central Africa
    LandmassPolygon(
      name: 'central_africa',
      vertices: [
        LatLng(12.0, -5.0), LatLng(12.0, 15.0), LatLng(5.0, 20.0),
        LatLng(-5.0, 28.0), LatLng(-10.0, 30.0), LatLng(-12.0, 25.0),
        LatLng(-15.0, 20.0), LatLng(-10.0, 12.0), LatLng(-5.0, 10.0),
        LatLng(0.0, 10.0), LatLng(4.0, 8.0), LatLng(5.0, 2.0),
        LatLng(10.0, 1.0),
      ],
      color: 0xFF1C2635,
    ),

    // East Africa
    LandmassPolygon(
      name: 'east_africa',
      vertices: [
        LatLng(12.0, 42.0), LatLng(15.0, 44.0), LatLng(12.0, 44.0),
        LatLng(12.5, 44.0), LatLng(12.0, 50.0), LatLng(5.0, 50.0),
        LatLng(0.0, 42.0), LatLng(-5.0, 40.0), LatLng(-10.0, 35.0),
        LatLng(-12.0, 30.0), LatLng(-5.0, 28.0), LatLng(5.0, 20.0),
        LatLng(5.0, 32.0), LatLng(10.0, 40.0),
      ],
      color: 0xFF1D2735,
    ),

    // Southern Africa
    LandmassPolygon(
      name: 'southern_africa',
      vertices: [
        LatLng(-5.0, 12.0), LatLng(-10.0, 12.0), LatLng(-15.0, 20.0),
        LatLng(-20.0, 28.0), LatLng(-25.0, 33.0), LatLng(-30.0, 30.0),
        LatLng(-35.0, 20.0), LatLng(-34.0, 18.0), LatLng(-30.0, 16.0),
        LatLng(-25.0, 15.0), LatLng(-20.0, 12.0), LatLng(-15.0, 12.0),
        LatLng(-10.0, 10.0),
      ],
      color: 0xFF1E2630,
    ),

    // Madagascar
    LandmassPolygon(
      name: 'madagascar',
      vertices: [
        LatLng(-12.0, 49.0), LatLng(-16.0, 50.0), LatLng(-22.0, 48.0),
        LatLng(-25.0, 47.0), LatLng(-22.0, 44.0), LatLng(-16.0, 44.0),
        LatLng(-13.0, 48.0),
      ],
      color: 0xFF1C2538,
    ),

    // Horn of Africa (Somalia)
    LandmassPolygon(
      name: 'horn_of_africa',
      vertices: [
        LatLng(12.0, 42.0), LatLng(12.0, 50.0), LatLng(5.0, 50.0),
        LatLng(2.0, 45.0), LatLng(0.0, 42.0),
      ],
      color: 0xFF1D2830,
    ),

    // Cape Verde area (small)
    // Skipping small islands for performance
  ];

  // ─── NORTH AMERICA ──────────────────────────────────────────────────

  static const List<LandmassPolygon> _northAmerica = [
    // Canada (simplified)
    LandmassPolygon(
      name: 'canada',
      vertices: [
        LatLng(49.0, -125.0), LatLng(55.0, -130.0), LatLng(60.0, -140.0),
        LatLng(65.0, -140.0), LatLng(70.0, -140.0), LatLng(72.0, -128.0),
        LatLng(70.0, -100.0), LatLng(65.0, -85.0), LatLng(60.0, -80.0),
        LatLng(55.0, -80.0), LatLng(52.0, -80.0), LatLng(47.0, -70.0),
        LatLng(44.0, -67.0), LatLng(45.0, -75.0), LatLng(48.0, -90.0),
        LatLng(49.0, -95.0),
      ],
      color: 0xFF1B2635,
    ),

    // USA (lower 48)
    LandmassPolygon(
      name: 'usa',
      vertices: [
        LatLng(49.0, -125.0), LatLng(49.0, -95.0), LatLng(48.0, -90.0),
        LatLng(45.0, -82.0), LatLng(42.0, -83.0), LatLng(42.0, -71.0),
        LatLng(40.0, -74.0), LatLng(35.0, -75.0), LatLng(30.0, -82.0),
        LatLng(25.0, -80.0), LatLng(25.0, -82.0), LatLng(28.0, -90.0),
        LatLng(30.0, -90.0), LatLng(29.0, -95.0), LatLng(26.0, -97.0),
        LatLng(32.0, -117.0), LatLng(38.0, -122.0), LatLng(42.0, -124.0),
        LatLng(46.0, -124.0),
      ],
      color: 0xFF1E2A38,
    ),

    // Alaska
    LandmassPolygon(
      name: 'alaska',
      vertices: [
        LatLng(60.0, -140.0), LatLng(64.0, -153.0), LatLng(70.0, -160.0),
        LatLng(72.0, -157.0), LatLng(71.0, -140.0), LatLng(65.0, -140.0),
      ],
      color: 0xFF1C2835,
    ),

    // Mexico
    LandmassPolygon(
      name: 'mexico',
      vertices: [
        LatLng(32.0, -117.0), LatLng(26.0, -97.0), LatLng(22.0, -97.0),
        LatLng(18.0, -95.0), LatLng(15.0, -92.0), LatLng(17.0, -100.0),
        LatLng(20.0, -105.0), LatLng(23.0, -110.0), LatLng(28.0, -115.0),
      ],
      color: 0xFF1D2630,
    ),

    // Central America
    LandmassPolygon(
      name: 'central_america',
      vertices: [
        LatLng(18.0, -95.0), LatLng(15.0, -92.0), LatLng(14.0, -87.0),
        LatLng(10.0, -84.0), LatLng(8.0, -77.0), LatLng(9.0, -78.0),
        LatLng(10.0, -84.0), LatLng(14.0, -90.0),
      ],
      color: 0xFF1E2735,
    ),

    // Cuba
    LandmassPolygon(
      name: 'cuba',
      vertices: [
        LatLng(23.0, -84.0), LatLng(22.0, -80.0), LatLng(20.0, -75.0),
        LatLng(20.0, -78.0), LatLng(21.5, -83.0),
      ],
      color: 0xFF1C2530,
    ),

    // Greenland
    LandmassPolygon(
      name: 'greenland',
      vertices: [
        LatLng(60.0, -45.0), LatLng(65.0, -40.0), LatLng(72.0, -25.0),
        LatLng(78.0, -20.0), LatLng(82.0, -30.0), LatLng(83.0, -50.0),
        LatLng(78.0, -68.0), LatLng(72.0, -55.0), LatLng(65.0, -54.0),
      ],
      color: 0xFF1A2530,
    ),

    // Hispaniola (Haiti + Dominican Republic)
    LandmassPolygon(
      name: 'hispaniola',
      vertices: [
        LatLng(19.5, -72.0), LatLng(20.0, -70.0), LatLng(18.5, -68.5),
        LatLng(18.0, -72.0),
      ],
      color: 0xFF1D2535,
    ),

    // Jamaica
    LandmassPolygon(
      name: 'jamaica',
      vertices: [
        LatLng(18.5, -78.0), LatLng(18.0, -76.5), LatLng(17.8, -77.0),
      ],
      color: 0xFF1C2630,
    ),
  ];

  // ─── SOUTH AMERICA ───────────────────────────────────────────────────

  static const List<LandmassPolygon> _southAmerica = [
    // Main continent
    LandmassPolygon(
      name: 'south_america',
      vertices: [
        LatLng(12.0, -72.0), LatLng(10.0, -67.0), LatLng(8.0, -60.0),
        LatLng(5.0, -52.0), LatLng(2.0, -50.0), LatLng(-3.0, -42.0),
        LatLng(-8.0, -35.0), LatLng(-15.0, -39.0), LatLng(-23.0, -42.0),
        LatLng(-28.0, -48.0), LatLng(-33.0, -52.0), LatLng(-38.0, -58.0),
        LatLng(-42.0, -64.0), LatLng(-46.0, -68.0), LatLng(-50.0, -70.0),
        LatLng(-55.0, -68.0), LatLng(-55.0, -65.0), LatLng(-52.0, -70.0),
        LatLng(-45.0, -75.0), LatLng(-40.0, -73.0), LatLng(-35.0, -72.0),
        LatLng(-30.0, -71.0), LatLng(-20.0, -70.0), LatLng(-15.0, -75.0),
        LatLng(-5.0, -80.0), LatLng(0.0, -78.0), LatLng(2.0, -78.0),
        LatLng(5.0, -77.0), LatLng(8.0, -77.0), LatLng(10.0, -75.0),
        LatLng(11.0, -73.0),
      ],
      color: 0xFF1C2735,
    ),

    // Colombia + Venezuela (northern bump)
    LandmassPolygon(
      name: 'colombia_venezuela',
      vertices: [
        LatLng(12.0, -72.0), LatLng(11.0, -73.0), LatLng(8.0, -77.0),
        LatLng(5.0, -77.0), LatLng(2.0, -78.0), LatLng(0.0, -75.0),
        LatLng(-3.0, -70.0), LatLng(2.0, -68.0), LatLng(5.0, -60.0),
        LatLng(8.0, -60.0), LatLng(10.0, -67.0),
      ],
      color: 0xFF1E2838,
    ),

    // Falkland Islands (small)
    LandmassPolygon(
      name: 'falklands',
      vertices: [
        LatLng(-51.0, -58.0), LatLng(-52.0, -58.0), LatLng(-52.0, -60.0),
        LatLng(-51.0, -60.0),
      ],
      color: 0xFF1A2535,
    ),

    // Tierra del Fuego
    LandmassPolygon(
      name: 'tierra_del_fuego',
      vertices: [
        LatLng(-55.0, -65.0), LatLng(-55.0, -68.0), LatLng(-56.0, -68.0),
        LatLng(-55.0, -72.0), LatLng(-54.0, -70.0), LatLng(-52.0, -70.0),
      ],
      color: 0xFF1B2630,
    ),
  ];

  // ─── OCEANIA ─────────────────────────────────────────────────────────

  static const List<LandmassPolygon> _oceania = [
    // Australia
    LandmassPolygon(
      name: 'australia',
      vertices: [
        LatLng(-12.0, 132.0), LatLng(-14.0, 127.0), LatLng(-15.0, 125.0),
        LatLng(-20.0, 118.0), LatLng(-25.0, 114.0), LatLng(-30.0, 115.0),
        LatLng(-34.0, 115.0), LatLng(-35.0, 118.0), LatLng(-35.0, 137.0),
        LatLng(-38.0, 145.0), LatLng(-38.0, 148.0), LatLng(-35.0, 150.0),
        LatLng(-32.0, 153.0), LatLng(-28.0, 153.0), LatLng(-24.0, 152.0),
        LatLng(-20.0, 149.0), LatLng(-16.0, 146.0), LatLng(-12.0, 142.0),
        LatLng(-11.0, 136.0),
      ],
      color: 0xFF1D2638,
    ),

    // New Zealand (North Island)
    LandmassPolygon(
      name: 'new_zealand_north',
      vertices: [
        LatLng(-35.0, 174.0), LatLng(-37.0, 175.0), LatLng(-41.0, 175.0),
        LatLng(-41.0, 174.0), LatLng(-38.0, 174.0),
      ],
      color: 0xFF1C2535,
    ),

    // New Zealand (South Island)
    LandmassPolygon(
      name: 'new_zealand_south',
      vertices: [
        LatLng(-42.0, 172.0), LatLng(-44.0, 169.0), LatLng(-46.0, 167.0),
        LatLng(-47.0, 168.0), LatLng(-45.0, 170.0), LatLng(-43.0, 172.0),
      ],
      color: 0xFF1D2630,
    ),

    // Tasmania
    LandmassPolygon(
      name: 'tasmania',
      vertices: [
        LatLng(-40.5, 145.0), LatLng(-43.0, 147.0), LatLng(-44.0, 148.0),
        LatLng(-43.0, 147.5), LatLng(-41.0, 145.0),
      ],
      color: 0xFF1E2735,
    ),

    // Fiji (simplified)
    LandmassPolygon(
      name: 'fiji',
      vertices: [
        LatLng(-17.0, 178.0), LatLng(-18.0, 179.0), LatLng(-19.0, 178.0),
        LatLng(-18.0, 177.0),
      ],
      color: 0xFF1C2635,
    ),
  ];

  // ─── ANTARCTICA ──────────────────────────────────────────────────────

  static const List<LandmassPolygon> _antarctica = [
    LandmassPolygon(
      name: 'antarctica',
      vertices: [
        LatLng(-65.0, -60.0), LatLng(-70.0, -30.0), LatLng(-72.0, 0.0),
        LatLng(-70.0, 30.0), LatLng(-68.0, 60.0), LatLng(-70.0, 90.0),
        LatLng(-68.0, 120.0), LatLng(-65.0, 150.0), LatLng(-67.0, 170.0),
        LatLng(-65.0, -150.0), LatLng(-68.0, -120.0), LatLng(-70.0, -90.0),
      ],
      color: 0xFF1A2030,
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════
  // MAJOR WORLD CITIES (decorative landmarks, not game cities)
  // ══════════════════════════════════════════════════════════════════════

  /// Major world cities shown as small dots on the map at low zoom.
  /// These are NOT game cities — they're decorative landmarks.
  static List<WorldCity> get worldCities => [
        // Europe (beyond game cities)
        WorldCity(name: 'Moscow', lat: 55.75, lng: 37.62, region: 'europe'),
        WorldCity(name: 'Istanbul', lat: 41.01, lng: 28.98, region: 'europe'),
        WorldCity(name: 'Athens', lat: 37.98, lng: 23.73, region: 'europe'),
        WorldCity(name: 'Kyiv', lat: 50.45, lng: 30.52, region: 'europe'),
        WorldCity(name: 'Bucharest', lat: 44.43, lng: 26.10, region: 'europe'),
        WorldCity(name: 'Sofia', lat: 42.70, lng: 23.32, region: 'europe'),
        WorldCity(name: 'Belgrade', lat: 44.79, lng: 20.47, region: 'europe'),
        WorldCity(name: 'Zagreb', lat: 45.81, lng: 15.98, region: 'europe'),
        WorldCity(name: 'Ljubljana', lat: 46.06, lng: 14.51, region: 'europe'),
        WorldCity(name: 'Tallinn', lat: 59.44, lng: 24.75, region: 'europe'),
        WorldCity(name: 'Riga', lat: 56.95, lng: 24.11, region: 'europe'),
        WorldCity(name: 'Vilnius', lat: 54.69, lng: 25.28, region: 'europe'),
        WorldCity(name: 'Helsinki', lat: 60.17, lng: 24.94, region: 'europe'),
        WorldCity(name: 'Minsk', lat: 53.90, lng: 27.57, region: 'europe'),
        WorldCity(name: 'Reykjavik', lat: 64.15, lng: -21.94, region: 'europe'),
        WorldCity(name: 'Lisbon', lat: 38.72, lng: -9.14, region: 'europe'),

        // Asia
        WorldCity(name: 'Tokyo', lat: 35.68, lng: 139.69, region: 'asia'),
        WorldCity(name: 'Beijing', lat: 39.90, lng: 116.40, region: 'asia'),
        WorldCity(name: 'Shanghai', lat: 31.23, lng: 121.47, region: 'asia'),
        WorldCity(name: 'Hong Kong', lat: 22.32, lng: 114.17, region: 'asia'),
        WorldCity(name: 'Singapore', lat: 1.35, lng: 103.82, region: 'asia'),
        WorldCity(name: 'Seoul', lat: 37.57, lng: 126.98, region: 'asia'),
        WorldCity(name: 'Mumbai', lat: 19.08, lng: 72.88, region: 'asia'),
        WorldCity(name: 'Delhi', lat: 28.61, lng: 77.21, region: 'asia'),
        WorldCity(name: 'Bangkok', lat: 13.76, lng: 100.50, region: 'asia'),
        WorldCity(name: 'Dubai', lat: 25.20, lng: 55.27, region: 'asia'),
        WorldCity(name: 'Riyadh', lat: 24.71, lng: 46.68, region: 'asia'),
        WorldCity(name: 'Tehran', lat: 35.69, lng: 51.39, region: 'asia'),
        WorldCity(name: 'Jakarta', lat: -6.21, lng: 106.85, region: 'asia'),
        WorldCity(name: 'Manila', lat: 14.60, lng: 120.98, region: 'asia'),
        WorldCity(name: 'Karachi', lat: 24.86, lng: 67.01, region: 'asia'),
        WorldCity(name: 'Dhaka', lat: 23.81, lng: 90.41, region: 'asia'),
        WorldCity(name: 'Taipei', lat: 25.03, lng: 121.57, region: 'asia'),
        WorldCity(name: 'Osaka', lat: 34.69, lng: 135.50, region: 'asia'),

        // Africa
        WorldCity(name: 'Cairo', lat: 30.04, lng: 31.24, region: 'africa'),
        WorldCity(name: 'Lagos', lat: 6.52, lng: 3.38, region: 'africa'),
        WorldCity(name: 'Nairobi', lat: -1.29, lng: 36.82, region: 'africa'),
        WorldCity(name: 'Cape Town', lat: -33.93, lng: 18.42, region: 'africa'),
        WorldCity(name: 'Johannesburg', lat: -26.20, lng: 28.05, region: 'africa'),
        WorldCity(name: 'Casablanca', lat: 33.57, lng: -7.59, region: 'africa'),
        WorldCity(name: 'Addis Ababa', lat: 9.02, lng: 38.75, region: 'africa'),
        WorldCity(name: 'Kinshasa', lat: -4.44, lng: 15.27, region: 'africa'),
        WorldCity(name: 'Accra', lat: 5.56, lng: -0.19, region: 'africa'),
        WorldCity(name: 'Dar es Salaam', lat: -6.79, lng: 39.28, region: 'africa'),

        // North America
        WorldCity(name: 'New York', lat: 40.71, lng: -74.01, region: 'namerica'),
        WorldCity(name: 'Los Angeles', lat: 34.05, lng: -118.24, region: 'namerica'),
        WorldCity(name: 'Chicago', lat: 41.88, lng: -87.63, region: 'namerica'),
        WorldCity(name: 'Toronto', lat: 43.65, lng: -79.38, region: 'namerica'),
        WorldCity(name: 'Mexico City', lat: 19.43, lng: -99.13, region: 'namerica'),
        WorldCity(name: 'Vancouver', lat: 49.28, lng: -123.12, region: 'namerica'),
        WorldCity(name: 'Miami', lat: 25.76, lng: -80.19, region: 'namerica'),
        WorldCity(name: 'San Francisco', lat: 37.77, lng: -122.42, region: 'namerica'),
        WorldCity(name: 'Washington DC', lat: 38.91, lng: -77.04, region: 'namerica'),
        WorldCity(name: 'Houston', lat: 29.76, lng: -95.37, region: 'namerica'),
        WorldCity(name: 'Montreal', lat: 45.50, lng: -73.57, region: 'namerica'),
        WorldCity(name: 'Havana', lat: 23.11, lng: -82.37, region: 'namerica'),

        // South America
        WorldCity(name: 'São Paulo', lat: -23.55, lng: -46.63, region: 'samerica'),
        WorldCity(name: 'Buenos Aires', lat: -34.60, lng: -58.38, region: 'samerica'),
        WorldCity(name: 'Rio de Janeiro', lat: -22.91, lng: -43.17, region: 'samerica'),
        WorldCity(name: 'Bogota', lat: 4.71, lng: -74.07, region: 'samerica'),
        WorldCity(name: 'Lima', lat: -12.05, lng: -77.04, region: 'samerica'),
        WorldCity(name: 'Santiago', lat: -33.45, lng: -70.67, region: 'samerica'),
        WorldCity(name: 'Caracas', lat: 10.49, lng: -66.88, region: 'samerica'),

        // Oceania
        WorldCity(name: 'Sydney', lat: -33.87, lng: 151.21, region: 'oceania'),
        WorldCity(name: 'Melbourne', lat: -37.81, lng: 144.96, region: 'oceania'),
        WorldCity(name: 'Auckland', lat: -36.85, lng: 174.76, region: 'oceania'),
        WorldCity(name: 'Perth', lat: -31.95, lng: 115.86, region: 'oceania'),
      ];

  // ══════════════════════════════════════════════════════════════════════
  // REGION LABELS (shown at very low zoom for orientation)
  // ══════════════════════════════════════════════════════════════════════

  /// Region labels shown at zoom < 2.5 for global orientation.
  static List<RegionLabel> get regionLabels => [
        RegionLabel(name: 'EUROPE', lat: 52.0, lng: 15.0, minZoom: 1.0, maxZoom: 2.5),
        RegionLabel(name: 'ASIA', lat: 45.0, lng: 90.0, minZoom: 1.0, maxZoom: 2.5),
        RegionLabel(name: 'AFRICA', lat: 5.0, lng: 20.0, minZoom: 1.0, maxZoom: 2.5),
        RegionLabel(name: 'N. AMERICA', lat: 45.0, lng: -100.0, minZoom: 1.0, maxZoom: 2.5),
        RegionLabel(name: 'S. AMERICA', lat: -15.0, lng: -55.0, minZoom: 1.0, maxZoom: 2.5),
        RegionLabel(name: 'OCEANIA', lat: -30.0, lng: 140.0, minZoom: 1.0, maxZoom: 2.5),
      ];

  // ══════════════════════════════════════════════════════════════════════
  // OCEAN / WATER BODIES
  // ══════════════════════════════════════════════════════════════════════

  /// Major water bodies / seas for subtle rendering at higher zoom.
  static List<WaterBody> get waterBodies => [
        WaterBody(name: 'Mediterranean Sea', vertices: [
          LatLng(36.0, -5.5), LatLng(37.0, 0.0), LatLng(43.3, -1.8),
          LatLng(43.7, 7.0), LatLng(44.1, 10.0), LatLng(40.5, 18.0),
          LatLng(37.5, 15.0), LatLng(36.5, 28.0), LatLng(31.0, 32.0),
          LatLng(30.0, 33.0), LatLng(22.0, 36.0), LatLng(20.0, 40.0),
          LatLng(17.0, 42.0), LatLng(12.5, 44.0), LatLng(12.0, 42.0),
          LatLng(14.5, 43.0), LatLng(17.0, 42.0),
        ]),
        WaterBody(name: 'Caspian Sea', vertices: [
          LatLng(47.0, 50.0), LatLng(44.0, 50.0), LatLng(37.0, 53.0),
          LatLng(36.5, 52.0), LatLng(40.0, 51.0), LatLng(42.0, 50.0),
        ]),
        WaterBody(name: 'Black Sea', vertices: [
          LatLng(47.0, 40.0), LatLng(44.0, 40.0), LatLng(42.0, 44.0),
          LatLng(41.0, 29.0), LatLng(43.0, 28.0),
        ]),
        WaterBody(name: 'Red Sea', vertices: [
          LatLng(22.0, 36.0), LatLng(20.0, 40.0), LatLng(17.0, 42.0),
          LatLng(12.5, 44.0), LatLng(14.5, 43.0), LatLng(15.0, 42.0),
          LatLng(20.0, 38.0), LatLng(22.0, 36.0),
        ]),
        WaterBody(name: 'Persian Gulf', vertices: [
          LatLng(30.0, 48.0), LatLng(27.0, 50.0), LatLng(25.0, 56.0),
          LatLng(22.0, 59.0), LatLng(28.0, 50.0), LatLng(30.0, 49.0),
        ]),
        WaterBody(name: 'Bay of Bengal', vertices: [
          LatLng(22.0, 88.0), LatLng(16.0, 82.0), LatLng(8.0, 77.0),
          LatLng(5.0, 80.0), LatLng(10.0, 98.0), LatLng(16.0, 100.0),
          LatLng(20.0, 93.0),
        ]),
        WaterBody(name: 'Hudson Bay', vertices: [
          LatLng(65.0, -85.0), LatLng(60.0, -80.0), LatLng(55.0, -82.0),
          LatLng(52.0, -80.0), LatLng(55.0, -78.0), LatLng(58.0, -78.0),
          LatLng(63.0, -82.0),
        ]),
        // ── Ferry-relevant water bodies ──
        WaterBody(name: 'Irish Sea', vertices: [
          LatLng(55.5, -6.0), LatLng(54.5, -5.0), LatLng(53.0, -4.5),
          LatLng(51.5, -5.5), LatLng(51.0, -6.5), LatLng(52.0, -7.0),
          LatLng(53.5, -6.5), LatLng(55.0, -7.0),
        ]),
        WaterBody(name: 'Baltic Sea', vertices: [
          LatLng(65.5, 23.0), LatLng(63.0, 22.0), LatLng(60.0, 24.0),
          LatLng(57.0, 20.0), LatLng(55.5, 18.0), LatLng(54.0, 14.0),
          LatLng(55.0, 12.0), LatLng(56.0, 11.0), LatLng(57.5, 11.5),
          LatLng(59.0, 13.0), LatLng(60.0, 18.0), LatLng(62.0, 20.0),
        ]),
        WaterBody(name: 'North Sea', vertices: [
          LatLng(62.0, -5.0), LatLng(60.0, 0.0), LatLng(58.5, 5.0),
          LatLng(56.0, 7.0), LatLng(54.0, 8.0), LatLng(52.0, 4.0),
          LatLng(51.0, 1.5), LatLng(50.5, -1.0), LatLng(52.0, -3.0),
          LatLng(54.0, -5.0), LatLng(57.0, -6.0),
        ]),
        WaterBody(name: 'English Channel', vertices: [
          LatLng(51.0, -5.0), LatLng(50.5, -1.5), LatLng(50.0, 1.0),
          LatLng(50.5, 2.0), LatLng(51.0, 2.0), LatLng(51.5, 1.0),
          LatLng(50.5, -1.0),
        ]),
        WaterBody(name: 'Aegean Sea', vertices: [
          LatLng(40.5, 24.0), LatLng(39.0, 25.5), LatLng(37.5, 26.0),
          LatLng(36.5, 27.0), LatLng(37.0, 28.5), LatLng(38.0, 26.5),
          LatLng(39.5, 25.0), LatLng(40.0, 24.5),
        ]),
      ];

  // ══════════════════════════════════════════════════════════════════════
  // HELPER: Look up landmass polygons visible in a bounding box
  // ══════════════════════════════════════════════════════════════════════

  /// Get all landmass polygons that could be visible given the camera view.
  /// [minLat], [maxLat], [minLng], [maxLng] define the visible area with
  /// a generous margin.
  static List<LandmassPolygon> getVisibleLandmasses({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) {
    const margin = 15.0;
    return allLandmasses.where((poly) {
      for (final v in poly.vertices) {
        if (v.latitude >= minLat - margin &&
            v.latitude <= maxLat + margin &&
            v.longitude >= minLng - margin &&
            v.longitude <= maxLng + margin) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  /// Get world cities visible in the given bounding box.
  static List<WorldCity> getVisibleWorldCities({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) {
    const margin = 5.0;
    return worldCities.where((city) {
      return city.lat >= minLat - margin &&
          city.lat <= maxLat + margin &&
          city.lng >= minLng - margin &&
          city.lng <= maxLng + margin;
    }).toList();
  }
}

// ══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ══════════════════════════════════════════════════════════════════════════

/// A simplified polygon representing a country or landmass region.
class LandmassPolygon {
  final String name;
  final List<LatLng> vertices;
  final int color; // ARGB hex

  const LandmassPolygon({
    required this.name,
    required this.vertices,
    required this.color,
  });
}

/// A decorative world city landmark (not a game city).
class WorldCity {
  final String name;
  final double lat;
  final double lng;
  final String region;

  const WorldCity({
    required this.name,
    required this.lat,
    required this.lng,
    required this.region,
  });
}

/// A region label shown at very low zoom.
class RegionLabel {
  final String name;
  final double lat;
  final double lng;
  final double minZoom;
  final double maxZoom;

  const RegionLabel({
    required this.name,
    required this.lat,
    required this.lng,
    required this.minZoom,
    required this.maxZoom,
  });
}

/// A water body (sea, gulf, bay) for subtle rendering.
class WaterBody {
  final String name;
  final List<LatLng> vertices;

  const WaterBody({required this.name, required this.vertices});
}
