class Contract {
  final String id;
  final int originCityId;
  final int destinationCityId;
  final String cargoType;
  final int cargoWeight;
  final int reward;
  final int deadlineHours;
  final String status;
  final String? assignedCompanyId;
  final String? assignedTruckId;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const Contract({
    required this.id,
    required this.originCityId,
    required this.destinationCityId,
    required this.cargoType,
    required this.cargoWeight,
    required this.reward,
    required this.deadlineHours,
    required this.status,
    this.assignedCompanyId,
    this.assignedTruckId,
    required this.createdAt,
    this.expiresAt,
  });

  factory Contract.fromJson(Map<String, dynamic> json) => Contract(
    id: json['id'] as String? ?? '',
    originCityId: json['origin_city_id'] as int? ?? 0,
    destinationCityId: json['destination_city_id'] as int? ?? 0,
    cargoType: json['cargo_type'] as String? ?? '',
    cargoWeight: (json['cargo_weight'] as num?)?.toInt() ?? 10,
    reward: (json['reward'] as num?)?.toInt() ?? 0,
    deadlineHours: (json['deadline_hours'] as num?)?.toInt() ?? 48,
    status: json['status'] as String? ?? 'available',
    assignedCompanyId: json['assigned_company_id'] as String?,
    assignedTruckId: json['assigned_truck_id'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
  );

  bool get isAvailable => status == 'available';
  bool get isAccepted => status == 'accepted';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
