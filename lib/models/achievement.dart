import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String companyId;
  final DateTime unlockedAt;

  const Achievement({required this.id, required this.companyId, required this.unlockedAt});

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['achievement_id'] as String? ?? '',
    companyId: json['company_id'] as String? ?? '',
    unlockedAt: DateTime.tryParse(json['unlocked_at'] as String? ?? '') ?? DateTime.now(),
  );
}
