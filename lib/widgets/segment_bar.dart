import 'package:flutter/material.dart';

/// A segmented progress bar divided into 10 equal segments.
class SegmentBar extends StatelessWidget {
  final int value; // 0-100
  final int segments; // default 10
  final double height;
  final Color activeColor;
  final Color inactiveColor;
  final double spacing;

  const SegmentBar({
    required this.value,
    this.segments = 10,
    this.height = 6,
    this.activeColor = const Color(0xFF42A5F5),
    this.inactiveColor = const Color(0xFF1A1A1A),
    this.spacing = 2,
  });

  int get _filledSegments => (value / (100 / segments)).clamp(0, segments).round();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(segments, (i) {
        final isActive = i < _filledSegments;
        return Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.only(right: i < segments - 1 ? spacing : 0),
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        );
      }),
    );
  }
}
