import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
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
      appBar: AppBar(
        title: const Text('Водители'),
        actions: [
          TextButton.icon(
            onPressed: game.isLoading ? null : () async {
              final cost = GameConstants.driverBaseSalary * GameConstants.driverHireCostMultiplier;
              final ok = await game.hireDriver(companyId);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'Водитель нанят!' : game.error ?? 'Ошибка'),
                backgroundColor: ok ? AppTheme.green : AppTheme.red,
                behavior: SnackBarBehavior.floating,
              ));
            },
            icon: const Icon(Icons.person_add, color: AppTheme.accent, size: 18),
            label: Text('Нанять (${GameConstants.formatMoney(GameConstants.driverBaseSalary * GameConstants.driverHireCostMultiplier)})', style: AppTheme.bodySm.copyWith(color: AppTheme.accent)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: game.isLoading && game.myDrivers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : game.myDrivers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text('Нет водителей', style: AppTheme.h2),
                      const SizedBox(height: 4),
                      Text('Нанимайте водителей для управления грузовиками', style: AppTheme.bodySm),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Всего: ${game.myDrivers.length} | Свободных: ${game.availableDrivers.length}',
                        style: AppTheme.bodySm,
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.divider),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: game.myDrivers.length,
                        itemBuilder: (context, i) {
                          final d = game.myDrivers[i];
                          final color = d.isAvailable ? AppTheme.green : AppTheme.amber;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: color.withOpacity(0.15),
                                  child: Icon(Icons.person, color: color, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(d.name, style: AppTheme.label),
                                  Row(children: [
                                    Text('Ур. ${d.skillLevel}', style: AppTheme.bodySm),
                                    const SizedBox(width: 12),
                                    Text('${GameConstants.formatMoney(d.salaryDaily)}/день', style: AppTheme.monoSm),
                                  ]),
                                ])),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: color.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    d.isAvailable ? 'Свободен' : 'В рейсе',
                                    style: AppTheme.bodySm.copyWith(color: color, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
