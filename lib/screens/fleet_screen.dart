import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
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
      appBar: AppBar(title: const Text('Автопарк'), actions: [
        IconButton(icon: const Icon(Icons.add, color: AppTheme.accent), onPressed: () => _showBuyDialog(context, game, companyId)),
      ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: game.myTrucks.length,
        itemBuilder: (context, i) => _TruckCard(truck: game.myTrucks[i], game: game, companyId: companyId),
      ),
    );
  }

  void _showBuyDialog(BuildContext context, GameProvider game, String companyId) {
    showDialog(context: context, builder: (ctx) => _BuyTruckDialog(game: game, companyId: companyId));
  }
}

class _TruckCard extends StatelessWidget {
  final dynamic truck;
  final GameProvider game;
  final String companyId;
  const _TruckCard({required this.truck, required this.game, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final typeInfo = GameConstants.findTruckType(truck.truckType);
    final originCity = truck.originCityId != null ? game.getCityById(truck.originCityId!) : null;
    final destCity = truck.destinationCityId != null ? game.getCityById(truck.destinationCityId!) : null;
    final curCity = truck.currentCityId != null ? game.getCityById(truck.currentCityId!) : null;
    final color = truck.isInTransit ? AppTheme.amber : AppTheme.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(truck.isInTransit ? Icons.local_shipping : Icons.directions_boat, color: color, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(truck.name, style: AppTheme.label),
              Text(typeInfo?.name ?? truck.truckType, style: AppTheme.bodySm),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(truck.statusDisplay, style: AppTheme.bodySm.copyWith(color: color)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Сост: ${truck.condition}%', style: AppTheme.monoSm),
            Text('Топливо: ${truck.fuelLevel.toStringAsFixed(0)}%', style: AppTheme.monoSm),
            if (curCity != null) Text('Город: ${curCity.name}', style: AppTheme.bodySm),
          ]),
          if (truck.isInTransit) ...[
            const SizedBox(height: 4),
            Text('${originCity?.name ?? '?'} → ${destCity?.name ?? '?'}', style: AppTheme.bodySm.copyWith(color: AppTheme.amber)),
          ],
          if (truck.isIdle) Row(children: [
            const SizedBox(height: 8),
            Expanded(child: TextButton(onPressed: () => game.refuelTruck(truck.id, companyId), child: const Text('Заправить'))),
            Expanded(child: TextButton(onPressed: () => game.repairTruck(truck.id, companyId), child: const Text('Ремонт'))),
          ]),
        ]),
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

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(width: 380, padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Купить грузовик', style: AppTheme.h2),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Название', hintText: 'Мой грузовик #1')),
        const SizedBox(height: 12),
        ...GameConstants.truckTypes.map((t) => RadioListTile<String>(
          title: Text(t.name, style: AppTheme.body),
          subtitle: Text('${t.capacity}т | ${t.speed}км/ч | \u20AC${t.price}', style: AppTheme.bodySm),
          value: t.type, groupValue: _selectedType, onChanged: (v) => setState(() => _selectedType = v),
          activeColor: AppTheme.accent,
        )),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: (_selectedType == null || _nameCtrl.text.isEmpty) ? null : () async {
            final ok = await widget.game.buyTruck(widget.companyId, _selectedType!, _nameCtrl.text.trim());
            if (context.mounted) { Navigator.pop(context); if (ok) context.go('/fleet'); }
          },
          child: Text('Купить за \u20AC${_selectedType != null ? GameConstants.findTruckType(_selectedType!)?.price ?? 0 : 0}'),
        ),
      ])),
    );
  }
}
