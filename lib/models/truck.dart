class Truck {
  final String id;
  final String companyId;
  final String? driverId;
  final String truckType;
  final String name;
  final String status; // idle, loading, in_transit, maintenance
  final int condition;
  final double fuelLevel;
  final double maxFuel;
  final int? currentCityId;
  final int? originCityId;
  final int? destinationCityId;
  final String? contractId;
  final DateTime? departureTime;
  final DateTime? estimatedArrival;

  const Truck({
    required this.id,
    required this.companyId,
    this.driverId,
    required this.truckType,
    required this.name,
    required this.status,
    required this.condition,
    required this.fuelLevel,
    required this.maxFuel,
    this.currentCityId,
    this.originCityId,
    this.destinationCityId,
    this.contractId,
    this.departureTime,
    this.estimatedArrival,
  });

  factory Truck.fromJson(Map<String, dynamic> json) => Truck(
    id: json['id'] as String? ?? '',
    companyId: json['company_id'] as String? ?? '',
    driverId: json['driver_id'] as String?,
    truckType: json['truck_type'] as String? ?? 'light',
    name: json['name'] as String? ?? 'Truck',
    status: json['status'] as String? ?? 'idle',
    condition: (json['condition_pct'] as num?)?.toInt() ?? 100,
    fuelLevel: (json['fuel_level'] as num?)?.toDouble() ?? 100,
    maxFuel: (json['max_fuel'] as num?)?.toDouble() ?? 100,
    currentCityId: json['current_city_id'] as int?,
    originCityId: json['origin_city_id'] as int?,
    destinationCityId: json['destination_city_id'] as int?,
    contractId: json['contract_id'] as String?,
    departureTime: json['departure_time'] != null ? DateTime.tryParse(json['departure_time'] as String) : null,
    estimatedArrival: json['estimated_arrival'] != null ? DateTime.tryParse(json['estimated_arrival'] as String) : null,
  );

  bool get isInTransit => status == 'in_transit' || status == 'loading';
  bool get isIdle => status == 'idle';
  String get statusDisplay => switch (status) {
    'idle' => 'Готов',
    'loading' => 'Загрузка',
    'in_transit' => 'В пути',
    'maintenance' => 'Ремонт',
    _ => status,
  };
}
