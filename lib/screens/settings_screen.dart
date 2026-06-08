import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Timer? _statsTimer;
  Duration _uptime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _uptime += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

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
                  const Text('Euro Logistics Tycoon', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Версия 1.1.0  •  Сессия: ${_fmtDuration(_uptime)}', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
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
                  _statRow('Баланс', GameConstants.formatMoney(company.money)),
                  _statRow('Уровень', 'Lv.${company.level}  (${company.xp} XP)'),
                  _statRow('Репутация', '${company.reputation}/${GameConstants.maxReputation}'),
                  const SizedBox(height: 8),
                  // XP progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (company.xp % GameConstants.xpPerLevel) / GameConstants.xpPerLevel,
                      backgroundColor: const Color(0xFF1A1A1A),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF5C542)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${GameConstants.xpPerLevel - (company.xp % GameConstants.xpPerLevel)} XP до след. уровня', style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
                ],
              ),
            ),

          if (company != null) const SizedBox(height: 10),

          // Fleet stats
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Активность', style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniStat(Icons.local_shipping, '${game.myTrucks.length}', 'Грузовиков'),
                    _miniStat(Icons.people, '${game.myDrivers.length}', 'Водителей'),
                    _miniStat(Icons.warehouse, '${game.myWarehouses.length}', 'Складов'),
                    _miniStat(Icons.description, '${game.availableContracts.length}', 'Контрактов'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // User info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: Color(0xFFF5C542), size: 20),
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
                const Text('Советы', style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _tip(Icons.local_shipping, 'Купите грузовики — без них нет рейсов'),
                const SizedBox(height: 6),
                _tip(Icons.description, 'Примите контракт — грузовик сам поедет'),
                const SizedBox(height: 6),
                _tip(Icons.build, 'Следите за топливом и состоянием'),
                const SizedBox(height: 6),
                _tip(Icons.warehouse, 'Склады в городах расширяют сеть'),
                const SizedBox(height: 6),
                _tip(Icons.star, 'Выполняйте рейсы для опыта и уровней'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Logout
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
                  title: const Text('Выйти?', style: TextStyle(color: Color(0xFFD0D0D0))),
                  content: const Text('Вы уверены что хотите выйти из аккаунта?', style: TextStyle(color: Color(0xFF888888))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888)))),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти', style: TextStyle(color: Color(0xFFEF5350)))),
                  ],
                ),
              );
              if (confirm == true) {
                if (mounted) await auth.logout();
              }
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
        Expanded(child: Text(value, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
      ],
    ),
  );

  Widget _miniStat(IconData icon, String value, String label) => Column(
    children: [
      Icon(icon, size: 18, color: const Color(0xFFF5C542)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Color(0xFFD0D0D0), fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'monospace')),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
    ],
  );

  Widget _tip(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFFF5C542).withOpacity(0.6)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF888888), fontSize: 12))),
    ],
  );
}
