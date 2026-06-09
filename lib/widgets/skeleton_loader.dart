import 'package:flutter/material.dart';

/// Static skeleton placeholder for loading states.
/// No animation to keep it simple — just a gray rounded rectangle.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: const Color(0xFF2A2A2A),
      ),
    );
  }
}

/// A skeleton row that mimics a list item layout.
class SkeletonListItem extends StatelessWidget {
  final bool hasIcon;
  final bool hasSubtitle;

  const SkeletonListItem({this.hasIcon = true, this.hasSubtitle = true, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasIcon)
            const SkeletonBox(width: 36, height: 36, borderRadius: 8),
          if (hasIcon) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 14, width: 180),
                if (hasSubtitle) ...[
                  const SizedBox(height: 6),
                  const SkeletonBox(height: 10, width: 120),
                ],
              ],
            ),
          ),
          const SkeletonBox(width: 50, height: 14, borderRadius: 3),
        ],
      ),
    );
  }
}

/// A skeleton card placeholder.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 40, height: 40, borderRadius: 8),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, width: 160),
                    SizedBox(height: 6),
                    SkeletonBox(height: 10, width: 100),
                  ],
                ),
              ),
              const SkeletonBox(width: 40, height: 40, borderRadius: 8),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonBox(height: 8),
          const SizedBox(height: 6),
          const SkeletonBox(height: 8, width: 200),
        ],
      ),
    );
  }
}
