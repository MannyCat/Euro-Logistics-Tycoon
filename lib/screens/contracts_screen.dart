import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/contract.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final companyId = auth.companyId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Контракты'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Доступные'),
            Tab(text: 'Мои'),
          ],
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.accent,
          dividerColor: Colors.transparent,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.accent),
            tooltip: 'Обновить',
            onPressed: () => game.refreshAll(companyId),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Available contracts
          _AvailableTab(game: game, companyId: companyId),
          // My contracts
          _MyContractsTab(game: game),
        ],
      ),
    );
  }
}

class _AvailableTab extends StatelessWidget {
  final GameProvider game;
  final String companyId;
  const _AvailableTab({required this.game, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final contracts = game.availableContracts;

    if (contracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('Нет доступных контрактов', style: AppTheme.h2),
            const SizedBox(height: 4),
            Text('Подождите или обновите список', style: AppTheme.bodySm),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => game.generateNewContracts(),
              icon: const Icon(Icons.add),
              label: const Text('Сгенерировать'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: contracts.length,
      itemBuilder: (context, i) => _ContractCard(
        contract: contracts[i],
        game: game,
        companyId: companyId,
        isOwn: false,
      ),
    );
  }
}

class _MyContractsTab extends StatelessWidget {
  final GameProvider game;
  const _MyContractsTab({required this.game});

  @override
  Widget build(BuildContext context) {
    final contracts = game.myContracts;

    if (contracts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('Нет активных контрактов', style: AppTheme.h2),
            const SizedBox(height: 4),
            Text('Примите контракт на карте или в таблице', style: AppTheme.bodySm),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: contracts.length,
      itemBuilder: (context, i) => _ContractCard(
        contract: contracts[i],
        game: game,
        companyId: '',
        isOwn: true,
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final Contract contract;
  final GameProvider game;
  final String companyId;
  final bool isOwn;
  const _ContractCard({required this.contract, required this.game, required this.companyId, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final origin = game.getCityById(contract.originCityId);
    final dest = game.getCityById(contract.destinationCityId);

    Color statusColor;
    String statusText;
    switch (contract.status) {
      case 'accepted':
        statusColor = AppTheme.amber;
        statusText = 'Активен';
        break;
      case 'completed':
        statusColor = AppTheme.green;
        statusText = 'Завершён';
        break;
      case 'expired':
        statusColor = AppTheme.red;
        statusText = 'Истёк';
        break;
      default: // available
        statusColor = AppTheme.accent;
        statusText = 'Доступен';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Text(statusText, style: AppTheme.bodySm.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(contract.cargoType, style: AppTheme.label),
            ),
            Text(
              GameConstants.formatMoney(contract.reward),
              style: AppTheme.mono.copyWith(color: AppTheme.green, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ]),
          const SizedBox(height: 8),
          // Route
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.green)),
            const SizedBox(width: 6),
            Text(origin?.name ?? '?', style: AppTheme.body),
            const Spacer(),
            const Icon(Icons.arrow_forward, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(dest?.name ?? '?', style: AppTheme.body),
            const SizedBox(width: 6),
            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.red)),
          ]),
          const SizedBox(height: 6),
          // Details
          Row(children: [
            Text('${contract.cargoWeight}т', style: AppTheme.bodySm),
            const SizedBox(width: 16),
            Text('Срок: ${contract.deadlineHours}ч', style: AppTheme.bodySm),
          ]),
          // Accept button (available contracts only)
          if (!isOwn && contract.isAvailable) ...[
            const SizedBox(height: 10),
            _AcceptButton(contract: contract, game: game, companyId: companyId),
          ],
        ]),
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  final Contract contract;
  final GameProvider game;
  final String companyId;
  const _AcceptButton({required this.contract, required this.game, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final hasIdle = game.idleTrucks.isNotEmpty;
    final nearest = hasIdle ? game.findNearestIdleTruck(contract.originCityId) : null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: hasIdle
            ? () => _accept(context)
            : null,
        icon: const Icon(Icons.check, size: 16),
        label: Text(
          nearest != null
              ? 'Принять (${nearest.name})'
              : hasIdle
                  ? 'Принять (${game.idleTrucks.first.name})'
                  : 'Нет свободных грузовиков',
        ),
      ),
    );
  }

  void _accept(BuildContext context) async {
    final result = await game.acceptContract(
      contractId: contract.id,
      truckId: null, // Auto-assign nearest
      companyId: companyId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.success
            ? 'Контракт принят! Грузовик: ${result.truckName}'
            : game.error ?? 'Ошибка принятия контракта'),
        backgroundColor: result.success ? AppTheme.green : AppTheme.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
