import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';

class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final companyId = auth.companyId ?? '';

    return ETS2Modal(
      title: 'Водители',
      icon: Icons.people,
      actions: [
        TextButton.icon(
          onPressed: game.isLoading ? null : () async {
            final money = game.company?.money ?? 0;
            final cost = GameConstants.driverBaseSalary * GameConstants.driverHireCostMultiplier;
            if (money < cost) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Недостаточно средств (нужно: ${GameConstants.formatMoney(cost)})'),
                  backgroundColor: const Color(0xFFEF5350),
                  behavior: SnackBarBehavior.floating,
                ));
              }
              return;
            }
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
                title: const Text('Нанять водителя?', style: TextStyle(color: Color(0xFFD0D0D0))),
                content: Text('Стоимость: ${GameConstants.formatMoney(cost)} (зарплата за 30 дней)', style: const TextStyle(color: Color(0xFF888888))),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888)))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Нанять', style: TextStyle(color: Color(0xFF66BB6A)))),
                ],
              ),
            );
            if (confirm != true) return;
            final ok = await game.hireDriver(companyId);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'Водитель нанят!' : game.error ?? 'Ошибка'),
                backgroundColor: ok ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
          icon: const Icon(Icons.person_add, color: Color(0xFFF5C542), size: 18),
          label: Text('Нанять (${GameConstants.formatMoney(GameConstants.driverBaseSalary * GameConstants.driverHireCostMultiplier)})', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 12)),
        ),
      ],
      child: game.isLoading && game.myDrivers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5C542)))
          : game.myDrivers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 48, color: Color(0xFF666666)),
                      const SizedBox(height: 12),
                      Text('Нет водителей', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
                      const SizedBox(height: 4),
                      const Text('Нанимайте водителей для управления грузовиками', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final cost = GameConstants.driverBaseSalary * GameConstants.driverHireCostMultiplier;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1E1E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
                              title: const Text('Нанять водителя?', style: TextStyle(color: Color(0xFFD0D0D0))),
                              content: Text('Стоимость: ${GameConstants.formatMoney(cost)}', style: const TextStyle(color: Color(0xFF888888))),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888)))),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Нанять', style: TextStyle(color: Color(0xFF66BB6A)))),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          final ok = await game.hireDriver(companyId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(ok ? 'Водитель нанят!' : game.error ?? 'Ошибка'),
                              backgroundColor: ok ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        },
                        icon: const Icon(Icons.person_add),
                        label: Text('Нанять за ${GameConstants.formatMoney(GameConstants.driverBaseSalary * GameConstants.driverHireCostMultiplier)}'),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: const Color(0xFF252525),
                      child: Row(
                        children: [
                          Text('Всего: ${game.myDrivers.length}', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                          const SizedBox(width: 16),
                          Text('Свободных: ${game.availableDrivers.length}', style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 16),
                          Text('В рейсе: ${game.myDrivers.length - game.availableDrivers.length}', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF3A3A3A)),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: game.myDrivers.length,
                        itemBuilder: (context, i) {
                          final d = game.myDrivers[i];
                          final color = d.isAvailable ? const Color(0xFF66BB6A) : const Color(0xFFF5C542);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF252525),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF3A3A3A)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 22, backgroundColor: color.withOpacity(0.15), child: Icon(Icons.person, color: color, size: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 14, fontWeight: FontWeight.w600)),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(color: const Color(0xFFF5C542).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                            child: Text('Ур. ${d.skillLevel}', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 11, fontWeight: FontWeight.w600)),
                                          ),
                                          const SizedBox(width: 10),
                                          Text('${GameConstants.formatMoney(d.salaryDaily)}/день', style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontFamily: 'monospace')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
                                  child: Text(d.isAvailable ? 'Свободен' : 'В рейсе', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
                                ),
                              ],
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
