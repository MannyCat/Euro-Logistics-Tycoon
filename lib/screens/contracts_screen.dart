import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/contract.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  int _activeTab = 0; // 0 = available, 1 = my

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final companyId = auth.companyId ?? '';

    return ETS2Modal(
      title: 'Контракты',
      icon: Icons.description,
      actions: [
        if (_activeTab == 0)
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFF5C542), size: 20),
            tooltip: 'Сгенерировать',
            onPressed: () => game.generateNewContracts(),
          ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF999999), size: 18),
          tooltip: 'Обновить',
          onPressed: () => game.refreshAll(companyId),
        ),
      ],
      child: Column(
        children: [
          // Custom tab bar (no Scaffold TabBar needed)
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF252525),
              border: Border(bottom: BorderSide(color: Color(0xFF3A3A3A))),
            ),
            child: Row(
              children: [
                _tabButton('Доступные (${game.availableContracts.length})', 0),
                const SizedBox(width: 4),
                _tabButton('Мои (${game.myContracts.length})', 1),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _activeTab == 0
                ? _AvailableTab(game: game, companyId: companyId)
                : _MyContractsTab(game: game),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isActive = _activeTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _activeTab = index),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 32,
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF5C542).withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isActive
                  ? Border.all(color: const Color(0xFFF5C542).withOpacity(0.4))
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isActive ? const Color(0xFFF5C542) : const Color(0xFF888888),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
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
            const Icon(Icons.description_outlined, size: 48, color: Color(0xFF666666)),
            const SizedBox(height: 12),
            Text('Нет доступных контрактов', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
            const SizedBox(height: 4),
            const Text('Подождите или обновите список', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
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
            const Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF666666)),
            const SizedBox(height: 12),
            Text('Нет активных контрактов', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
            const SizedBox(height: 4),
            const Text('Примите контракт из списка доступных', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
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
        statusColor = const Color(0xFFF5C542);
        statusText = 'Активен';
        break;
      case 'completed':
        statusColor = const Color(0xFF66BB6A);
        statusText = 'Завершён';
        break;
      case 'expired':
        statusColor = const Color(0xFFEF5350);
        statusText = 'Истёк';
        break;
      default:
        statusColor = const Color(0xFF42A5F5);
        statusText = 'Доступен';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(contract.cargoType, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600))),
              Text(
                GameConstants.formatMoney(contract.reward),
                style: const TextStyle(color: Color(0xFF66BB6A), fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF66BB6A))),
              const SizedBox(width: 6),
              Text(origin?.name ?? '?', style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12)),
              const Spacer(),
              const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF666666)),
              const SizedBox(width: 8),
              Text(dest?.name ?? '?', style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12)),
              const SizedBox(width: 6),
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF5350))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${contract.cargoWeight}т', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
              const SizedBox(width: 16),
              Text('Срок: ${contract.deadlineHours}ч', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
            ],
          ),
          if (!isOwn && contract.isAvailable) ...[
            const SizedBox(height: 10),
            _AcceptButton(contract: contract, game: game, companyId: companyId),
          ],
        ],
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
        onPressed: hasIdle ? () => _accept(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5C542),
          foregroundColor: const Color(0xFF1A1A1A),
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.check, size: 16),
        label: Text(
          nearest != null
              ? 'Принять (${nearest.name})'
              : hasIdle
                  ? 'Принять (${game.idleTrucks.first.name})'
                  : 'Нет свободных грузовиков',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  void _accept(BuildContext context) async {
    final result = await game.acceptContract(
      contractId: contract.id,
      truckId: null,
      companyId: companyId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.success
            ? 'Контракт принят! Грузовик: ${result.truckName}'
            : game.error ?? 'Ошибка принятия контракта'),
        backgroundColor: result.success ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
