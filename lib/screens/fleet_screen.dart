import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/truck.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';

class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final companyId = auth.companyId ?? '';

    return ETS2Modal(
      title: 'Автопарк',
      icon: Icons.local_shipping,
      actions: [
        if (game.myTrucks.length < 20)
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
                          _filterChip('Все (${game.myTrucks.length})', true),
                          const SizedBox(width: 6),
                          _filterChip('Свободных (${game.idleTrucks.length})', false),
                          const SizedBox(width: 6),
                          _filterChip('В пути (${game.transitTrucks.length})', false),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF3A3A3A)),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: game.myTrucks.length,
                        itemBuilder: (context, i) => _TruckCard(truck: game.myTrucks[i], game: game, companyId: companyId),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _filterChip(String label, bool selected) => Container(
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
  );

  void _showBuyDialog(BuildContext context, GameProvider game, String companyId) {
    showDialog(context: context, builder: (ctx) => _BuyTruckDialog(game: game, companyId: companyId));
  }
}

class _TruckCard extends StatelessWidget {
  final Truck truck;
  final GameProvider game;
  final String companyId;
  const _TruckCard({required this.truck, required this.game, required this.companyId});

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
                width: 42, height: 42,
                decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(truck.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(typeInfo?.name ?? truck.truckType, style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat('Сост.', '${truck.condition}%', truck.condition < 30 ? const Color(0xFFEF5350) : const Color(0xFF888888)),
              _stat('Топливо', '${truck.fuelLevel.toStringAsFixed(0)}%', const Color(0xFF888888)),
              if (curCity != null)
                Expanded(
                  child: Text(curCity.name, style: const TextStyle(color: Color(0xFF888888), fontSize: 12), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
          if (truck.isInTransit && originCity != null && destCity != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5C542).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF5C542).withOpacity(0.2)),
              ),
              child: Row(
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
            ),
          ],
          if (truck.isIdle) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async { await game.refuelTruck(truck.id, companyId); },
                    icon: const Icon(Icons.local_gas_station, size: 14),
                    label: const Text('Заправить'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF42A5F5),
                      side: const BorderSide(color: Color(0xFF42A5F5)),
                      minimumSize: const Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: truck.condition < 100 ? () async { await game.repairTruck(truck.id, companyId); } : null,
                    icon: const Icon(Icons.build, size: 14),
                    label: const Text('Ремонт'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF5C542),
                      side: const BorderSide(color: Color(0xFFF5C542)),
                      minimumSize: const Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final money = widget.game.company?.money ?? 0;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
      child: Container(
        width: 420,
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
              ),
            ),
            const SizedBox(height: 12),
            ...GameConstants.truckTypes.map((t) => _TruckOption(
              info: t,
              selected: _selectedType == t.type,
              canAfford: money >= t.price,
              onTap: () => setState(() => _selectedType = t.type),
            )),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: (_selectedType == null || _nameCtrl.text.trim().isEmpty) ? null : () async {
                final info = GameConstants.findTruckType(_selectedType!);
                if (info == null) return;
                final ok = await widget.game.buyTruck(
                  widget.companyId, _selectedType!, _nameCtrl.text.trim(), 1,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Грузовик "${_nameCtrl.text.trim()}" куплен!'), backgroundColor: const Color(0xFF66BB6A), behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5C542), foregroundColor: const Color(0xFF1A1A1A)),
              child: Text(_selectedType != null
                  ? 'Купить за ${GameConstants.formatMoney(GameConstants.findTruckType(_selectedType!)?.price ?? 0)}'
                  : 'Выберите тип'),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.name, style: TextStyle(color: disabled ? const Color(0xFF666666) : const Color(0xFFD0D0D0), fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('${info.capacity}т | ${info.speed}км/ч | ${info.fuel}л', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
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
