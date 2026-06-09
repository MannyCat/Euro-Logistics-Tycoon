import 'package:flutter/material.dart';
import '../config/app_icons.dart';

class ClanMission {
  final String id;
  final String missionType;
  final String title;
  final String description;
  final int targetValue;
  final int currentProgress;
  final int rewardXp;
  final int rewardMoney;
  final DateTime expiresAt;
  final bool completed;

  const ClanMission({
    required this.id,
    required this.missionType,
    required this.title,
    this.description = '',
    required this.targetValue,
    this.currentProgress = 0,
    this.rewardXp = 500,
    this.rewardMoney = 0,
    required this.expiresAt,
    this.completed = false,
  });

  factory ClanMission.fromJson(Map<String, dynamic> json) {
    return ClanMission(
      id: json['id'] as String,
      missionType: json['mission_type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetValue: (json['target_value'] as num?)?.toInt() ?? 0,
      currentProgress: (json['current_progress'] as num?)?.toInt() ?? 0,
      rewardXp: (json['reward_xp'] as num?)?.toInt() ?? 500,
      rewardMoney: (json['reward_money'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.parse(json['expires_at'] as String? ?? DateTime.now().toIso8601String()),
      completed: json['completed'] as bool? ?? false,
    );
  }

  double get progressPercent => targetValue > 0 ? (currentProgress / targetValue).clamp(0.0, 1.0) : 0.0;

  String get timeLeft {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 'Просрочено';
    final diff = expiresAt.difference(now);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) return '$daysд ${hours}ч';
    if (hours > 0) return '$hoursч ${minutes}м';
    return '${minutes}м';
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  IconData get missionIcon => switch (missionType) {
    'deliver_cargo' => AppIcons.inventory2,
    'earn_money' => AppIcons.euro,
    'deliver_cities' => AppIcons.locationCity,
    _ => AppIcons.assignmentOutlined,
  };

  Color get progressColor => completed ? const Color(0xFF66BB6A) : const Color(0xFFF5C542);

  String get typeLabel => switch (missionType) {
    'deliver_cargo' => 'Доставка',
    'earn_money' => 'Заработок',
    'deliver_cities' => 'Города',
    _ => 'Задание',
  };

  String get progressText {
    if (missionType == 'earn_money') {
      return '${(currentProgress / 1000).toStringAsFixed(0)}K / ${(targetValue / 1000).toStringAsFixed(0)}K';
    }
    if (missionType == 'deliver_cargo') {
      return '${(currentProgress / 10).toStringAsFixed(0)}т / ${(targetValue / 10).toStringAsFixed(0)}т';
    }
    return '$currentProgress / $targetValue';
  }
}