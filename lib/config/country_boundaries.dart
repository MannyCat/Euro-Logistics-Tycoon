import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Simplified country boundary polygons for the map shading overlay.
/// Each entry maps a country name (lowercase) to a list of [LatLng] vertices
/// tracing a very rough outline. Polygons are closed automatically by
/// [PolygonLayer].
///
/// These are NOT accurate borders — just enough visual mass to tint each
/// country differently on the dark map at typical zoom levels (3–8).

class CountryBoundaries {
  CountryBoundaries._();

  /// Map from country name (lowercase) → polygon vertices.
  static Map<String, List<LatLng>> get boundaries => {
        // ─── Germany ─────────────────────────────────────────
        'germany': [
          const LatLng(54.9, 8.6),   // NE (Rügen / Stralsund)
          const LatLng(55.0, 14.3),  // NE (Usedom)
          const LatLng(54.4, 14.8),  // E (Görlitz)
          const LatLng(51.0, 15.0),  // SE (Görlitz south)
          const LatLng(50.3, 12.2),  // S (Zwickau)
          const LatLng(47.6, 10.2),  // SW (Bodensee)
          const LatLng(47.5, 7.6),   // W (Basel area)
          const LatLng(48.8, 7.6),   // W (Karlsruhe)
          const LatLng(49.0, 6.4),   // W (Saarbrücken)
          const LatLng(50.4, 6.2),   // NW (Aachen)
          const LatLng(51.8, 6.7),   // NW (Düsseldorf)
          const LatLng(53.5, 7.0),   // N (Bremen)
          const LatLng(54.8, 8.6),   // NE (Hamburg)
        ],

        // ─── France ──────────────────────────────────────────
        'france': [
          const LatLng(51.1, 2.1),    // N (Calais)
          const LatLng(51.1, 4.5),   // NE (Maubeuge)
          const LatLng(49.5, 6.4),   // E (Strasbourg)
          const LatLng(48.6, 7.6),   // E (Mulhouse)
          const LatLng(47.5, 7.0),    // SE (Geneva)
          const LatLng(46.2, 6.1),   // SE (Annecy)
          const LatLng(43.7, 7.0),   // SE (Nice)
          const LatLng(43.3, 3.1),   // S (Perpignan)
          const LatLng(42.5, 3.1),    // S (Perpignan west)
          const LatLng(42.9, -0.3),  // SW (Andorra)
          const LatLng(43.4, -1.8),  // W (Bayonne)
          const LatLng(47.2, -2.5),  // W (Nantes)
          const LatLng(48.6, -4.8),  // W (Brest)
          const LatLng(49.7, -1.8),  // NW (Cherbourg)
          const LatLng(50.9, 1.7),   // N (Dunkirk)
        ],

        // ─── Italy ───────────────────────────────────────────
        'italy': [
          const LatLng(46.5, 13.6),  // NE (Udine)
          const LatLng(45.7, 14.6),  // E (Trieste)
          const LatLng(44.2, 12.3),  // E (Ravenna)
          const LatLng(43.6, 13.0),  // E (Ancona)
          const LatLng(41.9, 15.4),  // SE (Puglia)
          const LatLng(40.6, 16.5),  // SE (heel)
          const LatLng(39.6, 16.5),  // S (Calabria)
          const LatLng(38.1, 15.6),  // S (Sicily tip)
          const LatLng(37.5, 15.0),  // SW Sicily
          const LatLng(38.1, 13.0),  // W Sicily
          const LatLng(40.0, 15.4),  // W (Campania)
          const LatLng(41.2, 16.2),  // E (Foggia)
          const LatLng(42.0, 14.0),  // W (Naples area)
          const LatLng(43.3, 11.8),  // W (Florence coast)
          const LatLng(44.1, 10.0),  // W (Genoa)
          const LatLng(46.0, 8.3),   // NW (Aosta)
          const LatLng(46.5, 11.0),  // N (Bolzano)
          const LatLng(47.0, 13.5),  // NE (Cortina)
        ],

        // ─── Spain ───────────────────────────────────────────
        'spain': [
          const LatLng(43.8, -1.8),  // N (San Sebastián)
          const LatLng(43.4, -3.8),  // N (Santander)
          const LatLng(43.6, -7.3),  // NW (Galicia)
          const LatLng(42.0, -9.3),  // W (Portugal border)
          const LatLng(37.2, -7.4),  // SW (Huelva)
          const LatLng(36.7, -4.4),  // S (Málaga)
          const LatLng(36.7, -2.1),  // SE (Almería)
          const LatLng(38.0, -0.2),  // SE (Alicante)
          const LatLng(40.5, 0.5),   // E (Valencia)
          const LatLng(42.9, 3.2),   // NE (Barcelona)
          const LatLng(43.5, 1.8),   // N (Girona)
        ],

        // ─── United Kingdom ────────────────────────────────────
        'uk': [
          const LatLng(51.5, -0.5),  // SE (London)
          const LatLng(50.6, -3.5),  // SW (Cornwall)
          const LatLng(51.5, -5.0),  // W (Wales)
          const LatLng(53.5, -3.0),  // W (Liverpool)
          const LatLng(54.5, -5.5),  // NW (Belfast area, NI)
          const LatLng(55.3, -5.8),  // N (Scotland south)
          const LatLng(56.5, -6.0),  // N (Scotland)
          const LatLng(58.6, -3.2),  // NE (Scotland)
          const LatLng(57.5, -1.8),  // E (Aberdeen)
          const LatLng(55.5, 1.3),   // E (Norfolk)
          const LatLng(52.5, 1.8),   // E (Suffolk)
        ],

        // ─── Poland ────────────────────────────────────────────
        'poland': [
          const LatLng(54.5, 14.3),  // N (Baltic)
          const LatLng(54.6, 18.5),  // NE (Gdańsk)
          const LatLng(54.4, 24.1),  // E (Suwałki)
          const LatLng(51.3, 23.5),  // SE (Lublin)
          const LatLng(49.5, 22.8),  // S (Bieszczady)
          const LatLng(49.0, 20.0),  // S (Zakopane area)
          const LatLng(49.6, 14.3),  // SW (Sudeten)
          const LatLng(51.0, 15.0),  // W (Lower Silesia)
          const LatLng(52.5, 15.6),  // W (Poznań)
          const LatLng(53.5, 14.6),  // NW (Szczecin),
        ],

        // ─── Czech Republic ──────────────────────────────────
        'czech republic': [
          const LatLng(51.1, 12.4),  // N (Děčín)
          const LatLng(51.1, 18.3),  // NE (Ostrava)
          const LatLng(49.6, 18.9),  // SE (Ostrava south)
          const LatLng(48.6, 17.2),  // S (Brno)
          const LatLng(48.6, 14.8),  // SW (Šumava)
          const LatLng(48.6, 12.1),  // W (Cheb)
          const LatLng(50.2, 12.2),  // NW (Karlovy Vary)
        ],

        // ─── Austria ──────────────────────────────────────────
        'austria': [
          const LatLng(48.9, 16.8),  // NE (Vienna)
          const LatLng(48.6, 17.0),  // E (Burgenland)
          const LatLng(47.0, 16.4),  // SE (Graz)
          const LatLng(46.7, 14.0),  // S (Klagenfurt)
          const LatLng(46.6, 11.0),  // SW (Innsbruck)
          const LatLng(47.5, 10.0),  // W (Bregenz)
          const LatLng(47.8, 12.6),  // NW (Salzburg)
          const LatLng(48.7, 13.0),  // N (Linz area)
          const LatLng(48.9, 15.5),  // NE (St. Pölten),
        ],

        // ─── Switzerland ──────────────────────────────────────
        'switzerland': [
          const LatLng(47.8, 10.5),  // NE (St. Gallen)
          const LatLng(47.5, 8.5),   // W (Lake Geneva)
          const LatLng(46.2, 6.8),   // SW (Geneva)
          const LatLng(46.5, 7.9),   // S (Brig)
          const LatLng(46.6, 10.1),  // SE (Ticino)
          const LatLng(47.0, 10.4),  // E (Chur)
        ],

        // ─── Netherlands ───────────────────────────────────────
        'netherlands': [
          const LatLng(53.6, 7.0),   // NE (Groningen)
          const LatLng(53.4, 5.8),   // NW (Friesland)
          const LatLng(52.0, 4.0),   // W (Rotterdam)
          const LatLng(51.4, 4.0),   // SW (Zeeland)
          const LatLng(51.4, 5.5),   // S (Noord-Brabant)
          const LatLng(51.5, 6.2),   // SE (Limburg)
          const LatLng(52.3, 6.6),   // E (Gelderland)
        ],

        // ─── Belgium ───────────────────────────────────────────
        'belgium': [
          const LatLng(51.5, 2.5),   // W (Ostend)
          const LatLng(51.4, 4.5),   // E (Arlon)
          const LatLng(50.7, 6.0),   // SE (Arlon south)
          const LatLng(50.2, 5.9),   // S (Arlon)
          const LatLng(49.5, 6.0),   // S (Arlon)
          const LatLng(49.5, 5.8),   // SW
          const LatLng(50.8, 2.9),   // NW (Bruges),
        ],

        // ─── Denmark ──────────────────────────────────────────
        'denmark': [
          const LatLng(57.8, 8.4),   // NW (Skagen)
          const LatLng(56.0, 8.5),   // W (Jutland)
          const LatLng(55.4, 9.7),   // S (Jutland south)
          const LatLng(54.8, 11.5),  // SE (Jutland east)
          const LatLng(55.0, 12.7),  // E (Zealand)
          const LatLng(56.8, 12.7),  // NE (Copenhagen)
          const LatLng(57.7, 10.6),  // N (Zealand north),
        ],

        // ─── Sweden ───────────────────────────────────────────
        'sweden': [
          const LatLng(55.5, 12.8),  // S (Malmö)
          const LatLng(56.8, 14.2),  // SE (Kalmar)
          const LatLng(59.0, 18.0),  // E (Stockholm)
          const LatLng(60.5, 18.5),  // E (Åland)
          const LatLng(64.0, 20.0),  // NE (Gävle)
          const LatLng(69.1, 20.0),  // N (Kiruna)
          const LatLng(68.4, 16.5),  // NW (Lappland)
          const LatLng(65.8, 12.6),  // W (Trondheim area)
          const LatLng(63.5, 11.5),  // W (Trondheim)
          const LatLng(59.0, 11.2),  // SW (Gothenburg),
        ],

        // ─── Norway ───────────────────────────────────────────
        'norway': [
          const LatLng(57.9, 7.5),   // S (Stavanger)
          const LatLng(59.0, 5.3),    // W (Bergen)
          const LatLng(62.0, 5.8),   // W (Ålesund)
          const LatLng(63.5, 10.4),  // W (Trondheim)
          const LatLng(67.0, 15.0),  // N (Narvik)
          const LatLng(70.0, 20.0),  // NE (Nordkapp area)
          const LatLng(71.2, 26.0),  // NE (Varanger)
          const LatLng(69.0, 18.0),  // E
          const LatLng(68.0, 15.0),  // E
          const LatLng(64.5, 12.5),  // E (Røros)
          const LatLng(61.0, 12.0),  // E (Østerdalen)
          const LatLng(58.8, 8.7),   // SE (Oslo),
        ],

        // ─── Finland ──────────────────────────────────────────
        'finland': [
          const LatLng(60.0, 21.0),  // S (Helsinki)
          const LatLng(60.5, 27.0),  // SE (Lappeenranta)
          const LatLng(62.0, 28.5),  // E (Joensuu)
          const LatLng(65.0, 28.5),  // NE (Kuusamo)
          const LatLng(70.1, 28.0),  // N (Inari)
          const LatLng(69.6, 20.0),  // NW (Kilpisjärvi)
          const LatLng(66.0, 14.0),  // W (Bottenviken)
          const LatLng(63.5, 21.0),  // W (Vaasa)
          const LatLng(61.0, 21.5),  // SW (Turku),
        ],

        // ─── Hungary ──────────────────────────────────────────
        'hungary': [
          const LatLng(48.6, 17.2),  // N (Bratislava)
          const LatLng(48.1, 20.0),  // NE (Miskolc)
          const LatLng(47.8, 22.0),  // E (Debrecen)
          const LatLng(46.0, 21.0),  // SE (Szeged)
          const LatLng(45.7, 18.3),  // S (Pécs)
          const LatLng(45.9, 16.3),  // SW (Nagykanizsa)
          const LatLng(46.5, 16.2),  // W (Lake Balaton)
          const LatLng(47.5, 16.8),  // NW (Győr),
        ],

        // ─── Portugal ──────────────────────────────────────────
        'portugal': [
          const LatLng(42.0, -9.3),  // N (Porto)
          const LatLng(41.8, -8.4),  // N (Braga)
          const LatLng(38.7, -9.4),  // W (Lisbon)
          const LatLng(37.0, -7.9),  // S (Algarve)
          const LatLng(37.0, -7.5),  // SE (Faro)
          const LatLng(39.0, -7.5),  // E (Castelo Branco)
          const LatLng(40.5, -7.3),  // NE (Guarda),
        ],

        // ─── Ireland ───────────────────────────────────────────
        'ireland': [
          const LatLng(53.5, -6.0),  // E (Dublin)
          const LatLng(55.3, -6.0),  // NE (Belfast)
          const LatLng(55.4, -7.0),  // N (Londonderry)
          const LatLng(54.3, -10.0), // W (Sligo)
          const LatLng(52.0, -10.5), // SW (Cork)
          const LatLng(51.4, -10.3), // S (Kinsale)
          const LatLng(52.1, -6.3),  // E (Wexford),
        ],

        // ─── Romania ───────────────────────────────────────────
        'romania': [
          const LatLng(48.3, 22.0),  // N (Maramureș)
          const LatLng(48.3, 26.0),  // NE (Bukovina)
          const LatLng(47.5, 27.0),  // E (Moldova)
          const LatLng(45.5, 30.0),  // SE (Danube Delta)
          const LatLng(44.0, 28.5),  // S (Dobrogea)
          const LatLng(43.6, 24.0),  // S (Vidin area)
          const LatLng(44.2, 22.5),  // SW (Banat)
          const LatLng(45.5, 22.0),  // W (Transylvania)
          const LatLng(47.0, 22.0),  // NW (Cluj),
        ],

        // ─── Slovakia ─────────────────────────────────────────
        'slovakia': [
          const LatLng(49.6, 17.0),  // NW
          const LatLng(49.6, 22.6),  // NE (Prešov)
          const LatLng(48.5, 22.0),  // SE (Košice)
          const LatLng(47.8, 18.5),  // S (Hungarian border)
          const LatLng(47.7, 16.6),  // SW (Bratislava)
          const LatLng(48.6, 17.0),  // W (Trenčín),
        ],

        // ─── Luxembourg ───────────────────────────────────────
        'luxembourg': [
          const LatLng(50.2, 5.7),   // N
          const LatLng(49.5, 6.5),   // SE
          const LatLng(49.4, 6.1),   // S
          const LatLng(49.8, 5.8),   // W
        ],
      };

  /// Color for each country, keyed by lowercase country name.
  /// All colors are very dark, blending with the CartoDB dark map.
  static Map<String, Color> countryColors = {
    'germany': const Color(0xFF1E2A3A),
    'france': const Color(0xFF1A2535),
    'italy': const Color(0xFF1F2530),
    'spain': const Color(0xFF202528),
    'uk': const Color(0xFF1B2833),
    'united kingdom': const Color(0xFF1B2833),
    'poland': const Color(0xFF1D2638),
    'czech republic': const Color(0xFF1C2935),
    'czechia': const Color(0xFF1C2935),
    'austria': const Color(0xFF1E2835),
    'switzerland': const Color(0xFF1A2A3A),
    'netherlands': const Color(0xFF1B2530),
    'belgium': const Color(0xFF1C2630),
    'denmark': const Color(0xFF1E2535),
    'sweden': const Color(0xFF1B2538),
    'norway': const Color(0xFF1D2635),
    'finland': const Color(0xFF1E2738),
    'hungary': const Color(0xFF1F2835),
    'portugal': const Color(0xFF1A2830),
    'ireland': const Color(0xFF1C2535),
    'romania': const Color(0xFF1D2835),
    'slovakia': const Color(0xFF1C2735),
    'luxembourg': const Color(0xFF1E2835),
  };

  /// Look up polygon for a given country name (case-insensitive).
  static List<LatLng>? polygonFor(String country) {
    final key = country.toLowerCase().trim();
    return boundaries[key];
  }

  /// Look up shading color for a given country name (case-insensitive).
  static Color? colorFor(String country) {
    final key = country.toLowerCase().trim();
    return countryColors[key];
  }
}
