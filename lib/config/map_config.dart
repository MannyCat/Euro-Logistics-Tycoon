/// Map tile configuration.
/// Change tile provider here. All screens reference this.
class MapConfig {
  MapConfig._();

  /// Primary dark tile URL template.
  /// Free options (no API key needed):
  ///   CartoDB dark_all: https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png
  ///   CartoDB dark_nolabels + dark_only_labels (current split approach)
  ///
  /// MapTiler (free tier, needs API key):
  ///   https://api.maptiler.com/maps/basic-dark/256/{z}/{x}/{y}.png?key=<KEY>
  ///
  /// Set your MapTiler API key here (or leave empty for CartoDB fallback):
  static const String maptilerKey = '';

  /// Primary base tiles (dark, no labels)
  static String get baseTileUrl => maptilerKey.isNotEmpty
      ? 'https://api.maptiler.com/maps/basic-dark/256/{z}/{x}/{y}.png?key=$maptilerKey'
      : 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png';

  /// Label overlay tiles
  static String get labelTileUrl => maptilerKey.isNotEmpty
      ? 'https://api.maptiler.com/maps/basic-dark/256/{z}/{x}/{y}.png?key=$maptilerKey'
      : 'https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}{r}.png';

  /// User agent for tile requests
  static const String userAgent = 'com.elt.logistics';

  /// Whether to use retina/HiDPI tiles
  static const bool retinaMode = true;

  /// Whether to use separate label overlay (false = use combined tiles)
  static bool get useSeparateLabels => maptilerKey.isEmpty;
}
