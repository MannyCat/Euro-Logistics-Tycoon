import 'package:flutter/material.dart';
import '../config/app_icons.dart';

class Transaction {
  final String id;
  final String type;
  final String description;
  final int amount;
  final DateTime createdAt;

  const Transaction({required this.id, required this.type, required this.description, required this.amount, required this.createdAt});

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String? ?? '',
    type: json['type'] as String? ?? '',
    description: json['description'] as String? ?? '',
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  bool get isIncome => amount > 0;

  IconData get typeIcon => switch (type) {
    'contract_completed' => AppIcons.checkCircle,
    'contract_accepted' => AppIcons.description,
    'truck_purchase' => AppIcons.truck,
    'truck_sale' => AppIcons.sell,
    'driver_hire' => AppIcons.personAdd,
    'refuel' => AppIcons.fuel,
    'repair' => AppIcons.wrench,
    'warehouse' => AppIcons.warehouses,
    'salary' => AppIcons.accountBalance,
    'clan_create' => AppIcons.shield,
    _ => AppIcons.finances,
  };

  Color get typeColor => switch (type) {
    'contract_completed' => const Color(0xFF66BB6A),
    'truck_purchase' => const Color(0xFF42A5F5),
    'truck_sale' => const Color(0xFFCE93D8),
    'driver_hire' => const Color(0xFF64B5F6),
    'refuel' => const Color(0xFFF5C542),
    'repair' => const Color(0xFFEF5350),
    'warehouse' => const Color(0xFF42A5F5),
    'salary' => const Color(0xFFEF5350),
    'clan_create' => const Color(0xFFCE93D8),
    _ => const Color(0xFF888888),
  };
}
