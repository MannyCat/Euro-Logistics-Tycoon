import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/driver.dart';
import '../models/truck.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  int _selectedFilter = 0; // 0=All, 1=Idle, 2=Transit

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final companyId = auth.companyId ?? '';

    final filteredTrucks = switch (_selectedFilter) {
      1 => game.idleTrucks,
      2 => game.transitTrucks,
      _ => game.myTrucks,
    };

    return ETS2Modal(
      title: 'Автопарк',
      icon: Icons.local_shipping,
      actions: [
        if (game.myTrucks.length < GameConstants.maxTrucks)
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFF5C542), size: 20),
            tooltip: 'Купить грузовик',
            onPressed: () => _showBuyDialog(context, game, companyId),
          ),
      ],
      child: game.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5C542)))
          : game.myTrucks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping, size: 48, color: Color(0xFF666666)),
                      const SizedBox(height: 12),
                      Text('Нет грузовиков', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
                      const SizedBox(height: 4),
                      const Text('Купите первый грузовик, чтобы начать', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showBuyDialog(context, game, companyId),
                        icon: const Icon(Icons.add),
                        label: const Text('Купить грузовик'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: const Color(0xFF252525),
                      child: Row(
                        children: [
                          _filterChip('Все (${game.myTrucks.length})', 0),
                          const SizedBox(width: 6),
                          _filterChip('Свободных (${game.idleTrucks.length})', 1),
                          const SizedBox(width: 6),
                          _filterChip('В пути (${game.transitTrucks.length})', 2),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF3A3A3A)),
                    Expanded(
                      child: filteredTrucks.isEmpty
                          ? Center(
                              child: Text('Нет грузовиков в этой категории', style: AppTheme.bodySm),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: filteredTrucks.length,
                              itemBuilder: (context, i) => _TruckCard(truck: filteredTrucks[i], game: game, companyId: companyId),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _filterChip(String label, int index) {
    final selected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5C542).withOpacity(0.15) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFFF5C542).withOpacity(0.4) : const Color(0xFF3A3A3A)),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? const Color(0xFFF5C542) : const Color(0xFF888888),
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }

  void _showBuyDialog(BuildContext context, GameProvider game, String companyId) {
    showDialog(context: context, builder: (ctx) => _BuyTruckDialog(game: game, companyId: companyId));
  }
}

class _TruckCard extends StatefulWidget {
  final Truck truck;
  final GameProvider game;
  final String companyId;
  const _TruckCard({required this.truck, required this.game, required this.companyId});

  @override
  State<_TruckCard> createState() => _TruckCardState();
}

class _TruckCardState extends State<_TruckCard> {
  bool _isRefueling = false;
  bool _isRepairing = false;
  bool _isSelling = false;

  Truck get truck => widget.truck;
  GameProvider get game => widget.game;
  String get companyId => widget.companyId;

  @override
  Widget build(BuildContext context) {
    final typeInfo = GameConstants.findTruckType(truck.truckType);
    final originCity = truck.originCityId != null ? game.getCityById(truck.originCityId!) : null;
    final destCity = truck.destinationCityId != null ? game.getCityById(truck.destinationCityId!) : null;
    final curCity = truck.currentCityId != null ? game.getCityById(truck.currentCityId!) : null;

    final Color statusColor;
    final IconData statusIcon;
    switch (truck.status) {
      case 'in_transit':
        statusColor = const Color(0xFFF5C542);
        statusIcon = Icons.local_shipping;
        break;
      case 'loading':
        statusColor = const Color(0xFF42A5F5);
        statusIcon = Icons.hourglass_top;
        break;
      case 'maintenance':
        statusColor = const Color(0xFFEF5350);
        statusIcon = Icons.build;
        break;
      default:
        statusColor = const Color(0xFF66BB6A);
        statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Paint color stripe at top
          if (truck.paintColor != 'default')
            Container(height: 3, decoration: BoxDecoration(color: truck.paintColorValue, borderRadius: const BorderRadius.vertical(top: Radius.circular(7)))),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Truck image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        GameConstants.truckAssetPath(truck.truckType),
                        width: 42, height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                          child: Icon(statusIcon, color: statusColor, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(truck.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 14, fontWeight: FontWeight.w600)),
                          Text('${typeInfo?.name ?? truck.truckType}  •  ${typeInfo?.capacity ?? '?'}т', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                          // Upgrade level indicators
                          const SizedBox(height: 4),
                          _UpgradeIndicators(truck: truck),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(truck.statusDisplay, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat('Сост.', '${truck.condition}%', truck.condition < 30 ? const Color(0xFFEF5350) : truck.condition < 60 ? const Color(0xFFF5C542) : const Color(0xFF66BB6A)),
                    _stat('Топливо', '${truck.fuelLevel.toStringAsFixed(0)}%', truck.fuelLevel < 20 ? const Color(0xFFEF5350) : const Color(0xFF888888)),
                    if (curCity != null)
                      Expanded(
                        child: Text(curCity.name, style: const TextStyle(color: Color(0xFF888888), fontSize: 12), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
                // Assigned driver info
                _assignedDriverRow(game),
                // Route info for transit trucks
                if (truck.isInTransit && originCity != null && destCity != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5C542).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF5C542).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.trip_origin, size: 14, color: Color(0xFF66BB6A)),
                            const SizedBox(width: 6),
                            Expanded(child: Text('${originCity.name}  \u2192  ${destCity.name}', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 12))),
                            if (truck.estimatedArrival != null) ...[
                              const SizedBox(width: 8),
                              Text(_timeLeft(truck.estimatedArrival!), style: const TextStyle(color: Color(0xFFF5C542), fontSize: 11, fontFamily: 'monospace')),
                            ],
                          ],
                        ),
                        // Contract cargo info
                        if (truck.contractId != null) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.inventory_2_outlined, size: 12, color: Color(0xFF888888)),
                            const SizedBox(width: 4),
                            Text(_getCargoInfo(truck.contractId!, game), style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                          ]),
                        ],
                        // Progress bar
                        if (truck.estimatedArrival != null && truck.departureTime != null) ...[
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _tripProgress(truck),
                              backgroundColor: const Color(0xFF1A1A1A),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF5C542)),
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                // Action buttons for idle trucks
                if (truck.isIdle) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.local_gas_station,
                          label: '${GameConstants.formatMoney(((truck.maxFuel - truck.fuelLevel) * GameConstants.fuelCostPerLiter).round())}',
                          tooltip: 'Заправить',
                          isLoading: _isRefueling,
                          enabled: truck.fuelLevel < truck.maxFuel,
                          color: const Color(0xFF42A5F5),
                          onPressed: _isRefueling ? null : () => _refuel(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.build,
                          label: '${GameConstants.formatMoney((100 - truck.condition) * GameConstants.repairCostPerPoint)}',
                          tooltip: 'Ремонт',
                          isLoading: _isRepairing,
                          enabled: truck.condition < 100,
                          color: const Color(0xFFF5C542),
                          onPressed: _isRepairing || truck.condition >= 100 ? null : () => _repair(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.arrow_upward,
                          label: 'Улучшить',
                          isLoading: false,
                          enabled: true,
                          color: const Color(0xFFCE93D8),
                          onPressed: () => _showUpgradeDialog(context, game, companyId),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.sell,
                          label: 'Продать',
                          isLoading: _isSelling,
                          enabled: true,
                          color: const Color(0xFFEF5350),
                          onPressed: _isSelling ? null : () => _sell(context),
                        ),
                      ),
                    ],
                  ),
                ],
                // Driver assign/unassign buttons
                if (truck.isIdle) ...[
                  const SizedBox(height: 6),
                  _driverActionButtons(context, game),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignedDriverRow(GameProvider game) {
    final assignedDriver = truck.driverId != null
        ? game.myDrivers.where((d) => d.id == truck.driverId).firstOrNull
        : null;
    if (assignedDriver == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF42A5F5).withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF42A5F5).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person, size: 14, color: Color(0xFF42A5F5)),
            const SizedBox(width: 6),
            Text(assignedDriver.name, style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFFF5C542).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(assignedDriver.skillLevelDisplay, style: const TextStyle(color: Color(0xFFF5C542), fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            if (assignedDriver.fatigue >= 50) ...[
              const SizedBox(width: 6),
              Text('😴${assignedDriver.fatigue}%', style: const TextStyle(color: Color(0xFFFF9800), fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _driverActionButtons(BuildContext context, GameProvider game) {
    final assignedDriver = truck.driverId != null
        ? game.myDrivers.where((d) => d.id == truck.driverId).firstOrNull
        : null;
    final availableDrivers = game.availableDrivers;

    return Row(
      children: [
        if (assignedDriver != null) ...[
          Expanded(
            child: _ActionButton(
              icon: Icons.person_remove,
              label: 'Снять водителя',
              isLoading: _isRefueling,
              enabled: true,
              color: const Color(0xFFEF5350),
              onPressed: () => _unassignDriver(context, assignedDriver, game),
            ),
          ),
        ] else if (availableDrivers.isNotEmpty) ...[
          Expanded(
            child: _ActionButton(
              icon: Icons.person_add,
              label: 'Назначить водителя',
              isLoading: _isRefueling,
              enabled: true,
              color: const Color(0xFF42A5F5),
              onPressed: () => _showAssignDriverDialog(context, availableDrivers, game),
            ),
          ),
        ],
      ],
    );
  }

  void _showAssignDriverDialog(BuildContext context, List<Driver> availableDrivers, GameProvider game) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
        title: Text('Назначить на ${truck.name}', style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 14)),
        children: availableDrivers.map((driver) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _assignDriverToTruck(context, driver, game);
            },
            child: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF66BB6A), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 13)),
                      Text('${driver.skillLevelDisplay} • ${driver.statusDisplay} • ${GameConstants.formatMoney(driver.salaryDaily)}/день', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _assignDriverToTruck(BuildContext context, Driver driver, GameProvider game) async {
    setState(() => _isRefueling = true);
    final ok = await game.assignDriver(driver.id, truck.id, companyId);
    if (mounted) setState(() => _isRefueling = false);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(game.error ?? 'Ошибка назначения'),
        backgroundColor: const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _unassignDriver(BuildContext context, Driver driver, GameProvider game) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
        title: Text('Снять ${driver.name}?', style: const TextStyle(color: Color(0xFFD0D0D0))),
        content: const Text('Водитель снова станет свободным.', style: TextStyle(color: Color(0xFF888888))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Снять', style: TextStyle(color: Color(0xFFEF5350)))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isRefueling = true);
    final ok = await game.unassignDriver(driver.id, companyId);
    if (mounted) setState(() => _isRefueling = false);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(game.error ?? 'Ошибка снятия'),
        backgroundColor: const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _refuel() async {
    setState(() => _isRefueling = true);
    final ok = await game.refuelTruck(truck.id, companyId);
    if (mounted) setState(() => _isRefueling = false);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(game.error ?? 'Ошибка заправки'),
        backgroundColor: const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _repair() async {
    setState(() => _isRepairing = true);
    final ok = await game.repairTruck(truck.id, companyId);
    if (mounted) setState(() => _isRepairing = false);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(game.error ?? 'Ошибка ремонта'),
        backgroundColor: const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _sell(BuildContext context) async {
    final typeInfo = GameConstants.findTruckType(truck.truckType);
    final sellPrice = typeInfo != null ? (typeInfo.price * GameConstants.sellBackRatio).round() : 0;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _SellDialog(truck: truck, sellPrice: sellPrice, game: game),
    );
    if (result == null || result == 'cancel') return;
    setState(() => _isSelling = true);

    if (result == 'instant') {
      final ok = await game.sellTruck(truck.id, companyId, sellPrice);
      if (mounted) setState(() => _isSelling = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? '${truck.name} продан!' : game.error ?? 'Ошибка'),
          backgroundColor: ok ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } else if (result == 'market') {
      final marketPrice = (typeInfo?.price ?? 0) * 2 ~/ 3;
      final ok = await game.listTruckOnMarket(truck.id, companyId, marketPrice);
      if (mounted) setState(() => _isSelling = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? '${truck.name} выставлен на рынок!' : game.error ?? 'Ошибка'),
          backgroundColor: ok ? const Color(0xFFF5C542) : const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Widget _stat(String label, String value, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label: ', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'monospace')),
      const SizedBox(width: 12),
    ],
  );

  String _timeLeft(DateTime eta) {
    final diff = eta.difference(DateTime.now());
    if (diff.isNegative) return 'Прибыл!';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '${h}ч ${m}м';
  }

  double _tripProgress(Truck truck) {
    if (truck.estimatedArrival == null || truck.departureTime == null) return 0.0;
    final total = truck.estimatedArrival!.difference(truck.departureTime!).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = DateTime.now().difference(truck.departureTime!).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _getCargoInfo(String contractId, GameProvider game) {
    final contract = game.myContracts.where((c) => c.id == contractId).firstOrNull;
    if (contract == null) return 'Груз в пути';
    return '${contract.cargoType} (${contract.cargoWeight}т)';
  }

  void _showUpgradeDialog(BuildContext context, GameProvider game, String companyId) {
    showDialog(
      context: context,
      builder: (ctx) => _UpgradeDialog(truck: truck, game: game, companyId: companyId),
    );
  }
}

/// Reusable action button with loading state
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? tooltip;
  final bool isLoading;
  final bool enabled;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.tooltip,
    required this.isLoading,
    required this.enabled,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: color, strokeWidth: 2))
          : Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: enabled ? color : const Color(0xFF3A3A3A)),
        minimumSize: const Size(double.infinity, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _BuyTruckDialog extends StatefulWidget {
  final GameProvider game;
  final String companyId;
  const _BuyTruckDialog({required this.game, required this.companyId});

  @override
  State<_BuyTruckDialog> createState() => _BuyTruckDialogState();
}

class _BuyTruckDialogState extends State<_BuyTruckDialog> {
  final _nameCtrl = TextEditingController();
  String? _selectedType;
  int? _selectedCityId;
  bool _isBuying = false;
  String? _error;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final money = widget.game.company?.money ?? 0;
    final info = _selectedType != null ? GameConstants.findTruckType(_selectedType!) : null;
    final city = _selectedCityId != null ? widget.game.getCityById(_selectedCityId!) : null;
    final canBuy = _selectedType != null && _nameCtrl.text.trim().isNotEmpty && _selectedCityId != null && (info != null && money >= info.price);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping, color: Color(0xFFF5C542), size: 22),
                  const SizedBox(width: 10),
                  Text('Купить грузовик', style: AppTheme.h2.copyWith(color: const Color(0xFFD0D0D0))),
                  const Spacer(),
                  Text(GameConstants.formatMoney(money), style: AppTheme.mono.copyWith(color: const Color(0xFF66BB6A), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Color(0xFFD0D0D0)),
                decoration: InputDecoration(
                  labelText: 'Название',
                  hintText: 'Мой грузовик #1',
                  labelStyle: const TextStyle(color: Color(0xFF888888)),
                  hintStyle: const TextStyle(color: Color(0xFF666666)),
                  helperText: _nameCtrl.text.trim().isEmpty ? 'Введите название грузовика' : null,
                  helperStyle: const TextStyle(color: Color(0xFFF5C542), fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              // City selection (searchable dropdown)
              Text('Город покупки:', style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCityId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF252525),
                    hint: Text('Выберите город', style: const TextStyle(color: Color(0xFF666666), fontSize: 13)),
                    style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 13),
                    items: widget.game.cities.map((c) {
                      final hasW = widget.game.myWarehouses.any((w) => w.cityId == c.id);
                      return DropdownMenuItem(
                        value: c.id,
                        child: Row(children: [
                          Icon(hasW ? Icons.warehouse : Icons.location_city, size: 14, color: hasW ? const Color(0xFF66BB6A) : const Color(0xFF888888)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                          Text(c.country, style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
                        ]),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCityId = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Тип грузовика:', style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...GameConstants.truckTypes.map((t) => _TruckOption(
                info: t,
                selected: _selectedType == t.type,
                canAfford: money >= t.price,
                onTap: () => setState(() => _selectedType = t.type),
              )),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canBuy && !_isBuying ? () => _buy() : null,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5C542), foregroundColor: const Color(0xFF1A1A1A)),
                  child: _isBuying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF1A1A1A), strokeWidth: 2))
                      : Text(_selectedType != null
                          ? 'Купить за ${GameConstants.formatMoney(info?.price ?? 0)}'
                          : 'Выберите тип и город'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _buy() async {
    setState(() => _isBuying = true);
    _error = null;
    final ok = await widget.game.buyTruck(
      widget.companyId, _selectedType!, _nameCtrl.text.trim(), _selectedCityId!,
    );
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Грузовик \"${_nameCtrl.text.trim()}\" куплен!'), backgroundColor: const Color(0xFF66BB6A), behavior: SnackBarBehavior.floating),
        );
      } else {
        setState(() => _error = widget.game.error ?? 'Ошибка покупки');
      }
    }
  }
}

/// Small dots showing upgrade levels on truck card
class _UpgradeIndicators extends StatelessWidget {
  final Truck truck;
  const _UpgradeIndicators({required this.truck});

  @override
  Widget build(BuildContext context) {
    final hasUpgrades = truck.engineLevel > 0 || truck.tankLevel > 0 || truck.cabinLevel > 0 || truck.paintColor != 'default';
    if (!hasUpgrades) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (truck.engineLevel > 0) ...[
          Icon(Icons.bolt, size: 11, color: const Color(0xFF42A5F5)),
          const SizedBox(width: 2),
          Text('E$truck.engineLevel', style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 9, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
        ],
        if (truck.tankLevel > 0) ...[
          Icon(Icons.local_gas_station, size: 11, color: const Color(0xFF66BB6A)),
          const SizedBox(width: 2),
          Text('T$truck.tankLevel', style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 9, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
        ],
        if (truck.cabinLevel > 0) ...[
          Icon(Icons.airline_seat_recline_normal, size: 11, color: const Color(0xFFCE93D8)),
          const SizedBox(width: 2),
          Text('C$truck.cabinLevel', style: const TextStyle(color: Color(0xFFCE93D8), fontSize: 9, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
        ],
        if (truck.paintColor != 'default') ...[
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: truck.paintColorValue, border: Border.all(color: const Color(0xFF555555), width: 0.5))),
        ],
      ],
    );
  }
}

/// Upgrade dialog — shows all upgrade categories
class _UpgradeDialog extends StatefulWidget {
  final Truck truck;
  final GameProvider game;
  final String companyId;
  const _UpgradeDialog({required this.truck, required this.game, required this.companyId});

  @override
  State<_UpgradeDialog> createState() => _UpgradeDialogState();
}

class _UpgradeDialogState extends State<_UpgradeDialog> {
  bool _isUpgrading = false;
  String? _error;

  // Live truck state (updated after upgrades)
  Truck get _truck {
    final latest = widget.game.myTrucks.where((t) => t.id == widget.truck.id).firstOrNull;
    return latest ?? widget.truck;
  }

  static const _engineCosts = [5000, 15000, 40000];
  static const _tankCosts = [3000, 8000, 20000];
  static const _cabinCosts = [4000, 12000, 30000];
  static const _paintCost = 2000;

  static const _paintColors = [
    ('default', 'Стандарт', Color(0xFF90A4AE)),
    ('red', 'Красный', Color(0xFFEF5350)),
    ('blue', 'Синий', Color(0xFF42A5F5)),
    ('green', 'Зелёный', Color(0xFF66BB6A)),
    ('gold', 'Золотой', Color(0xFFF5C542)),
    ('black', 'Чёрный', Color(0xFF212121)),
    ('white', 'Белый', Color(0xFFEEEEEE)),
    ('purple', 'Фиолетовый', Color(0xFFCE93D8)),
  ];

  @override
  Widget build(BuildContext context) {
    final money = widget.game.company?.money ?? 0;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
      child: Container(
        width: 460,
        constraints: const BoxConstraints(maxHeight: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.tune, color: Color(0xFFCE93D8), size: 22),
                  const SizedBox(width: 10),
                  Text('Улучшения: ${_truck.name}', style: AppTheme.h2.copyWith(color: const Color(0xFFD0D0D0))),
                  const Spacer(),
                  Text(GameConstants.formatMoney(money), style: AppTheme.mono.copyWith(color: const Color(0xFF66BB6A), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),

              // Engine upgrade
              _UpgradeSection(
                icon: Icons.bolt,
                title: 'Двигатель',
                color: const Color(0xFF42A5F5),
                currentLevel: _truck.engineLevel,
                maxLevel: 3,
                costs: _engineCosts,
                effectLabels: const ['+10% скорости', '+20% скорости', '+30% скорости'],
                money: money,
                onUpgrade: _truck.engineLevel < 3 ? () => _upgrade('engine', '${_truck.engineLevel + 1}') : null,
                isUpgrading: _isUpgrading,
              ),
              const SizedBox(height: 12),

              // Tank upgrade
              _UpgradeSection(
                icon: Icons.local_gas_station,
                title: 'Топливный бак',
                color: const Color(0xFF66BB6A),
                currentLevel: _truck.tankLevel,
                maxLevel: 3,
                costs: _tankCosts,
                effectLabels: const ['+20% ёмкости', '+40% ёмкости', '+60% ёмкости'],
                money: money,
                onUpgrade: _truck.tankLevel < 3 ? () => _upgrade('tank', '${_truck.tankLevel + 1}') : null,
                isUpgrading: _isUpgrading,
              ),
              const SizedBox(height: 12),

              // Cabin upgrade
              _UpgradeSection(
                icon: Icons.airline_seat_recline_normal,
                title: 'Кабина',
                color: const Color(0xFFCE93D8),
                currentLevel: _truck.cabinLevel,
                maxLevel: 3,
                costs: _cabinCosts,
                effectLabels: const ['-25% износа', '-50% износа', '-75% износа'],
                money: money,
                onUpgrade: _truck.cabinLevel < 3 ? () => _upgrade('cabin', '${_truck.cabinLevel + 1}') : null,
                isUpgrading: _isUpgrading,
              ),
              const SizedBox(height: 16),

              // Paint section
              const Text('Покраска', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _paintColors.map((entry) {
                        final (colorName, label, color) = entry;
                        final isSelected = _truck.paintColor == colorName;
                        final canAfford = money >= _paintCost || isSelected;
                        return InkWell(
                          onTap: canAfford && !_isUpgrading ? () => _upgrade('paint', colorName) : null,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.15) : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? color : const Color(0xFF3A3A3A), width: isSelected ? 2 : 1),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: colorName == 'black' ? const Color(0xFF555555) : Colors.transparent, width: 0.5)),
                                ),
                                const SizedBox(height: 3),
                                Text(label, style: TextStyle(color: canAfford ? const Color(0xFFD0D0D0) : const Color(0xFF555555), fontSize: 8, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_truck.paintColor != 'default' || money >= _paintCost)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _truck.paintColor == 'default' ? 'Покраска: €${GameConstants.formatMoney(_paintCost)}' : 'Текущий цвет установлен. Повторная покраска: €${GameConstants.formatMoney(_paintCost)}',
                          style: TextStyle(color: const Color(0xFF888888), fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12)),
              ],

              const SizedBox(height: 12),
              // Close button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF888888),
                    side: const BorderSide(color: Color(0xFF3A3A3A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Закрыть'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _upgrade(String type, String value) async {
    setState(() { _isUpgrading = true; _error = null; });
    final ok = await widget.game.upgradeTruck(_truck.id, widget.companyId, type, value);
    if (mounted) {
      setState(() { _isUpgrading = false; });
      if (ok) {
        setState(() {}); // refresh _truck getter
      } else {
        setState(() { _error = widget.game.error ?? 'Ошибка улучшения'; });
      }
    }
  }
}

/// Single upgrade section widget with level bars
class _UpgradeSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final int currentLevel;
  final int maxLevel;
  final List<int> costs;
  final List<String> effectLabels;
  final int money;
  final VoidCallback? onUpgrade;
  final bool isUpgrading;

  const _UpgradeSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.currentLevel,
    required this.maxLevel,
    required this.costs,
    required this.effectLabels,
    required this.money,
    this.onUpgrade,
    this.isUpgrading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMaxed = currentLevel >= maxLevel;
    final nextCost = !isMaxed ? costs[currentLevel] : 0;
    final canAfford = money >= nextCost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (isMaxed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF5C542).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                  child: const Text('МАКС', style: TextStyle(color: Color(0xFFF5C542), fontSize: 10, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Level bars
          Row(
            children: List.generate(maxLevel, (i) {
              final isFilled = i < currentLevel;
              final isNext = i == currentLevel;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 3 : 0),
                  child: Column(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: isFilled ? color : const Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        i < costs.length ? '€${_formatK(costs[i])}' : '',
                        style: TextStyle(
                          color: isNext && !isMaxed ? (canAfford ? const Color(0xFFD0D0D0) : const Color(0xFFEF5350)) : const Color(0xFF555555),
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          // Next level info & upgrade button
          if (!isMaxed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ур.${currentLevel} → Ур.${currentLevel + 1}: ${effectLabels[currentLevel]}',
                    style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: isUpgrading ? null : onUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford ? color : const Color(0xFF3A3A3A),
                      foregroundColor: canAfford ? const Color(0xFF1A1A1A) : const Color(0xFF555555),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    child: isUpgrading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFF1A1A1A), strokeWidth: 2))
                        : Text('€${GameConstants.formatMoney(nextCost)}'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatK(int amount) {
    if (amount >= 1000) return '${amount ~/ 1000}K';
    return '$amount';
  }
}

/// Enhanced sell dialog — choose between instant sell or listing on market
class _SellDialog extends StatelessWidget {
  final Truck truck;
  final int sellPrice;
  final GameProvider game;

  const _SellDialog({required this.truck, required this.sellPrice, required this.game});

  @override
  Widget build(BuildContext context) {
    final typeInfo = GameConstants.findTruckType(truck.truckType);
    final marketPrice = (typeInfo?.price ?? 0) * 2 ~/ 3;
    final money = game.company?.money ?? 0;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sell, color: Color(0xFFEF5350), size: 22),
                const SizedBox(width: 10),
                Text('Продать ${truck.name}?', style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),

            // Instant sell option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3A3A3A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.flash_on, size: 16, color: Color(0xFFEF5350)),
                    const SizedBox(width: 8),
                    const Text('Моментальная продажа', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(GameConstants.formatMoney(sellPrice), style: const TextStyle(color: Color(0xFFEF5350), fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                  ]),
                  const SizedBox(height: 4),
                  const Text('Мгновенно, ${(GameConstants.sellBackRatio * 100).toInt()}% от стоимости', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Market listing option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF5C542).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.store, size: 16, color: Color(0xFFF5C542)),
                    const SizedBox(width: 8),
                    const Text('Выставить на рынок', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(GameConstants.formatMoney(marketPrice), style: const TextStyle(color: Color(0xFFF5C542), fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                  ]),
                  const SizedBox(height: 4),
                  const Text('~67% от стоимости, лот виден другим игрокам 72ч', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, 'cancel'),
                    child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3A3A3A)),
                      minimumSize: const Size(double.infinity, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, 'instant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF5350),
                      foregroundColor: const Color(0xFF1A1A1A),
                      minimumSize: const Size(double.infinity, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Продать'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, 'market'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5C542),
                      foregroundColor: const Color(0xFF1A1A1A),
                      minimumSize: const Size(double.infinity, 38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('На рынок'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TruckOption extends StatelessWidget {
  final TruckTypeInfo info;
  final bool selected;
  final bool canAfford;
  final VoidCallback onTap;
  const _TruckOption({required this.info, required this.selected, required this.canAfford, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = !canAfford;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF5C542).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? const Color(0xFFF5C542) : const Color(0xFF3A3A3A)),
          ),
          child: Row(
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? const Color(0xFFF5C542) : const Color(0xFF666666))),
                child: selected ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF5C542)))) : null,
              ),
              const SizedBox(width: 10),
              // Truck type image
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  GameConstants.truckAssetPath(info.type),
                  width: 40, height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 40, height: 28),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.name, style: TextStyle(color: disabled ? const Color(0xFF666666) : const Color(0xFFD0D0D0), fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('${info.capacity}т  •  ${info.speed}км/ч  •  ${info.fuel}л', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                  ],
                ),
              ),
              Text(
                GameConstants.formatMoney(info.price),
                style: TextStyle(color: canAfford ? const Color(0xFF66BB6A) : const Color(0xFFEF5350), fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
