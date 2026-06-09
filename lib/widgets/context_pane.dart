import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../config/app_icons.dart';
import '../models/city.dart';
import '../widgets/country_flag.dart';

/// A slide-in right panel showing city details.
/// Used on the map instead of opening a dialog.
class ContextPane extends StatelessWidget {
  final City city;
  final Widget? content; // Optional custom content below city info
  final VoidCallback? onClose;

  const ContextPane({
    required this.city,
    this.content,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(left: BorderSide(color: Color(0xFF333333), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(-4, 0))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF333333))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CountryFlag(countryCode: city.countryCode, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(city.name, style: AppTheme.h2.copyWith(color: const Color(0xFFD0D0D0)), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onClose ?? () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(AppIcons.close, color: Color(0xFF666666), size: 16),
                  ),
                ),
              ],
            ),
          ),
          // City info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country & population
                Row(
                  children: [
                    Icon(AppIcons.public, size: 14, color: const Color(0xFF888888)),
                    const SizedBox(width: 6),
                    Text(city.country, style: AppTheme.bodySm),
                    const Spacer(),
                    Icon(AppIcons.users, size: 14, color: const Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Text('${(city.population / 1000).toStringAsFixed(0)}K', style: AppTheme.monoSm),
                  ],
                ),
                const SizedBox(height: 12),
                // Coordinates
                Row(
                  children: [
                    Icon(AppIcons.location, size: 14, color: const Color(0xFF888888)),
                    const SizedBox(width: 6),
                    Text('${city.latitude.toStringAsFixed(2)}, ${city.longitude.toStringAsFixed(2)}', style: AppTheme.monoSm),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFF333333)),
                // Custom content slot (contracts, warehouse actions, etc.)
                if (content != null) ...[
                  content!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
