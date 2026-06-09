import 'package:flutter/material.dart';
import '../config/app_icons.dart';

/// A single step in the delivery timeline.
class TimelineStep {
  final String label;
  final String? timestamp;
  final IconData icon;
  final Color color;
  final bool isComplete;
  final bool isCurrent;

  const TimelineStep({
    required this.label,
    this.timestamp,
    required this.icon,
    required this.color,
    this.isComplete = false,
    this.isCurrent = false,
  });
}

/// A vertical timeline widget showing delivery status progression.
/// Used in truck detail views and contract screens.
class DeliveryTimeline extends StatelessWidget {
  final List<TimelineStep> steps;

  const DeliveryTimeline({required this.steps, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + vertical line
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: step.isComplete || step.isCurrent
                        ? step.color.withOpacity(0.15)
                        : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: step.isComplete || step.isCurrent
                          ? step.color.withOpacity(0.4)
                          : const Color(0xFF333333),
                    ),
                  ),
                  child: Icon(
                    step.icon,
                    size: 14,
                    color: step.isComplete || step.isCurrent
                        ? step.color
                        : const Color(0xFF555555),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 28,
                    color: step.isComplete
                        ? step.color.withOpacity(0.4)
                        : const Color(0xFF333333),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    step.label,
                    style: TextStyle(
                      color: step.isComplete || step.isCurrent
                          ? const Color(0xFFD0D0D0)
                          : const Color(0xFF666666),
                      fontSize: 12,
                      fontWeight: step.isCurrent ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (step.timestamp != null)
                    Text(
                      step.timestamp!,
                      style: const TextStyle(color: Color(0xFF555555), fontSize: 10),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
