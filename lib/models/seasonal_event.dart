import 'package:flutter/material.dart';

class SeasonalEvent {
  final String id;
  final String eventKey;
  final String title;
  final String description;
  final String eventType;
  final double multiplier;
  final String? cargoType;
  final int targetDeliveries;
  final int rewardXp;
  final int rewardMoney;
  final DateTime endsAt;

  const SeasonalEvent({
    required this.id,
    required this.eventKey,
    required this.title,
    required this.description,
    required this.eventType,
    required this.multiplier,
    this.cargoType,
    required this.targetDeliveries,
    required this.rewardXp,
    required this.rewardMoney,
    required this.endsAt,
  });

  factory SeasonalEvent.fromJson(Map<String, dynamic> json) => SeasonalEvent(
    id: json['id'] as String? ?? '',
    eventKey: json['event_key'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    eventType: json['event_type'] as String? ?? '',
    multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1.0,
    cargoType: json['cargo_type'] as String?,
    targetDeliveries: (json['target_deliveries'] as num?)?.toInt() ?? 0,
    rewardXp: (json['reward_xp'] as num?)?.toInt() ?? 0,
    rewardMoney: (json['reward_money'] as num?)?.toInt() ?? 0,
    endsAt: json['ends_at'] != null
        ? DateTime.parse(json['ends_at'] as String)
        : DateTime.now().add(const Duration(hours: 48)),
  );

  String get timeLeft {
    final now = DateTime.now();
    if (endsAt.isBefore(now)) return 'Завершено';
    final diff = endsAt.difference(now);
    if (diff.inDays > 0) {
      final hours = diff.inHours % 24;
      return '${diff.inDays}д ${hours}ч';
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}ч ${minutes}м';
  }

  bool get isExpired => endsAt.isBefore(DateTime.now());

  String get multiplierLabel {
    if (eventType == 'cargo_bonus') {
      return 'x${multiplier.toStringAsFixed(1)} ${cargoType != null ? 'за $cargoType' : 'награда'}';
    }
    if (eventType == 'xp_boost') {
      return 'x${multiplier.toStringAsFixed(1)} XP';
    }
    return '';
  }

  String get typeLabel => switch (eventType) {
    'cargo_bonus' => 'Бонус груза',
    'delivery_challenge' => 'Челлендж',
    'xp_boost' => 'XP Буст',
    _ => 'Событие',
  };

  IconData get eventIcon => switch (eventType) {
    'cargo_bonus' => Icons.card_giftcard,
    'delivery_challenge' => Icons.emoji_events,
    'xp_boost' => Icons.bolt,
    _ => Icons.star,
  };

  Color get eventColor => switch (eventType) {
    'cargo_bonus' => const Color(0xFFEF5350),
    'delivery_challenge' => const Color(0xFFF5C542),
    'xp_boost' => const Color(0xFF42A5F5),
    _ => const Color(0xFF66BB6A),
  };

  Color get eventBgColor => switch (eventType) {
    'cargo_bonus' => const Color(0xFFEF5350).withOpacity(0.12),
    'delivery_challenge' => const Color(0xFFF5C542).withOpacity(0.12),
    'xp_boost' => const Color(0xFF42A5F5).withOpacity(0.12),
    _ => const Color(0xFF66BB6A).withOpacity(0.12),
  };
}
