import 'package:flutter/material.dart';
import '../config/app_icons.dart';

class EventLog {
  final String id;
  final String companyId;
  final String eventType;
  final String title;
  final String description;
  final String iconName;
  final String colorHex;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const EventLog({
    required this.id,
    required this.companyId,
    required this.eventType,
    required this.title,
    required this.description,
    required this.iconName,
    required this.colorHex,
    required this.metadata,
    required this.createdAt,
  });

  factory EventLog.fromJson(Map<String, dynamic> json) => EventLog(
    id: json['id'] as String? ?? '',
    companyId: json['company_id'] as String? ?? '',
    eventType: json['event_type'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    iconName: json['icon_name'] as String? ?? 'info',
    colorHex: json['color_hex'] as String? ?? '66BB6A',
    metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  // Helper getters
  IconData get icon => _iconFromName(iconName);
  Color get color => _colorFromHex(colorHex);
  String get timeAgo => _formatTimeAgo(createdAt);
  int? get moneyAmount => metadata['amount'] as int?;

  /// Whether this event belongs to the finance filter group
  bool get isFinance => const [
    'money_earned', 'refuel', 'repair', 'truck_purchased', 'truck_sold', 'warehouse_bought',
  ].contains(eventType);

  /// Whether this event belongs to the fleet filter group
  bool get isFleet => const [
    'truck_purchased', 'truck_sold', 'refuel', 'repair', 'contract_completed', 'contract_accepted',
  ].contains(eventType);

  /// Whether this event belongs to the drivers filter group
  bool get isDrivers => const [
    'driver_hired', 'driver_fired',
  ].contains(eventType);

  /// Whether this event belongs to the clans filter group
  bool get isClan => const [
    'clan_joined', 'clan_created', 'clan_left',
  ].contains(eventType);

  /// Whether this is an achievement event (for special styling)
  bool get isAchievement => const [
    'achievement_unlocked', 'level_up',
  ].contains(eventType);

  /// Whether this is a warning event (for red styling)
  bool get isWarning => eventType == 'warning';

  static IconData _iconFromName(String name) => switch (name) {
    'contract_completed' => AppIcons.checkCircle,
    'contract_accepted' => AppIcons.truck,
    'truck_purchased' => AppIcons.addCircle,
    'truck_sold' => AppIcons.sell,
    'driver_hired' => AppIcons.personAdd,
    'driver_fired' => AppIcons.personRemove,
    'money_earned' => AppIcons.euro,
    'level_up' => AppIcons.arrowUp,
    'achievement' => AppIcons.militaryTech,
    'refuel' => AppIcons.gasStation,
    'repair' => AppIcons.wrench,
    'warehouse' => AppIcons.warehouses,
    'clan' => AppIcons.shield,
    'warning' => AppIcons.warning,
    _ => AppIcons.info,
  };

  static Color _colorFromHex(String hex) {
    final parsed = int.tryParse('FF$hex', radix: 16);
    if (parsed == null) return const Color(0xFF66BB6A);
    return Color(parsed);
  }

  static String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes}м назад';
    if (diff.inHours < 24) return '${diff.inHours}ч назад';
    return '${diff.inDays}д назад';
  }
}
