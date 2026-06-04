import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/game_constants.dart';

/// Bidirectional mapping between GameConstants string slugs and database integer IDs.
/// Built once at startup by querying the DB and matching by normalized name.
class DbIdMapper {
  // Port slug ↔ DB int ID
  static final Map<String, int> portSlugToDb = {};
  static final Map<int, String> portDbToSlug = {};

  // Good slug ↔ DB int ID
  static final Map<String, int> goodSlugToDb = {};
  static final Map<int, String> goodDbToSlug = {};

  // Ship type slug ↔ DB int ID
  static final Map<String, int> shipTypeSlugToDb = {};
  static final Map<int, String> shipTypeDbToSlug = {};

  static bool _initialized = false;

  /// Build all mappings by querying the database tables.
  /// Must be called once after Supabase is initialized.
  static Future<void> init(SupabaseClient supabase) async {
    if (_initialized) return;

    try {
      // --- Ports ---
      final dbPorts = await supabase.from('ports').select('id, name');
      for (final row in dbPorts) {
        final dbId = row['id'] as int;
        final dbName = _normalizeName(row['name'] as String);
        for (final gcPort in GameConstants.ports) {
          final slugNorm = gcPort.id.replaceAll('_', ' ');
          if (slugNorm == dbName) {
            portSlugToDb[gcPort.id] = dbId;
            portDbToSlug[dbId] = gcPort.id;
            break;
          }
        }
      }

      // --- Goods ---
      final dbGoods = await supabase.from('goods').select('id, name');
      for (final row in dbGoods) {
        final dbId = row['id'] as int;
        final dbName = _normalizeName(row['name'] as String);
        for (final gcGood in GameConstants.goods) {
          final slugNorm = gcGood.id.replaceAll('_', ' ');
          if (slugNorm == dbName) {
            goodSlugToDb[gcGood.id] = dbId;
            goodDbToSlug[dbId] = gcGood.id;
            break;
          }
        }
      }

      // --- Ship types ---
      final dbShipTypes =
          await supabase.from('ship_types').select('id, name');
      for (final row in dbShipTypes) {
        final dbId = row['id'] as int;
        final dbName = (row['name'] as String).toLowerCase();
        for (final gcShipType in GameConstants.shipTypes) {
          final slugNorm = gcShipType.id.replaceAll('_', ' ');
          // Ship types use different names — try partial match
          if (slugNorm.isNotEmpty && dbName.contains(slugNorm)) {
            shipTypeSlugToDb[gcShipType.id] = dbId;
            shipTypeDbToSlug[dbId] = gcShipType.id;
            break;
          }
        }
      }

      _initialized = true;
      // ignore: avoid_print
      print('DbIdMapper initialized: '
          'ports=${portSlugToDb.length}, '
          'goods=${goodSlugToDb.length}, '
          'shipTypes=${shipTypeSlugToDb.length}');
      // ignore: avoid_print
      print('DbIdMapper portSlugToDb: $portSlugToDb');
      // ignore: avoid_print
      print('DbIdMapper goodSlugToDb: $goodSlugToDb');
    } catch (e) {
      // ignore: avoid_print
      print('DbIdMapper init error: $e');
    }
  }

  /// Convert a port slug to database integer ID. Returns null if not found.
  static int? portSlugToInt(String? slug) {
    if (slug == null) return null;
    return portSlugToDb[slug];
  }

  /// Convert a database integer port ID to slug. Returns null if not found.
  static String? portIntToSlug(int? dbId) {
    if (dbId == null) return null;
    return portDbToSlug[dbId];
  }

  /// Convert a good slug to database integer ID. Returns null if not found.
  static int? goodSlugToInt(String? slug) {
    if (slug == null) return null;
    return goodSlugToDb[slug];
  }

  /// Convert a database integer good ID to slug. Returns null if not found.
  static String? goodIntToSlug(int? dbId) {
    if (dbId == null) return null;
    return goodDbToSlug[dbId];
  }

  /// Convert a ship type slug to database integer ID. Returns null if not found.
  static int? shipTypeSlugToInt(String? slug) {
    if (slug == null) return null;
    return shipTypeSlugToDb[slug];
  }

  /// Convert a database integer ship type ID to slug. Returns null if not found.
  static String? shipTypeIntToSlug(int? dbId) {
    if (dbId == null) return null;
    return shipTypeDbToSlug[dbId];
  }

  /// Normalize a database name for comparison with slugs.
  static String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'\s*\(.*?\)\s*'), '')
        .trim();
  }
}
