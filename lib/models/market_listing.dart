import 'package:flutter/material.dart';

class MarketListing {
  final String id;
  final String sellerId;
  final String listingType;
  final String itemId;
  final String itemName;
  final Map<String, dynamic> itemDetails;
  final int price;
  final DateTime createdAt;
  final DateTime expiresAt;

  const MarketListing({
    required this.id,
    required this.sellerId,
    required this.listingType,
    required this.itemId,
    required this.itemName,
    required this.itemDetails,
    required this.price,
    required this.createdAt,
    required this.expiresAt,
  });

  factory MarketListing.fromJson(Map<String, dynamic> json) => MarketListing(
    id: json['id'] as String? ?? '',
    sellerId: json['seller_id'] as String? ?? '',
    listingType: json['listing_type'] as String? ?? '',
    itemId: json['item_id'] as String? ?? '',
    itemName: json['item_name'] as String? ?? '',
    itemDetails: (json['item_details'] as Map<String, dynamic>?) ?? {},
    price: (json['price'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '') ?? DateTime.now().add(const Duration(hours: 72)),
  );

  /// Returns human-readable time remaining string in Russian
  String get timeLeft {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Истёк';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    if (days > 0) return '${days}д ${hours}ч';
    if (hours > 0) return '${hours}ч ${minutes}м';
    return '${minutes}м';
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Truck type from item details (for truck listings)
  String get truckType => itemDetails['truck_type'] as String? ?? '';
  int get condition => (itemDetails['condition'] as num?)?.toInt() ?? 100;
}
