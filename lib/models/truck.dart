import 'package:flutter/material.dart';

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

  // Upgrade fields
  final int engineLevel;    // 0-3
  final int tankLevel;      // 0-3
  final int cabinLevel;     // 0-3
  final String paintColor;  // 'default', 'red', 'blue', 'green', 'gold', 'black', 'white', 'purple'

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
    this.engineLevel = 0,
    this.tankLevel = 0,
    this.cabinLevel = 0,
    this.paintColor = 'default',
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
    engineLevel: (json['engine_level'] as num?)?.toInt() ?? 0,
    tankLevel: (json['tank_level'] as num?)?.toInt() ?? 0,
    cabinLevel: (json['cabin_level'] as num?)?.toInt() ?? 0,
    paintColor: json['paint_color'] as String? ?? 'default',
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

  // Upgrade computed getters
  double get speedBonus => engineLevel * 0.10; // +10% per level
  double get fuelCapacityBonus => tankLevel * 0.20; // +20% per level (already applied to max_fuel in DB)
  double get reliabilityBonus => cabinLevel * 0.25; // -25% condition loss per level
  Color get paintColorValue => _colorFromName(paintColor);

  static Color _colorFromName(String name) => switch (name) {
    'red' => const Color(0xFFEF5350),
    'blue' => const Color(0xFF42A5F5),
    'green' => const Color(0xFF66BB6A),
    'gold' => const Color(0xFFF5C542),
    'black' => const Color(0xFF212121),
    'white' => const Color(0xFFEEEEEE),
    'purple' => const Color(0xFFCE93D8),
    _ => const Color(0xFF90A4AE), // default silver
  };
}
