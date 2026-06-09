import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_icons.dart';
import '../config/app_theme.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.timestamp,
    this.isRead = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes}м назад';
    if (diff.inHours < 24) return '${diff.inHours}ч назад';
    return '${diff.inDays}д назад';
  }
}

/// Slide-out notification panel from the right edge.
class NotificationPanel extends StatelessWidget {
  final List<NotificationItem> notifications;
  final VoidCallback? onClearAll;
  final VoidCallback? onClose;

  const NotificationPanel({
    required this.notifications,
    this.onClearAll,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(left: BorderSide(color: Color(0xFF333333))),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF333333))),
            ),
            child: Row(
              children: [
                Icon(AppIcons.eventLog, color: const Color(0xFF42A5F5), size: 16),
                const SizedBox(width: 8),
                Text('Уведомления', style: AppTheme.h3.copyWith(color: const Color(0xFFD0D0D0))),
                const Spacer(),
                Text('${notifications.length}', style: AppTheme.monoSm),
                const SizedBox(width: 8),
                if (onClearAll != null)
                  InkWell(
                    onTap: onClearAll,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text('Очистить', style: AppTheme.bodySm.copyWith(color: const Color(0xFF666666))),
                    ),
                  ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onClose ?? () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(AppIcons.close, color: const Color(0xFF666666), size: 14),
                  ),
                ),
              ],
            ),
          ),
          // Notification list
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.eventLog, size: 32, color: const Color(0xFF444444)),
                        const SizedBox(height: 8),
                        Text('Нет уведомлений', style: AppTheme.bodySm),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) => _NotificationCard(item: notifications[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: item.isRead ? const Color(0xFF1E1E1E) : const Color(0xFF222222),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: item.isRead ? const Color(0xFF333333) : item.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(item.body, style: const TextStyle(color: Color(0xFF888888), fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(item.timeAgo, style: const TextStyle(color: Color(0xFF555555), fontSize: 10)),
        ],
      ),
    );
  }
}
