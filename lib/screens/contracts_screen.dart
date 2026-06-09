import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/contract.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';
import '../providers/game_provider.dart' as gp show haversineKm;
import '../utils/pathfinder.dart';

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
            onPressed: () async {
              await game.generateNewContracts();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Новые контракты сгенерированы'),
                  backgroundColor: Color(0xFF42A5F5),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
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

class _MyContractsTab extends StatefulWidget {
  final GameProvider game;
  const _MyContractsTab({required this.game});

  @override
  State<_MyContractsTab> createState() => _MyContractsTabState();
}

class _MyContractsTabState extends State<_MyContractsTab> {
  int _filter = 0; // 0=active, 1=completed, 2=expired, 3=all

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final List<Contract> filtered;
    switch (_filter) {
      case 0:
        filtered = game.myContracts.where((c) => c.status == 'accepted').toList();
        break;
      case 1:
        filtered = game.myContracts.where((c) => c.status == 'completed').toList();
        break;
      case 2:
        filtered = game.myContracts.where((c) => c.status == 'expired').toList();
        break;
      default:
        filtered = game.myContracts;
    }

    return Column(
      children: [
        // Sub-filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: const Color(0xFF1A1A1A),
          child: Row(
            children: [
              _chip('Активные (${game.myContracts.where((c) => c.status == 'accepted').length})', 0, const Color(0xFFF5C542)),
              const SizedBox(width: 4),
              _chip('Завершённые (${game.myContracts.where((c) => c.status == 'completed').length})', 1, const Color(0xFF66BB6A)),
              const SizedBox(width: 4),
              _chip('Просроченные (${game.myContracts.where((c) => c.status == 'expired').length})', 2, const Color(0xFFEF5350)),
              const SizedBox(width: 4),
              _chip('Все (${game.myContracts.length})', 3, const Color(0xFF888888)),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF3A3A3A)),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF666666)),
                      const SizedBox(height: 12),
                      Text(_filter == 0 ? 'Нет активных контрактов' : _filter == 1 ? 'Нет завершённых контрактов' : _filter == 2 ? 'Нет просроченных контрактов' : 'Нет контрактов', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
                      const SizedBox(height: 4),
                      Text(_filter == 0 ? 'Примите контракт из списка доступных' : _filter == 1 ? 'Совершайте рейсы, чтобы видеть историю' : 'Просроченные контракты появляются по истечении срока', style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _ContractCard(
                    contract: filtered[i],
                    game: game,
                    companyId: '',
                    isOwn: true,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, int index, Color color) {
    final active = _filter == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _filter = index),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 28,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: active ? color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: active ? Border.all(color: color.withOpacity(0.4)) : null,
            ),
            alignment: Alignment.center,
            child: Text(label, textAlign: TextAlign.center, style: TextStyle(
              color: active ? color : const Color(0xFF666666),
              fontSize: 10,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            )),
          ),
        ),
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

    // Calculate road distance via pathfinding
    double distKm = 0;
    List<int> pathIds = [];
    final route = game.findRoute(contract.originCityId, contract.destinationCityId);
    if (route != null) {
      distKm = route.totalDistanceKm;
      pathIds = PathFinder.findPath(contract.originCityId, contract.destinationCityId);
    } else if (origin != null && dest != null) {
      distKm = gp.haversineKm(origin.latitude, origin.longitude, dest.latitude, dest.longitude);
    }
    final rewardPerKm = distKm > 0 ? (contract.reward / distKm).round() : 0;

    // Dynamic economy calculations
    final tollCost = pathIds.length >= 2 ? GameConstants.getTollCost(pathIds) : 0;
    final demandMultiplier = GameConstants.getCargoDemandMultiplier(contract.destinationCityId, contract.cargoType);
    final companyLevel = game.company?.level ?? 1;
    final effectiveFuel = GameConstants.effectiveFuelPrice(companyLevel);
    final estimatedFuelCost = (distKm / 100 * GameConstants.fuelCostPer100km * (effectiveFuel / GameConstants.baseFuelPrice)).round();
    final netProfit = contract.reward - estimatedFuelCost - tollCost;

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (contract.status) {
      case 'accepted':
        statusColor = const Color(0xFFF5C542);
        statusText = 'Активен';
        statusIcon = Icons.local_shipping;
        break;
      case 'completed':
        statusColor = const Color(0xFF66BB6A);
        statusText = 'Завершён';
        statusIcon = Icons.check_circle;
        break;
      case 'expired':
        statusColor = const Color(0xFFEF5350);
        statusText = 'Истёк';
        statusIcon = Icons.timer_off;
        break;
      default:
        statusColor = const Color(0xFF42A5F5);
        statusText = 'Доступен';
        statusIcon = Icons.description;
    }

    // Deadline progress
    double deadlineProgress = 0.0;
    Color deadlineColor = const Color(0xFF66BB6A);
    if (contract.expiresAt != null && contract.createdAt != null) {
      final total = contract.expiresAt!.difference(contract.createdAt).inSeconds;
      if (total > 0) {
        final elapsed = DateTime.now().difference(contract.createdAt).inSeconds;
        deadlineProgress = (elapsed / total).clamp(0.0, 1.0);
        if (deadlineProgress > 0.8) {
          deadlineColor = const Color(0xFFEF5350);
        } else if (deadlineProgress > 0.5) {
          deadlineColor = const Color(0xFFF5C542);
        }
      }
    }

    // Find assigned truck info for active contracts
    String? assignedTruckName;
    if (isOwn && contract.assignedTruckId != null) {
      final truck = game.myTrucks.where((t) => t.id == contract.assignedTruckId).firstOrNull;
      if (truck != null) {
        assignedTruckName = truck.name;
        // Show ETA
        if (truck.estimatedArrival != null) {
          final diff = truck.estimatedArrival!.difference(DateTime.now());
          if (!diff.isNegative) {
            statusText = '${diff.inHours}ч ${diff.inMinutes % 60}м';
          } else {
            statusText = 'Прибыл!';
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: contract.status == 'accepted' ? const Color(0xFFF5C542).withOpacity(0.3) : const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CargoIcon(cargoType: contract.cargoType),
              const SizedBox(width: 6),
              Expanded(child: Text(contract.cargoType, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600))),
              Text(
                GameConstants.formatMoney(contract.reward),
                style: const TextStyle(color: Color(0xFF66BB6A), fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace'),
              ),
            ],
          ),
          // Assigned truck info
          if (assignedTruckName != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.local_shipping, size: 12, color: const Color(0xFFF5C542).withOpacity(0.7)),
              const SizedBox(width: 4),
              Text(assignedTruckName, style: TextStyle(color: const Color(0xFFF5C542).withOpacity(0.9), fontSize: 11)),
            ]),
          ],
          const SizedBox(height: 8),
          // Route row
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF66BB6A))),
              const SizedBox(width: 6),
              Flexible(child: Text(origin?.name ?? '?', style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12), overflow: TextOverflow.ellipsis)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 1, color: const Color(0xFF666666)),
                    Icon(Icons.arrow_forward, size: 10, color: const Color(0xFF666666)),
                    Container(width: 40, height: 1, color: const Color(0xFF666666)),
                  ],
                ),
              ),
              Flexible(child: Text(dest?.name ?? '?', style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF5350))),
            ],
          ),
          const SizedBox(height: 6),
          // Stats row
          Row(
            children: [
              Text('${contract.cargoWeight}т', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
              const SizedBox(width: 12),
              Text('${distKm.round()}km', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
              const SizedBox(width: 12),
              Text('${GameConstants.formatMoney(rewardPerKm)}/km', style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 11, fontFamily: 'monospace')),
              const Spacer(),
              if (tollCost > 0) ...[
                Text('🛣️ ${GameConstants.formatMoney(tollCost)}', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 11)),
                const SizedBox(width: 8),
              ],
              if (demandMultiplier > 1.0) ...[
                Text('📈 +${((demandMultiplier - 1) * 100).round()}%', style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 11)),
                const SizedBox(width: 8),
              ],
              Text('${contract.deadlineHours}ч', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
            ],
          ),
          // Economy details row
          if (!isOwn && contract.isAvailable) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text('⛽ ${effectiveFuel.toStringAsFixed(2)}€/л', style: TextStyle(
                  color: effectiveFuel > GameConstants.baseFuelPrice * 1.1 ? const Color(0xFFEF5350)
                      : effectiveFuel < GameConstants.baseFuelPrice * 0.9 ? const Color(0xFF66BB6A)
                      : const Color(0xFF888888),
                  fontSize: 10, fontFamily: 'monospace',
                )),
                const SizedBox(width: 8),
                Text('💰 ~${GameConstants.formatMoney(estimatedFuelCost)} топл.', style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
                const Spacer(),
                Text('Чистая: ${GameConstants.formatMoney(netProfit)}', style: TextStyle(
                  color: netProfit > 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                  fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace',
                )),
              ],
            ),
          ],
          // Deadline progress bar for available/accepted contracts
          if (contract.isAvailable || contract.isAccepted) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: deadlineProgress,
                backgroundColor: const Color(0xFF1A1A1A),
                valueColor: AlwaysStoppedAnimation<Color>(deadlineColor),
                minHeight: 3,
              ),
            ),
          ],
          // Accept button
          if (!isOwn && contract.isAvailable) ...[
            const SizedBox(height: 10),
            _AcceptButton(contract: contract, game: game, companyId: companyId),
          ],
        ],
      ),
    );
  }


}

class _CargoIcon extends StatelessWidget {
  final String cargoType;
  const _CargoIcon({required this.cargoType});

  @override
  Widget build(BuildContext context) {
    final path = GameConstants.cargoAssetPath(cargoType);
    if (path.isEmpty) return const SizedBox(width: 20, height: 20);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(path, width: 20, height: 20, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(width: 20, height: 20)),
    );
  }
}

class _AcceptButton extends StatefulWidget {
  final Contract contract;
  final GameProvider game;
  final String companyId;
  const _AcceptButton({required this.contract, required this.game, required this.companyId});

  @override
  State<_AcceptButton> createState() => _AcceptButtonState();
}

class _AcceptButtonState extends State<_AcceptButton> {
  bool _isAccepting = false;

  Contract get contract => widget.contract;
  GameProvider get game => widget.game;
  String get companyId => widget.companyId;

  @override
  Widget build(BuildContext context) {
    final hasIdle = game.idleTrucks.isNotEmpty;
    final nearest = hasIdle ? game.findNearestIdleTruck(contract.originCityId) : null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (hasIdle && !_isAccepting) ? () => _accept(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5C542),
          foregroundColor: const Color(0xFF1A1A1A),
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: _isAccepting
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF1A1A1A), strokeWidth: 2))
            : const Icon(Icons.check, size: 16),
        label: Text(
          _isAccepting
              ? 'Принятие...'
              : nearest != null
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
    setState(() => _isAccepting = true);
    final result = await game.acceptContract(
      contractId: contract.id,
      truckId: null,
      companyId: companyId,
    );
    if (mounted) setState(() => _isAccepting = false);
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
