import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/warehouse.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';

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
      final resp = await Supabase.instance.client.from('warehouses').select().eq('company_id', companyId);
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
        backgroundColor: ok ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
      ));
      if (ok) { await _loadWarehouses(); await game.loadCompany(companyId); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final companyId = auth.companyId ?? '';

    return ETS2Modal(
      title: 'Филиалы',
      icon: Icons.warehouse,
      actions: [
        TextButton.icon(
          onPressed: () => setState(() => _showBuyMode = !_showBuyMode),
          icon: Icon(_showBuyMode ? Icons.close : Icons.add_business_outlined, color: const Color(0xFFF5C542), size: 18),
          label: Text(_showBuyMode ? 'Готово' : 'Купить склад', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 12)),
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5C542)))
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
            const Icon(Icons.warehouse_outlined, size: 48, color: Color(0xFF666666)),
            const SizedBox(height: 12),
            Text('Нет филиалов', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
            const SizedBox(height: 4),
            const Text('Покупайте склады в городах для расширения сети', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
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
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
          child: Row(
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF42A5F5).withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.warehouse, color: Color(0xFF42A5F5), size: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(city?.name ?? 'Город #${w.cityId}', style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 14, fontWeight: FontWeight.w600)),
                    Row(children: [
                      Text(city?.country ?? '', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                      const SizedBox(width: 12),
                      Text('Ур. ${w.level}', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                      const SizedBox(width: 12),
                      Text('Вмст: ${w.capacity}т', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: w.isActive ? const Color(0xFF66BB6A).withOpacity(0.15) : const Color(0xFFEF5350).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: w.isActive ? const Color(0xFF66BB6A).withOpacity(0.3) : const Color(0xFFEF5350).withOpacity(0.3)),
                ),
                child: Text(w.isActive ? 'Активен' : 'Неактивен', style: TextStyle(color: w.isActive ? const Color(0xFF66BB6A) : const Color(0xFFEF5350), fontWeight: FontWeight.w600, fontSize: 11)),
              ),
            ],
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
    final ownedCities = game.myWarehouses.map((w) => w.cityId).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF252525),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF42A5F5), size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('Выберите город для покупки склада', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12))),
              Text(GameConstants.formatMoney(money), style: const TextStyle(color: Color(0xFF66BB6A), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace')),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF3A3A3A)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: cities.length,
            itemBuilder: (context, i) {
              final city = cities[i];
              final alreadyOwned = ownedCities.contains(city.id);
              final canAfford = money >= city.warehouseCost;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
                child: Row(
                  children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF42A5F5).withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.location_city, color: Color(0xFF42A5F5), size: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(city.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600)),
                          Row(children: [
                            Text(city.country, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                            const SizedBox(width: 8),
                            Text('Цена: ${GameConstants.formatMoney(city.warehouseCost)}', style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontFamily: 'monospace')),
                          ]),
                        ],
                      ),
                    ),
                    if (alreadyOwned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF66BB6A).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: const Text('Есть', style: TextStyle(color: Color(0xFF66BB6A), fontSize: 11)),
                      )
                    else
                      TextButton(
                        onPressed: canAfford ? () async { await game.claimWarehouse(companyId, city.id); onPurchased(); } : null,
                        child: Text(GameConstants.formatMoney(city.warehouseCost), style: TextStyle(color: canAfford ? const Color(0xFF66BB6A) : const Color(0xFFEF5350), fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
