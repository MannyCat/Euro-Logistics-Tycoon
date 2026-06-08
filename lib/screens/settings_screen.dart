import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final userId = auth.userId ?? '';
    final company = game.company;

    return ETS2Modal(
      title: 'Настройки',
      icon: Icons.settings,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // App info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
            child: Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF5C542).withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.local_shipping, color: Color(0xFFF5C542), size: 22)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Euro Logistics Tycoon', style: AppTheme.h2.copyWith(color: const Color(0xFFD0D0D0))),
                  const SizedBox(height: 2),
                  const Text('Версия 1.0.0 — Прототип', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Company stats
          if (company != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Статистика компании', style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  _statRow('Название', company.name),
                  _statRow('Баланс', '\u20AC${company.money}'),
                  _statRow('Уровень', '${company.level}'),
                  _statRow('Репутация', '${company.reputation}/100'),
                  _statRow('Опыт', '${company.xp} XP'),
                ],
              ),
            ),

          if (company != null) const SizedBox(height: 10),

          // User info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Color(0xFF42A5F5), size: 20),
                const SizedBox(width: 10),
                const Text('Профиль', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('ID: ${userId.length > 12 ? '${userId.substring(0, 12)}...' : userId}', style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontFamily: 'monospace')),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Game tips
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Руководство', style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _tip(Icons.local_shipping, 'Купите грузовики в разделе "Автопарк"'),
                const SizedBox(height: 6),
                _tip(Icons.description, 'Примите контракт из списка доступных'),
                const SizedBox(height: 6),
                _tip(Icons.people, 'Нанимайте водителей для расширения бизнеса'),
                const SizedBox(height: 6),
                _tip(Icons.build, 'Следите за состоянием грузовиков: заправка и ремонт'),
                const SizedBox(height: 6),
                _tip(Icons.warehouse, 'Покупайте склады в городах для расширения сети'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Logout
          OutlinedButton.icon(
            onPressed: () async {
              await auth.logout();
            },
            icon: const Icon(Icons.logout, color: Color(0xFFEF5350)),
            label: const Text('Выйти из аккаунта', style: TextStyle(color: Color(0xFFEF5350))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEF5350)),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
        Text(value, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    ),
  );

  Widget _tip(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF666666)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF888888), fontSize: 12))),
    ],
  );
}
