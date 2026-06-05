import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final companyId = auth.companyId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Водители'), actions: [
        IconButton(icon: const Icon(Icons.person_add, color: AppTheme.accent),
          onPressed: () async {
            final ok = await game.hireDriver(companyId);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok ? 'Водитель нанят!' : game.error ?? 'Ошибка'),
              backgroundColor: ok ? AppTheme.green : AppTheme.red, behavior: SnackBarBehavior.floating));
          }),
      ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: game.myDrivers.length,
        itemBuilder: (context, i) {
          final d = game.myDrivers[i];
          final color = d.isAvailable ? AppTheme.green : AppTheme.amber;
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(Icons.person, color: color, size: 20)),
              title: Text(d.name, style: AppTheme.label),
              subtitle: Text('Уровень: ${d.skillLevel}  |  \u20AC${d.salaryDaily}/день', style: AppTheme.bodySm),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(d.isAvailable ? 'Свободен' : 'Работает', style: AppTheme.bodySm.copyWith(color: color)),
              ),
            ),
          );
        },
      ),
    );
  }
}
