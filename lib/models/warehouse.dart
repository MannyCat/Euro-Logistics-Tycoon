class Warehouse {
  final String id;
  final String companyId;
  final int cityId;
  final int level;
  final int capacity;
  final bool isActive;
  final DateTime purchasedAt;

  const Warehouse({
    required this.id,
    required this.companyId,
    required this.cityId,
    required this.level,
    required this.capacity,
    required this.isActive,
    required this.purchasedAt,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) => Warehouse(
    id: json['id'] as String? ?? '',
    companyId: json['company_id'] as String? ?? '',
    cityId: (json['city_id'] as num?)?.toInt() ?? 0,
    level: (json['level'] as num?)?.toInt() ?? 1,
    capacity: (json['capacity'] as num?)?.toInt() ?? 50,
    isActive: (json['is_active'] as bool?) ?? true,
    purchasedAt: DateTime.tryParse(json['purchased_at'] as String? ?? '') ?? DateTime.now(),
  );
}
