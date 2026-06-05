import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class ContractsScreen extends StatelessWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final companyId = auth.companyId ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          title: const Text('Контракты'),
          bottom: const TabBar(tabs: [Tab(text: 'Доступные'), Tab(text: 'Мои')], labelColor: AppTheme.accent, unselectedLabelColor: AppTheme.textMuted, indicatorColor: AppTheme.accent, dividerColor: Colors.transparent),
        ),
        body: TabBarView(children: [
          // Available
          ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: game.availableContracts.length,
            itemBuilder: (context, i) => _ContractCard(contract: game.availableContracts[i], game: game, companyId: companyId, isOwn: false),
          ),
          // My
          ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: game.myContracts.length,
            itemBuilder: (context, i) => _ContractCard(contract: game.myContracts[i], game: game, companyId: companyId, isOwn: true),
          ),
        ]),
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final dynamic contract;
  final GameProvider game;
  final String companyId;
  final bool isOwn;
  const _ContractCard({required this.contract, required this.game, required this.companyId, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final origin = game.getCityById(contract.originCityId);
    final dest = game.getCityById(contract.destinationCityId);
    final statusColor = contract.isAccepted ? AppTheme.amber : AppTheme.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(isOwn ? (contract.isAccepted ? 'Активен' : 'Завершён') : 'Доступен', style: AppTheme.bodySm.copyWith(color: statusColor)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(contract.cargoType, style: AppTheme.label)),
            Text('\u20AC${contract.reward}', style: AppTheme.mono.copyWith(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.trip_origin, size: 14, color: AppTheme.green),
            const SizedBox(width: 4),
            Text(origin?.name ?? '?', style: AppTheme.body),
            const Spacer(),
            const Icon(Icons.arrow_forward, size: 14, color: AppTheme.textMuted),
            const Spacer(),
            Text(dest?.name ?? '?', style: AppTheme.body),
            const SizedBox(width: 4),
            const Icon(Icons.location_on, size: 14, color: AppTheme.red),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Text('${contract.cargoWeight}т', style: AppTheme.bodySm),
            const SizedBox(width: 16),
            Text('Срок: ${contract.deadlineHours}ч', style: AppTheme.bodySm),
          ]),
          if (!isOwn && contract.isAvailable) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: game.idleTrucks.isEmpty ? null : () async {
                  final ok = await game.acceptContract(contract.id, game.idleTrucks.first.id, companyId);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Контракт принят!' : game.error ?? 'Ошибка'),
                    backgroundColor: ok ? AppTheme.green : AppTheme.red, behavior: SnackBarBehavior.floating));
                },
                child: Text(game.idleTrucks.isEmpty ? 'Нет свободных грузовиков' : 'Принять (${game.idleTrucks.first.name})'),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
