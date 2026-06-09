class Driver {
  final String id;
  final String companyId;
  final String name;
  final int skillLevel;
  final int salaryDaily;
  final String status;
  final String? assignedTruckId;
  final int xp;
  final int tripsCompleted;
  final int fatigue; // 0-100
  final int speedSkill;
  final int fuelEfficiencySkill;
  final int reliabilitySkill;
  final DateTime? lastTripAt;

  const Driver({
    required this.id,
    required this.companyId,
    required this.name,
    required this.skillLevel,
    required this.salaryDaily,
    required this.status,
    this.assignedTruckId,
    this.xp = 0,
    this.tripsCompleted = 0,
    this.fatigue = 0,
    this.speedSkill = 0,
    this.fuelEfficiencySkill = 0,
    this.reliabilitySkill = 0,
    this.lastTripAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    id: json['id'] as String? ?? '',
    companyId: json['company_id'] as String? ?? '',
    name: json['name'] as String? ?? 'Driver',
    skillLevel: (json['skill_level'] as num?)?.toInt() ?? 1,
    salaryDaily: (json['salary_daily'] as num?)?.toInt() ?? 300,
    status: json['status'] as String? ?? 'available',
    assignedTruckId: json['assigned_truck_id'] as String?,
    xp: (json['xp'] as num?)?.toInt() ?? 0,
    tripsCompleted: (json['trips_completed'] as num?)?.toInt() ?? 0,
    fatigue: (json['fatigue'] as num?)?.toInt() ?? 0,
    speedSkill: (json['speed_skill'] as num?)?.toInt() ?? 0,
    fuelEfficiencySkill: (json['fuel_efficiency_skill'] as num?)?.toInt() ?? 0,
    reliabilitySkill: (json['reliability_skill'] as num?)?.toInt() ?? 0,
    lastTripAt: json['last_trip_at'] != null ? DateTime.tryParse(json['last_trip_at'] as String) : null,
  );

  bool get isAvailable => status == 'available';
  bool get isResting => status == 'resting';
  bool get isAssigned => status == 'assigned';
  bool get isInTransit => status == 'in_transit';
  bool get isExhausted => fatigue >= 90;
  bool get isTired => fatigue >= 50;

  int get xpToNextLevel => skillLevel < 20 ? 100 - (xp % 100) : 0;
  double get speedBonus => speedSkill * 0.003; // max 30% at 100
  double get fuelBonus => fuelEfficiencySkill * 0.003; // max 30% at 100
  double get reliabilityBonus => reliabilitySkill * 0.005; // max 50% at 100

  String get skillLevelDisplay => 'Ур. $skillLevel';
  String get statusDisplay => switch (status) {
    'available' => 'Свободен',
    'assigned' => 'Назначен',
    'resting' => 'Отдыхает',
    'in_transit' => 'В рейсе',
    _ => status,
  };
}
