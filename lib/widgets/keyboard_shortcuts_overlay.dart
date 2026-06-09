import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_icons.dart';

/// A modal overlay showing all keyboard shortcuts.
/// Triggered by Ctrl+/ or the ? button in the top bar.
class KeyboardShortcutsOverlay extends StatelessWidget {
  const KeyboardShortcutsOverlay({super.key});

  static const _shortcuts = [
    ('C', 'Контракты', AppIcons.description),
    ('F', 'Автопарк', AppIcons.truck),
    ('D', 'Водители', AppIcons.users),
    ('W', 'Филиалы', AppIcons.warehouses),
    ('T', 'Финансы', AppIcons.finances),
    ('H', 'Журнал событий', AppIcons.eventLog),
    ('M', 'Рынок', AppIcons.market),
    ('L', 'Рейтинг', AppIcons.leaderboard),
    ('A', 'Достижения', AppIcons.militaryTech),
    ('G', 'Кланы', AppIcons.clan),
    ('B', 'Аналитика', AppIcons.analytics),
    ('R', 'Обновить данные', AppIcons.refresh),
    ('Esc', 'Закрыть диалог', AppIcons.close),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF444444)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30, spreadRadius: 4),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.settings, color: const Color(0xFFF5C542), size: 18),
                const SizedBox(width: 10),
                const Text('Горячие клавиши', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(AppIcons.close, color: Color(0xFF666666), size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._shortcuts.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFF444444), width: 0.5),
                    ),
                    child: Text(s.$1, style: const TextStyle(color: Color(0xFF999999), fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                  ),
                  const SizedBox(width: 14),
                  Icon(s.$3, color: const Color(0xFF888888), size: 16),
                  const SizedBox(width: 10),
                  Text(s.$2, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13)),
                ],
              ),
            )),
            const SizedBox(height: 12),
            const Text('Нажмите Ctrl+/ чтобы открыть', style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
