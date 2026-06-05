import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class MobileDrawer extends StatelessWidget {
  const MobileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final company = game.company;
    final currentPath = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;

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
                  child: const Icon(Icons.local_shipping, color: AppTheme.accent, size: 20),
                ),
                const SizedBox(width: 10),
                Text('ELT', style: AppTheme.h2.copyWith(fontSize: 16, letterSpacing: 2)),
              ]),
            ),
            const Divider(height: 1, color: AppTheme.divider),

            // Company stats
            if (company != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppTheme.card,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(company.name, style: AppTheme.label, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    _miniStat(Icons.euro, company.moneyFormatted, AppTheme.green),
                    const SizedBox(width: 16),
                    _miniStat(Icons.star, 'Lv.${company.level}', AppTheme.accent),
                    const SizedBox(width: 16),
                    _miniStat(Icons.trending_up, 'Rep.${company.reputation}', AppTheme.accentLight),
                  ]),
                ]),
              ),
            ],

            const SizedBox(height: 4),

            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _navItem(Icons.map_outlined, 'Карта', '/', currentPath, context),
                  _navItem(Icons.description_outlined, 'Контракты', '/contracts', currentPath, context),
                  _navItem(Icons.local_shipping_outlined, 'Автопарк', '/fleet', currentPath, context),
                  _navItem(Icons.people_outlined, 'Водители', '/drivers', currentPath, context),
                  _navItem(Icons.warehouse_outlined, 'Филиалы', '/warehouses', currentPath, context),
                  _navItem(Icons.receipt_long_outlined, 'Финансы', '/transactions', currentPath, context),
                  const Divider(height: 1, color: AppTheme.divider, indent: 16, endIndent: 16),
                  _navItem(Icons.settings_outlined, 'Настройки', '/settings', currentPath, context),
                ],
              ),
            ),

            // Logout
            Container(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context); // close drawer
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout, color: AppTheme.red, size: 16),
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

  Widget _navItem(IconData icon, String label, String route, String currentPath, BuildContext context) {
    final isActive = currentPath == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.pop(context); // close drawer
            context.go(route);
          },
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.accent.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(icon, color: isActive ? AppTheme.accent : AppTheme.textMuted, size: 20),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(
                color: isActive ? AppTheme.text : AppTheme.textMuted,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
