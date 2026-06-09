import 'package:flutter/material.dart';

/// Compact country flag widget using flagcdn.com CDN.
class CountryFlag extends StatelessWidget {
  final String countryCode; // 2-letter ISO code (e.g., 'de', 'fr')
  final double size;
  final double borderRadius;

  const CountryFlag({
    required this.countryCode,
    this.size = 14,
    this.borderRadius = 2,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        'https://flagcdn.com/w40/$countryCode.png',
        width: size,
        height: size * 0.67, // flags are roughly 3:2 aspect ratio
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size * 0.67,
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: const Center(
            child: Text('?', style: TextStyle(color: Color(0xFF666666), fontSize: 8)),
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size * 0.67,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          );
        },
      ),
    );
  }
}
