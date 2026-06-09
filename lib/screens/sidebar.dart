import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import 'contracts_screen.dart';
import 'fleet_screen.dart';
import 'drivers_screen.dart';
import 'warehouses_screen.dart';
import 'transactions_screen.dart';
import 'settings_screen.dart';
import 'achievements_screen.dart';
import 'leaderboard_screen.dart';
import 'clan_screen.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback onRefresh;
  final void Function(Widget modal) onOpenModal;

  const Sidebar({super.key, required this.onRefresh, required this.onOpenModal});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final company = game.company;

    return Container(
      width: 230,
      decoration: BoxDecoration(color: AppTheme.surface, border: Border(right: BorderSide(color: AppTheme.divider))),
      child: Column(
        children: [
          // Logo
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: const Color(0xFFF5C542).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.local_shipping, color: Color(0xFFF5C542), size: 18),
              ),
              const SizedBox(width: 10),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('ELT', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2)),
              ]),
            ]),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          // Navigation — all modals
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                _navItem(Icons.description_outlined, 'Контракты', 'C', () => onOpenModal(const ContractsScreen()), badge: game.myContracts.isNotEmpty ? game.myContracts.length : null),
                _navItem(Icons.local_shipping_outlined, 'Автопарк', 'F', () => onOpenModal(const FleetScreen()), badge: game.idleTrucks.isNotEmpty ? game.idleTrucks.length : null),
                _navItem(Icons.people_outlined, 'Водители', 'D', () => onOpenModal(const DriversScreen())),
                _navItem(Icons.warehouse_outlined, 'Филиалы', 'W', () => onOpenModal(const WarehousesScreen())),
                _navItem(Icons.receipt_long_outlined, 'Финансы', 'T', () => onOpenModal(const TransactionsScreen())),
                const Divider(height: 1, color: AppTheme.divider, indent: 12, endIndent: 12),
                _navItem(Icons.emoji_events_outlined, 'Рейтинг', 'L', () => onOpenModal(const LeaderboardScreen())),
                _navItem(Icons.military_tech_outlined, 'Достижения', 'A', () => onOpenModal(const AchievementsScreen())),
                _navItem(Icons.shield_outlined, 'Кланы', 'G', () => onOpenModal(const ClanScreen())),
                const Divider(height: 1, color: AppTheme.divider, indent: 12, endIndent: 12),
                _navItem(Icons.settings_outlined, 'Настройки', null, () => onOpenModal(const SettingsScreen())),
              ],
            ),
          ),

          // Company info footer
          if (company != null) Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.divider))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(company.name, style: AppTheme.labelSm, overflow: TextOverflow.ellipsis, maxLines: 1)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppTheme.textMuted, size: 16),
                  tooltip: 'Обновить',
                  onPressed: onRefresh,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('Реп: ${company.reputation}', style: AppTheme.bodySm),
                const SizedBox(width: 12),
                Text('XP: ${company.xp}', style: AppTheme.bodySm),
                const Spacer(),
                Text('Lv.${company.level}', style: AppTheme.monoSm.copyWith(color: const Color(0xFFF5C542))),
              ]),
            ]),
          ),

          // Logout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.divider))),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async { await auth.logout(); },
                icon: const Icon(Icons.logout, color: AppTheme.red, size: 16),
                label: const Text('Выйти', style: TextStyle(color: AppTheme.red)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.red.withOpacity(0.3))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, String? shortcut, VoidCallback onTap, {int? badge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Tooltip(
            message: shortcut != null ? '$label ($shortcut)' : label,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Icon(icon, color: const Color(0xFF999999), size: 18),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                )),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5C542).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF5C542).withOpacity(0.4), width: 0.5),
                    ),
                    child: Text('$badge', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                if (shortcut != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(shortcut, style: const TextStyle(color: Color(0xFF666666), fontSize: 10, fontFamily: 'monospace')),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
