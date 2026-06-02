import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class VoyageProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? etaText;
  final double? height;

  const VoyageProgressBar({
    super.key,
    required this.progress,
    this.etaText,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clampedProgress,
            minHeight: height ?? 8,
            backgroundColor: AppTheme.inputBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
          ),
        ),
        if (etaText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(clampedProgress * 100).toStringAsFixed(1)}%',
                  style: AppTheme.monoNumberSmall.copyWith(
                    color: AppTheme.accentBlue,
                  ),
                ),
                Text(
                  etaText!,
                  style: AppTheme.bodyTextSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
