import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/city.dart';
import '../models/contract.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class CityDetailDialog extends StatelessWidget {
  final City city;
  const CityDetailDialog({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();
    final companyId = auth.companyId;
    if (companyId == null) return const SizedBox();

    // Find contracts related to this city
    final contracts = game.availableContracts.where((c) =>
        c.originCityId == city.id || c.destinationCityId == city.id).toList();

    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.divider)),
      child: Container(
        width: 440,
        constraints: const BoxConstraints(maxHeight: 580),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_city, color: AppTheme.accent, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(city.name, style: AppTheme.h2),
                Text(city.country, style: AppTheme.bodySm),
              ])),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          // City stats
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('${(city.population / 1000).round()}K', 'Население'),
              _stat(GameConstants.formatMoney(city.warehouseCost), 'Склад'),
              _stat(GameConstants.formatMoney(city.depotFee), 'Парк.'),
            ]),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          // Contracts header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(children: [
              Text('Контракты (${contracts.length})', style: AppTheme.labelSm),
              const Spacer(),
            ]),
          ),

          // Contract list
          Flexible(
            child: contracts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.description_outlined, size: 32, color: AppTheme.textMuted.withOpacity(0.4)),
                        const SizedBox(height: 8),
                        Text('Нет контрактов в этом городе', style: AppTheme.bodySm, textAlign: TextAlign.center),
                      ]),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: contracts.length,
                    itemBuilder: (context, i) => _ContractCard(contract: contracts[i], companyId: companyId),
                  ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _stat(String val, String label) => Column(children: [
    Text(val, style: AppTheme.mono.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
    const SizedBox(height: 2),
    Text(label, style: AppTheme.bodySm),
  ]);
}

class _ContractCard extends StatelessWidget {
  final Contract contract;
  final String companyId;
  const _ContractCard({required this.contract, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final origin = game.getCityById(contract.originCityId);
    final dest = game.getCityById(contract.destinationCityId);

    final dist = origin != null && dest != null
        ? _haversineKm(origin.latitude, origin.longitude, dest.latitude, dest.longitude).round()
        : 0;

    final hasIdle = game.idleTrucks.isNotEmpty;
    final nearest = hasIdle ? game.findNearestIdleTruck(contract.originCityId) : null;

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent)),
            const SizedBox(width: 8),
            Expanded(child: Text(contract.cargoType, style: AppTheme.label)),
            Text(
              GameConstants.formatMoney(contract.reward),
              style: AppTheme.mono.copyWith(color: AppTheme.green, fontWeight: FontWeight.bold),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Text('${origin?.name ?? '?'}  \u2192  ${dest?.name ?? '?'}', style: AppTheme.bodySm),
            const Spacer(),
            Text('${contract.cargoWeight}т  |  ${dist}km', style: AppTheme.monoSm),
          ]),
          const SizedBox(height: 8),
          if (nearest != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _accept(context, game),
                icon: const Icon(Icons.check, size: 16),
                label: Text('Принять (${nearest.name})', style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.red.withOpacity(0.2)),
              ),
              child: Text(
                game.idleTrucks.isEmpty ? 'Нет свободных грузовиков' : 'Нет грузовиков рядом',
                style: AppTheme.bodySm.copyWith(color: AppTheme.red),
                textAlign: TextAlign.center,
              ),
            ),
        ]),
      ),
    );
  }

  void _accept(BuildContext context, GameProvider game) async {
    final result = await game.acceptContract(
      contractId: contract.id,
      truckId: null, // Auto-assign nearest
      companyId: companyId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.success
            ? 'Контракт принят! Грузовик: ${result.truckName}'
            : game.error ?? 'Ошибка'),
        backgroundColor: result.success ? AppTheme.green : AppTheme.red,
        behavior: SnackBarBehavior.floating,
      ));
      if (result.success) Navigator.pop(context);
    }
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
