import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/city.dart';
import '../models/contract.dart';
import '../models/garage.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../utils/pathfinder.dart';

class CityDetailDialog extends StatelessWidget {
  final City city;
  const CityDetailDialog({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();
    final companyId = auth.companyId;
    if (companyId == null) return const SizedBox();

    final contracts = game.availableContracts.where((c) =>
        c.originCityId == city.id || c.destinationCityId == city.id).toList();
    final hasWarehouse = game.myWarehouses.any((w) => w.cityId == city.id);
    final garage = game.garageInCity(city.id);
    final trucksHere = game.myTrucks.where((t) => t.currentCityId == city.id && t.isIdle).length;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
      child: Container(
        width: 440,
        constraints: const BoxConstraints(maxHeight: 580),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header — ETS2 amber palette
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2C),
              border: Border(bottom: BorderSide(color: Color(0xFF444444))),
            ),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF5C542).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_city, color: Color(0xFFF5C542), size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(city.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 16, fontWeight: FontWeight.w700)),
                Text(city.country, style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
              ])),
              if (hasWarehouse)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF66BB6A).withOpacity(0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF66BB6A).withOpacity(0.3))),
                  child: const Text('Склад', style: TextStyle(color: Color(0xFF66BB6A), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              if (garage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFF9800).withOpacity(0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3))),
                  child: Text('Гараж $trucksHere/${garage.slots}', style: const TextStyle(color: Color(0xFFFF9800), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF999999), size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          // City stats
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _stat('${(city.population / 1000000).toStringAsFixed(1)}M', 'Население'),
                _stat(GameConstants.formatMoney(city.warehouseCost), 'Склад'),
                _stat(GameConstants.formatMoney(city.depotFee), 'Парк.'),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _miniStat(Icons.local_shipping, '$trucksHere', 'Грузовиков'),
                _miniStat(Icons.description, '${contracts.length}', 'Контрактов'),
              ]),

              // ===== GARAGE SECTION =====
              if (garage != null) ...[
                const SizedBox(height: 10),
                _GarageSection(garage: garage, cityId: city.id, companyId: companyId, trucksHere: trucksHere),
              ] else ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final game = context.read<GameProvider>();
                      final ok = await game.buyGarage(companyId, city.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Гараж в ${city.name} куплен!' : game.error ?? 'Ошибка'),
                          backgroundColor: ok ? const Color(0xFFFF9800) : const Color(0xFFEF5350),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                    icon: const Icon(Icons.garage, size: 16),
                    label: const Text('Купить гараж — €20K'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF9800),
                      side: const BorderSide(color: Color(0xFFFF9800)),
                      minimumSize: const Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                if (!game.canParkAtCity(city.id))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Без гаража нельзя покупать грузовики', style: TextStyle(color: const Color(0xFFEF5350).withOpacity(0.7), fontSize: 10)),
                  ),
              ],

              // Buy warehouse button
              if (!hasWarehouse) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final game = context.read<GameProvider>();
                      final ok = await game.claimWarehouse(companyId, city.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? 'Склад в ${city.name} куплен!' : game.error ?? 'Ошибка'),
                          backgroundColor: ok ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                          behavior: SnackBarBehavior.floating,
                        ));
                        if (ok) Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.warehouse, size: 16),
                    label: Text('Купить склад — ${GameConstants.formatMoney(city.warehouseCost)}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF42A5F5),
                      side: const BorderSide(color: Color(0xFF42A5F5)),
                      minimumSize: const Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ]),
          ),
          const Divider(height: 1, color: Color(0xFF3A3A3A)),

          // Contracts
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Text('Контракты (${contracts.length})', style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
          ),

          Flexible(
            child: contracts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.description_outlined, size: 32, color: Color(0xFF666666)),
                        const SizedBox(height: 8),
                        const Text('Нет контрактов', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
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
    Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFD0D0D0), fontFamily: 'monospace')),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
  ]);

  Widget _miniStat(IconData icon, String value, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: const Color(0xFFF5C542)),
    const SizedBox(width: 4),
    Text(value, style: const TextStyle(color: Color(0xFFD0D0D0), fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'monospace')),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
  ]);
}

/// Garage info section shown when player owns a garage in the city.
class _GarageSection extends StatelessWidget {
  final Garage garage;
  final int cityId;
  final String companyId;
  final int trucksHere;

  const _GarageSection({
    required this.garage,
    required this.cityId,
    required this.companyId,
    required this.trucksHere,
  });

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isFull = garage.isFull(trucksHere);
    final freeSlots = garage.freeSlots(trucksHere);
    final pct = garage.slots > 0 ? trucksHere / garage.slots : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFull
              ? const Color(0xFFEF5350).withOpacity(0.4)
              : const Color(0xFFFF9800).withOpacity(0.3),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Title row
        Row(children: [
          const Icon(Icons.garage, size: 18, color: Color(0xFFFF9800)),
          const SizedBox(width: 6),
          const Text('Гараж', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(
            '$trucksHere / ${garage.slots}',
            style: TextStyle(
              color: isFull ? const Color(0xFFEF5350) : const Color(0xFFD0D0D0),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Text(
            freeSlots > 0 ? '$freeSlots свободно' : 'Полон',
            style: TextStyle(
              color: isFull ? const Color(0xFFEF5350) : const Color(0xFF66BB6A),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),

        // Slot usage bar
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Stack(children: [
              Container(decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isFull ? const Color(0xFFEF5350) : const Color(0xFFFF9800),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ]),
          ),
        ),

        // Parked trucks list
        if (trucksHere > 0) ...[
          const SizedBox(height: 8),
          ...game.myTrucks
              .where((t) => t.currentCityId == cityId && t.isIdle)
              .take(4)
              .map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(children: [
                      const Icon(Icons.local_shipping, size: 13, color: Color(0xFF66BB6A)),
                      const SizedBox(width: 4),
                      Text(t.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 11, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text(
                        '${t.condition}% • ${t.fuelLevel.toInt()}L',
                        style: const TextStyle(color: Color(0xFF888888), fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ]),
                  )),
          if (game.myTrucks.where((t) => t.currentCityId == cityId && t.isIdle).length > 4)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '+ ещё ${game.myTrucks.where((t) => t.currentCityId == cityId && t.isIdle).length - 4}',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 10),
              ),
            ),
        ],

        // Expand button
        if (!garage.isMaxLevel) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: game.isLoading
                  ? null
                  : () async {
                      final game = context.read<GameProvider>();
                      final ok = await game.expandGarage(companyId, cityId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? 'Гараж расширен (+2 слота)!'
                              : game.error ?? 'Ошибка'),
                          backgroundColor: ok
                              ? const Color(0xFFFF9800)
                              : const Color(0xFFEF5350),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
              icon: const Icon(Icons.expand, size: 14),
              label: Text(
                'Расширить (+2 слота) — ${GameConstants.formatMoney(garage.expansionCost)}',
                style: const TextStyle(fontSize: 11),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF9800),
                side: const BorderSide(color: Color(0xFFFF9800).withOpacity(0.5)),
                minimumSize: const Size(double.infinity, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Максимальный размер гаража',
                style: TextStyle(color: const Color(0xFF888888).withOpacity(0.6), fontSize: 10)),
          ),
      ]),
    );
  }
}

class _ContractCard extends StatefulWidget {
  final Contract contract;
  final String companyId;
  const _ContractCard({required this.contract, required this.companyId});

  @override
  State<_ContractCard> createState() => _ContractCardState();
}

class _ContractCardState extends State<_ContractCard> {
  bool _isAccepting = false;

  Contract get contract => widget.contract;
  String get companyId => widget.companyId;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final origin = game.getCityById(contract.originCityId);
    final dest = game.getCityById(contract.destinationCityId);

    final roadRoute = game.findRoute(contract.originCityId, contract.destinationCityId);
    final dist = roadRoute != null
        ? roadRoute.totalDistanceKm.round()
        : (origin != null && dest != null
            ? haversineKm(origin.latitude, origin.longitude, dest.latitude, dest.longitude).round()
            : 0);

    final hasIdle = game.idleTrucks.isNotEmpty;
    final nearest = hasIdle ? game.findNearestIdleTruck(contract.originCityId) : null;
    final isOrigin = contract.originCityId == origin?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: (isOrigin ? const Color(0xFF66BB6A) : const Color(0xFFEF5350)).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(isOrigin ? 'Откуда' : 'Куда', style: TextStyle(color: isOrigin ? const Color(0xFF66BB6A) : const Color(0xFFEF5350), fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          _CargoIcon(cargoType: contract.cargoType),
          const SizedBox(width: 6),
          Expanded(child: Text(contract.cargoType, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600))),
          Text(
            GameConstants.formatMoney(contract.reward),
            style: const TextStyle(color: Color(0xFF66BB6A), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace'),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text('${origin?.name ?? '?'}  \u2192  ${dest?.name ?? '?'}', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
          const Spacer(),
          Text('${contract.cargoWeight}т  •  ${dist}km', style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontFamily: 'monospace')),
        ]),
        const SizedBox(height: 8),
        if (nearest != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !_isAccepting ? () => _accept(context, game) : null,
              icon: _isAccepting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF1A1A1A), strokeWidth: 2))
                  : const Icon(Icons.check, size: 16),
              label: Text(_isAccepting ? 'Принятие...' : 'Принять (${nearest.name})', style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5C542),
                foregroundColor: const Color(0xFF1A1A1A),
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
              color: const Color(0xFFEF5350).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF5350).withOpacity(0.2)),
            ),
            child: Text(
              game.idleTrucks.isEmpty ? 'Нет свободных грузовиков' : 'Нет грузовиков рядом',
              style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
      ]),
    );
  }

  void _accept(BuildContext context, GameProvider game) async {
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
            : game.error ?? 'Ошибка'),
        backgroundColor: result.success ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
      ));
      if (result.success) Navigator.pop(context);
    }
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
