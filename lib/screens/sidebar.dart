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
                decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.local_shipping, color: AppTheme.accent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('ELT', style: TextStyle(color: AppTheme.text, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2)),
            ]),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                _navItem(Icons.map_outlined, 'Карта', true, () {}),
                _navItem(Icons.description_outlined, 'Контракты', false, () => onOpenModal(const ContractsScreen())),
                _navItem(Icons.local_shipping_outlined, 'Автопарк', false, () => onOpenModal(const FleetScreen())),
                _navItem(Icons.people_outlined, 'Водители', false, () => onOpenModal(const DriversScreen())),
                _navItem(Icons.warehouse_outlined, 'Филиалы', false, () => onOpenModal(const WarehousesScreen())),
                _navItem(Icons.receipt_long_outlined, 'Финансы', false, () => onOpenModal(const TransactionsScreen())),
                const Divider(height: 1, color: AppTheme.divider, indent: 12, endIndent: 12),
                _navItem(Icons.settings_outlined, 'Настройки', false, () => onOpenModal(const SettingsScreen())),
              ],
            ),
          ),

          // Company info
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
                Text('Lv.${company.level}', style: AppTheme.monoSm.copyWith(color: AppTheme.accent)),
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

  Widget _navItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
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
