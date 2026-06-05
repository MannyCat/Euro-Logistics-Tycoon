import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/city.dart';
import '../models/warehouse.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  List<Warehouse> _warehouses = [];
  bool _isLoading = false;
  bool _showBuyMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWarehouses());
  }

  Future<void> _loadWarehouses() async {
    final auth = context.read<AuthProvider>();
    final companyId = auth.companyId;
    if (companyId == null) return;
    setState(() => _isLoading = true);
    try {
      final resp = await Supabase.instance.client
          .from('warehouses')
          .select()
          .eq('company_id', companyId);
      _warehouses = resp.map<Warehouse>((e) => Warehouse.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Load warehouses error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _buyWarehouse(int cityId) async {
    final auth = context.read<AuthProvider>();
    final game = context.read<GameProvider>();
    final companyId = auth.companyId;
    if (companyId == null) return;

    final ok = await game.claimWarehouse(companyId, cityId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Склад куплен!' : game.error ?? 'Ошибка'),
        backgroundColor: ok ? AppTheme.green : AppTheme.red,
        behavior: SnackBarBehavior.floating,
      ));
      if (ok) {
        await _loadWarehouses();
        await game.loadCompany(companyId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final companyId = auth.companyId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Филиалы'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showBuyMode = !_showBuyMode),
            icon: Icon(_showBuyMode ? Icons.close : Icons.add_business_outlined, color: AppTheme.accent, size: 18),
            label: Text(_showBuyMode ? 'Готово' : 'Купить склад', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _showBuyMode
              ? _BuyWarehouseView(game: game, companyId: companyId, onPurchased: _loadWarehouses)
              : _WarehouseListView(warehouses: _warehouses, game: game),
    );
  }
}

class _WarehouseListView extends StatelessWidget {
  final List<Warehouse> warehouses;
  final GameProvider game;
  const _WarehouseListView({required this.warehouses, required this.game});

  @override
  Widget build(BuildContext context) {
    if (warehouses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warehouse_outlined, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('Нет филиалов', style: AppTheme.h2),
            const SizedBox(height: 4),
            Text('Покупайте склады в городах для расширения сети', style: AppTheme.bodySm),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: warehouses.length,
      itemBuilder: (context, i) {
        final w = warehouses[i];
        final city = game.getCityById(w.cityId);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.warehouse, color: AppTheme.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(city?.name ?? 'Город #${w.cityId}', style: AppTheme.label),
                Row(children: [
                  Text(city?.country ?? '', style: AppTheme.bodySm),
                  const SizedBox(width: 12),
                  Text('Ур. ${w.level}', style: AppTheme.bodySm),
                  const SizedBox(width: 12),
                  Text('Вмст: ${w.capacity}т', style: AppTheme.bodySm),
                ]),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: w.isActive ? AppTheme.green.withOpacity(0.15) : AppTheme.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: w.isActive ? AppTheme.green.withOpacity(0.3) : AppTheme.red.withOpacity(0.3)),
                ),
                child: Text(
                  w.isActive ? 'Активен' : 'Неактивен',
                  style: AppTheme.bodySm.copyWith(
                    color: w.isActive ? AppTheme.green : AppTheme.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _BuyWarehouseView extends StatelessWidget {
  final GameProvider game;
  final String companyId;
  final VoidCallback onPurchased;
  const _BuyWarehouseView({required this.game, required this.companyId, required this.onPurchased});

  @override
  Widget build(BuildContext context) {
    final cities = game.cities;
    final money = game.company?.money ?? 0;

    // Find cities where we don't already have a warehouse
    final ownedCities = game.myWarehouses.map((w) => w.cityId).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.surface,
          child: Row(children: [
            Icon(Icons.info_outline, color: AppTheme.accent, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Выберите город для покупки склада', style: AppTheme.body)),
            const Spacer(),
            Text(GameConstants.formatMoney(money), style: AppTheme.mono.copyWith(color: AppTheme.green, fontWeight: FontWeight.bold)),
          ]),
        ),
        const Divider(height: 1, color: AppTheme.divider),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: cities.length,
            itemBuilder: (context, i) {
              final city = cities[i];
              final alreadyOwned = ownedCities.contains(city.id);
              final canAfford = money >= city.warehouseCost;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.location_city, color: AppTheme.accent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(city.name, style: AppTheme.label),
                      Row(children: [
                        Text(city.country, style: AppTheme.bodySm),
                        const SizedBox(width: 8),
                        Text('Вмст: ${city.warehouseCost ~/ 1000}K', style: AppTheme.monoSm),
                      ]),
                    ])),
                    if (alreadyOwned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text('Есть', style: AppTheme.bodySm.copyWith(color: AppTheme.green)),
                      )
                    else
                      TextButton(
                        onPressed: canAfford ? () async {
                          await game.claimWarehouse(companyId, city.id);
                          onPurchased();
                        } : null,
                        child: Text(GameConstants.formatMoney(city.warehouseCost), style: TextStyle(
                          color: canAfford ? AppTheme.green : AppTheme.red,
                          fontWeight: FontWeight.bold,
                        )),
                      ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
