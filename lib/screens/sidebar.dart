import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class Sidebar extends StatelessWidget {
  final VoidCallback onRefresh;
  const Sidebar({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final company = game.company;
    final currentRoute = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;

    return Container(
      width: 230,
      decoration: BoxDecoration(color: AppTheme.surface, border: Border(right: BorderSide(color: AppTheme.divider))),
      child: Column(
        children: [
          // Logo area
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.local_shipping, color: AppTheme.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('ELT', style: AppTheme.h2.copyWith(fontSize: 15, letterSpacing: 2)),
              ]),
            ]),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                _navItem(Icons.map_outlined, 'Карта', '/', currentRoute, context),
                _navItem(Icons.description_outlined, 'Контракты', '/contracts', currentRoute, context),
                _navItem(Icons.local_shipping_outlined, 'Автопарк', '/fleet', currentRoute, context),
                _navItem(Icons.people_outlined, 'Водители', '/drivers', currentRoute, context),
                _navItem(Icons.warehouse_outlined, 'Филиалы', '/warehouses', currentRoute, context),
                _navItem(Icons.receipt_long_outlined, 'Финансы', '/transactions', currentRoute, context),
                const Divider(height: 1, color: AppTheme.divider, indent: 12, endIndent: 12),
                _navItem(Icons.settings_outlined, 'Настройки', '/settings', currentRoute, context),
              ],
            ),
          ),

          // Company info footer
          if (company != null) Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.divider))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(company.name, style: AppTheme.labelSm, overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
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
                Text('Lv.${company.level}', style: AppTheme.monoSm.copyWith(color: AppTheme.accent)),
              ]),
            ]),
          ),

          // Logout button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.divider))),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async { await auth.logout(); if (context.mounted) context.go('/login'); },
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

  Widget _navItem(IconData icon, String label, String route, String currentRoute, BuildContext context) {
    final isActive = currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(route),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.accent.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive ? Border.all(color: AppTheme.accent.withOpacity(0.2)) : null,
            ),
            child: Row(children: [
              Icon(icon, color: isActive ? AppTheme.accent : AppTheme.textMuted, size: 18),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(
                color: isActive ? AppTheme.text : AppTheme.textMuted,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
