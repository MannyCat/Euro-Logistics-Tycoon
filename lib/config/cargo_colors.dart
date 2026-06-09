import 'package:flutter/material.dart';

/// Centralized color coding for cargo types.
/// Used across markers, badges, timeline, and contract cards.
class CargoColors {
  CargoColors._();

  static const Color container = Color(0xFF42A5F5);    // Blue — containers
  static const Color bulk = Color(0xFFFF9800);           // Orange — bulk cargo
  static const Color hazardous = Color(0xFFEF5350);     // Red — hazardous
  static const Color refrigerated = Color(0xFF00BCD4);   // Cyan — refrigerated
  static const Color living = Color(0xFF66BB6A);         // Green — living goods
  static const Color default_ = Color(0xFF9E9E9E);       // Gray — unspecified

  /// Returns color for a cargo type string.
  static Color forType(String type) => switch (type.toLowerCase()) {
    'container' || 'containers' || 'контейнер' || 'контейнеры' => container,
    'bulk' || 'насыпной' || 'насыпные' => bulk,
    'hazardous' || 'dangerous' || 'опасный' || 'опасные' => hazardous,
    'refrigerated' || 'refrigerator' || 'рефрижератор' => refrigerated,
    'living' || 'жилой' || 'живой' => living,
    _ => default_,
  };

  /// Returns a lighter version for backgrounds.
  static Color bgForType(String type) => forType(type).withOpacity(0.12);

  /// Returns a darker version for borders.
  static Color borderForType(String type) => forType(type).withOpacity(0.3);
}
