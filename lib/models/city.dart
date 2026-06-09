class City {
  final int id;
  final String slug;
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final int population;
  final int warehouseCost;
  final int depotFee;
  final bool hasDepot;

  const City({
    required this.id,
    required this.slug,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.population,
    required this.warehouseCost,
    required this.depotFee,
    required this.hasDepot,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id'] as int,
    slug: json['slug'] as String? ?? '',
    name: json['name'] as String? ?? '',
    country: json['country'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    population: (json['population'] as num?)?.toInt() ?? 0,
    warehouseCost: (json['warehouse_cost'] as num?)?.toInt() ?? 500000,
    depotFee: (json['depot_fee'] as num?)?.toInt() ?? 500,
    hasDepot: (json['has_depot'] as bool?) ?? true,
  );

  /// Two-letter ISO country code derived from country name.
  /// Used for flag CDN lookups (flagcdn.com).
  String get countryCode => switch (country.toLowerCase()) {
    'germany' => 'de',
    'france' => 'fr',
    'netherlands' => 'nl',
    'belgium' => 'be',
    'switzerland' => 'ch',
    'austria' => 'at',
    'italy' => 'it',
    'czech republic' || 'czechia' => 'cz',
    'poland' => 'pl',
    'hungary' => 'hu',
    'spain' => 'es',
    'denmark' => 'dk',
    'sweden' => 'se',
    'norway' => 'no',
    'finland' => 'fi',
    'uk' || 'united kingdom' => 'gb',
    'ireland' => 'ie',
    'portugal' => 'pt',
    'romania' => 'ro',
    'slovakia' => 'sk',
    'luxembourg' => 'lu',
    _ => 'eu',
  };

  /// URL to country flag from flagcdn.com (20px width for compact display)
  String get flagUrl => 'https://flagcdn.com/w20/$countryCode.png';
}
