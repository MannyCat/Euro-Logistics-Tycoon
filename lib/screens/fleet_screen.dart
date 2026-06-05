import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/truck.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class FleetScreen extends StatelessWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final companyId = auth.companyId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Автопарк'),
        actions: [
          if (game.myTrucks.length < 20)
            IconButton(
              icon: const Icon(Icons.add, color: AppTheme.accent),
              tooltip: 'Купить грузовик',
              onPressed: () => _showBuyDialog(context, game, companyId),
            ),
        ],
      ),
      body: game.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : game.myTrucks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text('Нет грузовиков', style: AppTheme.h2),
                      const SizedBox(height: 4),
                      Text('Купите первый грузовик, чтобы начать', style: AppTheme.bodySm),
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
                    // Filters
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          FilterChip(
                            label: Text('Все (${game.myTrucks.length})', style: AppTheme.bodySm),
                            selected: true,
                            onSelected: (_) {},
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text('Свободных (${game.idleTrucks.length})', style: AppTheme.bodySm),
                            selected: false,
                            onSelected: (_) {},
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: Text('В пути (${game.transitTrucks.length})', style: AppTheme.bodySm),
                            selected: false,
                            onSelected: (_) {},
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.divider),
                    // List
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
        statusColor = AppTheme.amber;
        statusIcon = Icons.local_shipping;
        break;
      case 'loading':
        statusColor = AppTheme.accentLight;
        statusIcon = Icons.hourglass_top;
        break;
      case 'maintenance':
        statusColor = AppTheme.red;
        statusIcon = Icons.build;
        break;
      default: // idle
        statusColor = AppTheme.green;
        statusIcon = Icons.check_circle;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(statusIcon, color: statusColor, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(truck.name, style: AppTheme.label),
              Text(typeInfo?.name ?? truck.truckType, style: AppTheme.bodySm),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: statusColor.withOpacity(0.3))),
              child: Text(truck.statusDisplay, style: AppTheme.bodySm.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 10),
          // Stats row
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _stat('Сост.', '${truck.condition}%', truck.condition < 30 ? AppTheme.red : AppTheme.textDim),
            _stat('Топливо', '${truck.fuelLevel.toStringAsFixed(0)}%', AppTheme.textDim),
            if (curCity != null) Expanded(child: Text(curCity.name, style: AppTheme.bodySm, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
          ]),
          // Transit info
          if (truck.isInTransit && originCity != null && destCity != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.amber.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.amber.withOpacity(0.2))),
              child: Row(children: [
                Icon(Icons.trip_origin, size: 14, color: AppTheme.green),
                const SizedBox(width: 6),
                Expanded(child: Text('${originCity.name}  \u2192  ${destCity.name}', style: AppTheme.bodySm.copyWith(color: AppTheme.amber))),
                if (truck.estimatedArrival != null) ...[
                  const SizedBox(width: 8),
                  Text(_timeLeft(truck.estimatedArrival!), style: AppTheme.monoSm.copyWith(color: AppTheme.amber)),
                ],
              ]),
            ),
          ],
          // Idle actions
          if (truck.isIdle) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async { await game.refuelTruck(truck.id, companyId); },
                  icon: const Icon(Icons.local_gas_station, size: 16),
                  label: const Text('Заправить'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: truck.condition < 100 ? () async { await game.repairTruck(truck.id, companyId); } : null,
                  icon: const Icon(Icons.build, size: 16),
                  label: const Text('Ремонт'),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text('$label: ', style: AppTheme.bodySm),
    Text(value, style: AppTheme.monoSm.copyWith(color: color, fontWeight: FontWeight.w600)),
    const SizedBox(width: 12),
  ]);

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
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.divider)),
      child: Container(width: 420, padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Icon(Icons.local_shipping, color: AppTheme.accent, size: 22),
          const SizedBox(width: 10),
          Text('Купить грузовик', style: AppTheme.h2),
          const Spacer(),
          Text(GameConstants.formatMoney(money), style: AppTheme.mono.copyWith(color: AppTheme.green, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Название', hintText: 'Мой грузовик #1'),
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
              widget.companyId,
              _selectedType!,
              _nameCtrl.text.trim(),
              1, // Start in London
            );
            if (context.mounted) {
              Navigator.pop(context);
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Грузовик "${_nameCtrl.text.trim()}" куплен!'), backgroundColor: AppTheme.green, behavior: SnackBarBehavior.floating),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(widget.game.error ?? 'Ошибка'), backgroundColor: AppTheme.red, behavior: SnackBarBehavior.floating),
                );
              }
            }
          },
          child: Text(_selectedType != null
              ? 'Купить за ${GameConstants.formatMoney(GameConstants.findTruckType(_selectedType!)?.price ?? 0)}'
              : 'Выберите тип'),
        ),
      ])),
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
      child: Material(
        color: selected ? AppTheme.accent.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? AppTheme.accent : AppTheme.divider),
            ),
            child: Row(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? AppTheme.accent : AppTheme.textMuted)),
                child: selected ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent))) : null,
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(info.name, style: AppTheme.label.copyWith(color: disabled ? AppTheme.textMuted : null)),
                Text('${info.capacity}т | ${info.speed}км/ч | ${info.fuel}л', style: AppTheme.bodySm),
              ])),
              Text(
                GameConstants.formatMoney(info.price),
                style: AppTheme.mono.copyWith(color: canAfford ? AppTheme.green : AppTheme.red, fontWeight: FontWeight.bold),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
