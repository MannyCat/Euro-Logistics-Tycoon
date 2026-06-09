class Garage {
  final String id;
  final String companyId;
  final int cityId;
  final int slots;
  final int maxSlots;
  final DateTime createdAt;

  const Garage({
    required this.id,
    required this.companyId,
    required this.cityId,
    required this.slots,
    required this.maxSlots,
    required this.createdAt,
  });

  factory Garage.fromJson(Map<String, dynamic> json) => Garage(
        id: json['id'] as String,
        companyId: json['company_id'] as String,
        cityId: (json['city_id'] as num).toInt(),
        slots: (json['slots'] as num).toInt(),
        maxSlots: (json['max_slots'] as num?)?.toInt() ?? 8,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  /// Used slots — must be computed externally based on trucks at this city.
  /// This field is 0 by default; callers should use `usedSlotsInCity(cityId)`
  /// from GameProvider for actual count.
  int get usedSlots => 0;

  /// Computed free slots (needs external used count).
  int freeSlots(int usedCount) => slots - usedCount;

  /// Whether the garage has no room left.
  bool isFull(int usedCount) => usedCount >= slots;

  /// Whether the garage is at maximum capacity (level).
  bool get isMaxLevel => slots >= maxSlots;

  /// Cost of the next expansion.
  /// Formula: 15000 * ((current_slots - 2) / 2 + 1)
  int get expansionCost {
    if (isMaxLevel) return 0;
    return 15000 * ((slots - 2) ~/ 2 + 1);
  }
}
