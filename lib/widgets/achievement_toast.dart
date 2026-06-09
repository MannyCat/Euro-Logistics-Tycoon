import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_icons.dart';
import '../config/game_constants.dart';
import '../providers/game_provider.dart';

/// Lightweight overlay that shows queued achievement unlock notifications.
/// Wraps a [child] widget and renders animated toasts at the top-right.
class AchievementToastOverlay extends StatefulWidget {
  final Widget child;

  const AchievementToastOverlay({super.key, required this.child});

  @override
  State<AchievementToastOverlay> createState() => _AchievementToastOverlayState();
}

class _AchievementToastOverlayState extends State<AchievementToastOverlay>
    with SingleTickerProviderStateMixin {
  /// Queue of achievement IDs waiting to be shown.
  final List<String> _queue = [];

  /// Currently visible toast entry (null when idle).
  String? _currentId;

  Timer? _dismissTimer;
  Timer? _queueTimer;

  @override
  void initState() {
    super.initState();
    // Check the queue periodically to pop the next toast.
    _queueTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_currentId == null && _queue.isNotEmpty) {
        _showNext();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _queueTimer?.cancel();
    super.dispose();
  }

  /// Enqueue one or more newly-unlocked achievement IDs for display.
  void enqueue(List<String> ids) {
    for (final id in ids) {
      if (!_queue.contains(id) && id != _currentId) {
        _queue.add(id);
      }
    }
  }

  void _showNext() {
    if (_queue.isEmpty) return;
    final id = _queue.removeAt(0);
    setState(() => _currentId = id);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _currentId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentId != null)
          Positioned(
            top: 60,
            right: 12,
            child: _AchievementToast(
              key: ValueKey(_currentId),
              achievementId: _currentId!,
              onDismiss: () {
                _dismissTimer?.cancel();
                if (mounted) setState(() => _currentId = null);
              },
            ),
          ),
      ],
    );
  }
}

/// A single animated toast card for an achievement notification.
class _AchievementToast extends StatefulWidget {
  final String achievementId;
  final VoidCallback onDismiss;

  const _AchievementToast({super.key, required this.achievementId, required this.onDismiss});

  @override
  State<_AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<_AchievementToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.2, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.outBack));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final def = GameConstants.achievements.where((a) => a.id == widget.achievementId).firstOrNull;
    final name = def?.name ?? widget.achievementId;
    final description = def?.description ?? '';
    final icon = def?.icon ?? AppIcons.militaryTech;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFF5C542).withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF5C542).withOpacity(0.12),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Gold glow icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5C542).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFF5C542).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: const Color(0xFFF5C542), size: 20),
                ),
                const SizedBox(width: 12),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            AppIcons.militaryTech,
                            color: Color(0xFFF5C542),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'ДОСТИЖЕНИЕ',
                            style: TextStyle(
                              color: Color(0xFFF5C542),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFFD0D0D0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Dismiss
                Icon(AppIcons.close, color: const Color(0xFF666666), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}