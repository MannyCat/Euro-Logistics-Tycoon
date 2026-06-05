import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final userId = auth.userId ?? '';
    final company = game.company;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // App info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.local_shipping, color: AppTheme.accent, size: 22)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Euro Logistics Tycoon', style: AppTheme.h2),
                  const SizedBox(height: 2),
                  Text('Версия 1.0.0 — Прототип', style: AppTheme.bodySm),
                ]),
              ]),
            ]),
          ),
        ),

        const SizedBox(height: 12),

        // Company stats card
        if (company != null) Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Статистика компании', style: AppTheme.labelSm),
              const SizedBox(height: 10),
              _statRow('Название', company.name),
              _statRow('Баланс', '\u20AC${company.money}'),
              _statRow('Уровень', '${company.level}'),
              _statRow('Репутация', '${company.reputation}/100'),
              _statRow('Опыт', '${company.xp} XP'),
            ]),
          ),
        ),

        if (company != null) const SizedBox(height: 12),

        // User info
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline, color: AppTheme.accent),
            title: Text('Профиль', style: AppTheme.label),
            subtitle: Text('ID: ${userId.length > 12 ? '${userId.substring(0, 12)}...' : userId}', style: AppTheme.bodySm),
          ),
        ),

        const SizedBox(height: 12),

        // Game tips
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Руководство', style: AppTheme.labelSm),
              const SizedBox(height: 8),
              _tip(Icons.local_shipping, 'Купите грузовики в разделе "Автопарк"'),
              const SizedBox(height: 6),
              _tip(Icons.description, 'Нажмите на город на карте, чтобы увидеть контракты'),
              const SizedBox(height: 6),
              _tip(Icons.people, 'Нанимайте водителей для расширения бизнеса'),
              const SizedBox(height: 6),
              _tip(Icons.build, 'Следите за состоянием грузовиков: заправка и ремонт'),
              const SizedBox(height: 6),
              _tip(Icons.warehouse, 'Покупайте склады в городах для расширения сети'),
              const SizedBox(height: 6),
              _tip(Icons.auto_graph, 'Автоматически назначается ближайший свободный грузовик'),
            ]),
          ),
        ),

        const SizedBox(height: 24),

        // Logout
        OutlinedButton.icon(
          onPressed: () async {
            await auth.logout();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout, color: AppTheme.red),
          label: const Text('Выйти из аккаунта', style: TextStyle(color: AppTheme.red)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.red),
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ]),
    );
  }

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Text('$label: ', style: AppTheme.bodySm),
      Text(value, style: AppTheme.monoSm.copyWith(fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _tip(IconData icon, String text) => Row(children: [
    Icon(icon, size: 16, color: AppTheme.textMuted),
    const SizedBox(width: 8),
    Expanded(child: Text(text, style: AppTheme.bodySm)),
  ]);
}
