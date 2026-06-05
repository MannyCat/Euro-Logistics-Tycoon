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

    return Container(
      width: 220,
      decoration: BoxDecoration(color: AppTheme.surface, border: Border(right: BorderSide(color: AppTheme.divider))),
      child: Column(
        children: [
          // Logo
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(children: [
              const Icon(Icons.local_shipping, color: AppTheme.accent, size: 22),
              const SizedBox(width: 8),
              Flexible(child: Text('ELT', style: AppTheme.h2.copyWith(fontSize: 16, letterSpacing: 2))),
            ]),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          // Nav
          Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 4), children: [
            _navItem(Icons.map, 'Карта', '/', true, context),
            _navItem(Icons.inventory_2, 'Контракты', '/contracts', false, context),
            _navItem(Icons.local_shipping, 'Автопарк', '/fleet', false, context),
            _navItem(Icons.people, 'Водители', '/drivers', false, context),
            const Divider(height: 1, color: AppTheme.divider),
            _navItem(Icons.settings, 'Настройки', '/settings', false, context),
          ])),

          // Company stats
          if (company != null) Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.divider))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(company.name, style: AppTheme.labelSm, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('Реп: ${company.reputation} | XP: ${company.xp}', style: AppTheme.bodySm),
            ]),
          ),

          // Logout
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.red, size: 18),
            onPressed: () async { await auth.logout(); if (context.mounted) context.go('/login'); },
            tooltip: 'Выйти',
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, String route, bool isCurrent, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => context.go(route),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isCurrent ? AppTheme.accent.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            Icon(icon, color: isCurrent ? AppTheme.accent : AppTheme.textMuted, size: 18),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: isCurrent ? AppTheme.text : AppTheme.textMuted, fontSize: 13, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400)),
          ]),
        ),
      ),
    );
  }
}
