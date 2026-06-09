import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_icons.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import 'map_screen.dart';
import 'contracts_screen.dart';
import 'fleet_screen.dart';
import 'drivers_screen.dart';
import 'warehouses_screen.dart';
import 'transactions_screen.dart';
import 'settings_screen.dart';
import 'achievements_screen.dart';
import 'leaderboard_screen.dart';
import 'clan_screen.dart';
import 'event_log_screen.dart';
import 'market_screen.dart';
import 'analytics_screen.dart';

class MobileDrawer extends StatelessWidget {
  final void Function(Widget modal) onOpenModal;

  const MobileDrawer({super.key, required this.onOpenModal});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final company = game.company;

    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(AppIcons.truck, color: AppTheme.accent, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('ELT', style: TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 2)),
              ]),
            ),
            const Divider(height: 1, color: AppTheme.divider),

            // Company stats
            if (company != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppTheme.card,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(company.name, style: AppTheme.label, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    _miniStat(AppIcons.euro, company.moneyFormatted, AppTheme.green),
                    const SizedBox(width: 16),
                    _miniStat(AppIcons.star, 'Lv.${company.level}', AppTheme.accent),
                    const SizedBox(width: 16),
                    _miniStat(AppIcons.income, 'Rep.${company.reputation}', AppTheme.accentLight),
                  ]),
                ]),
              ),

            const SizedBox(height: 4),

            // Navigation — all modals
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _navItem(context, AppIcons.map, 'Карта', () {
                    Navigator.pop(context);
                  }),
                  _navItem(context, AppIcons.description, 'Контракты', () {
                    Navigator.pop(context);
                    onOpenModal(const ContractsScreen());
                  }),
                  _navItem(context, AppIcons.truck, 'Автопарк', () {
                    Navigator.pop(context);
                    onOpenModal(const FleetScreen());
                  }),
                  _navItem(context, AppIcons.drivers, 'Водители', () {
                    Navigator.pop(context);
                    onOpenModal(const DriversScreen());
                  }),
                  _navItem(context, AppIcons.warehouses, 'Филиалы', () {
                    Navigator.pop(context);
                    onOpenModal(const WarehousesScreen());
                  }),
                  _navItem(context, AppIcons.finances, 'Финансы', () {
                    Navigator.pop(context);
                    onOpenModal(const TransactionsScreen());
                  }),
                  _navItem(context, AppIcons.eventLog, 'Журнал', () {
                    Navigator.pop(context);
                    onOpenModal(const EventLogScreen());
                  }),
                  const Divider(height: 1, color: AppTheme.divider, indent: 16, endIndent: 16),
                  _navItem(context, AppIcons.leaderboard, 'Рейтинг', () {
                    Navigator.pop(context);
                    onOpenModal(const LeaderboardScreen());
                  }),
                  _navItem(context, AppIcons.achievements, 'Достижения', () {
                    Navigator.pop(context);
                    onOpenModal(const AchievementsScreen());
                  }),
                  _navItem(context, AppIcons.clan, 'Кланы', () {
                    Navigator.pop(context);
                    onOpenModal(const ClanScreen());
                  }),
                  _navItem(context, AppIcons.analytics, 'Аналитика', () {
                    Navigator.pop(context);
                    onOpenModal(const AnalyticsScreen());
                  }),
                  _navItem(context, AppIcons.market, 'Рынок', () {
                    Navigator.pop(context);
                    onOpenModal(const MarketScreen());
                  }),
                  const Divider(height: 1, color: AppTheme.divider, indent: 16, endIndent: 16),
                  _navItem(context, AppIcons.settings, 'Настройки', () {
                    Navigator.pop(context);
                    onOpenModal(const SettingsScreen());
                  }),
                ],
              ),
            ),

            // Logout
            Container(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await auth.logout();
                },
                icon: const Icon(AppIcons.logOut, color: AppTheme.red, size: 16),
                label: const Text('Выйти', style: TextStyle(color: AppTheme.red)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: AppTheme.red.withOpacity(0.3))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 3),
    Text(value, style: AppTheme.monoSm.copyWith(color: color, fontWeight: FontWeight.bold)),
  ]);

  Widget _navItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Icon(icon, color: AppTheme.textMuted, size: 20),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w400)),
            ]),
          ),
        ),
      ),
    );
  }
}
