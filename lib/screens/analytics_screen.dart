import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/game_provider.dart';
import '../utils/pathfinder.dart';
import '../widgets/ets2_modal.dart';
import '../config/app_icons.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final company = game.company;

    return ETS2Modal(
      title: 'Аналитика',
      icon: AppIcons.analytics,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ===== SUMMARY CARDS =====
          _sectionTitle('Обзор компании'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _SummaryCard(
                icon: AppIcons.euro,
                iconColor: const Color(0xFFF5C542),
                label: 'Баланс',
                value: company != null ? company.moneyFormatted : '—',
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard(
                icon: AppIcons.truck,
                iconColor: const Color(0xFF42A5F5),
                label: 'Грузовики',
                value: '${game.myTrucks.length} / ${GameConstants.maxTrucksAtLevel(company?.level ?? 1)}',
                subtitle: 'Свободных: ${game.idleTrucks.length}',
              )),
              const SizedBox(width: 8),
              Expanded(child: _SummaryCard(
                icon: AppIcons.description,
                iconColor: const Color(0xFF66BB6A),
                label: 'Контрактов',
                value: '${_completedContracts(game)}',
                subtitle: 'Активных: ${game.transitTrucks.length}',
              )),
            ],
          ),

          const SizedBox(height: 16),

          // ===== INCOME VS EXPENSES =====
          _sectionTitle('Финансы'),
          const SizedBox(height: 8),
          _FinanceSection(game: game),

          const SizedBox(height: 16),

          // ===== FLEET STATS =====
          _sectionTitle('Автопарк'),
          const SizedBox(height: 8),
          _FleetSection(game: game),

          const SizedBox(height: 16),

          // ===== TOP CITIES =====
          _sectionTitle('Филиалы и гаражи'),
          const SizedBox(height: 8),
          _CitiesSection(game: game),

          const SizedBox(height: 16),

          // ===== RECENT ACTIVITY =====
          _sectionTitle('Последние события'),
          const SizedBox(height: 8),
          _RecentActivitySection(game: game),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  int _completedContracts(GameProvider game) {
    return game.myContracts.where((c) => c.status == 'completed').length;
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
  );
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;

  const _SummaryCard({required this.icon, required this.iconColor, required this.label, required this.value, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: iconColor, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(color: Color(0xFF666666), fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

class _FinanceSection extends StatelessWidget {
  final GameProvider game;
  const _FinanceSection({required this.game});

  @override
  Widget build(BuildContext context) {
    final completedContracts = game.myContracts.where((c) => c.status == 'completed');
    final totalIncome = completedContracts.fold<int>(0, (sum, c) => sum + c.reward);

    // Calculate expenses from transactions data — sum of all negative amounts
    // We compute from completed contracts and known costs
    final totalExpenses = game.myTrucks.fold<int>(0, (sum, t) {
      final repairCost = (100 - t.condition) * GameConstants.repairCostPerPoint;
      final refuelCost = ((t.maxFuel - t.fuelLevel) * GameConstants.currentFuelPricePerLiter).round();
      return sum + repairCost + refuelCost;
    });
    final netProfit = totalIncome - totalExpenses;

    // Average €/km from completed contracts
    double avgPerKm = 0;
    if (completedContracts.isNotEmpty) {
      double totalKm = 0;
      int totalReward = 0;
      for (final c in completedContracts) {
        final route = game.findRoute(c.originCityId, c.destinationCityId);
        totalKm += route?.totalDistanceKm ?? 0;
        totalReward += c.reward;
      }
      if (totalKm > 0) avgPerKm = totalReward / totalKm;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Income bar
          _financeRow(AppIcons.income, 'Доходы (контракты)', GameConstants.formatMoney(totalIncome), const Color(0xFF66BB6A)),
          // Expense bar
          _financeRow(AppIcons.expense, 'Расходы (ремонт + топливо)', GameConstants.formatMoney(totalExpenses), const Color(0xFFEF5350)),
          const Divider(height: 16, color: Color(0xFF3A3A3A)),
          // Net profit
          Row(
            children: [
              const Text('Чистая прибыль:', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const Spacer(),
              Text(GameConstants.formatMoney(netProfit),
                style: TextStyle(
                  color: netProfit >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                )),
            ],
          ),
          const SizedBox(height: 8),
          // Average €/km
          Row(
            children: [
              const Text('Средний доход/км:', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const Spacer(),
              Text('€${avgPerKm.toStringAsFixed(1)}',
                style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _financeRow(IconData icon, String label, String value, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 12))),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    ),
  );
}

class _FleetSection extends StatelessWidget {
  final GameProvider game;
  const _FleetSection({required this.game});

  @override
  Widget build(BuildContext context) {
    final trucks = game.myTrucks;
    if (trucks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
        child: const Text('Нет грузовиков', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
      );
    }

    final avgCondition = trucks.isEmpty ? 0.0 : trucks.map((t) => t.condition.toDouble()).reduce((a, b) => a + b) / trucks.length;
    final avgFuel = trucks.isEmpty ? 0.0 : trucks.map((t) => t.fuelLevel / t.maxFuel).reduce((a, b) => a + b) / trucks.length;

    // Trucks by type
    final typeCounts = <String, int>{};
    for (final t in trucks) {
      typeCounts[t.truckType] = (typeCounts[t.truckType] ?? 0) + 1;
    }
    final maxTypeCount = typeCounts.values.fold<int>(0, (a, b) => a > b ? a : b);

    final typeColors = <String, Color>{
      'light': const Color(0xFF42A5F5),
      'medium': const Color(0xFFF5C542),
      'heavy': const Color(0xFFEF5350),
      'special': const Color(0xFFCE93D8),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('Сост.', '${avgCondition.toStringAsFixed(0)}%', avgCondition < 50 ? const Color(0xFFEF5350) : const Color(0xFF66BB6A)),
              _miniStat('Топливо', '${(avgFuel * 100).toStringAsFixed(0)}%', const Color(0xFF42A5F5)),
              _miniStat('Всего', '${trucks.length}', const Color(0xFFF5C542)),
            ],
          ),
          const SizedBox(height: 12),
          // Trucks by type — colored bars
          const Text('По типам:', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
          const SizedBox(height: 6),
          ...typeCounts.entries.map((e) {
            final info = GameConstants.findTruckType(e.key);
            final color = typeColors[e.key] ?? const Color(0xFF888888);
            final fraction = maxTypeCount > 0 ? e.value / maxTypeCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(info?.name ?? e.key, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 11))),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(height: 14, decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(3))),
                        FractionallySizedBox(
                          widthFactor: fraction.clamp(0.05, 1.0),
                          child: Container(height: 14, decoration: BoxDecoration(color: color.withOpacity(0.6), borderRadius: BorderRadius.circular(3))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 24, child: Text('${e.value}', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace'), textAlign: TextAlign.right)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Column(
    children: [
      Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
    ],
  );
}

class _CitiesSection extends StatelessWidget {
  final GameProvider game;
  const _CitiesSection({required this.game});

  @override
  Widget build(BuildContext context) {
    final citiesWithStuff = <int, _CityInfo>{};
    for (final w in game.myWarehouses) {
      citiesWithStuff[w.cityId] = _CityInfo(cityId: w.cityId, hasWarehouse: true, truckCount: 0);
    }
    for (final g in game.myGarages) {
      final existing = citiesWithStuff[g.cityId] ?? _CityInfo(cityId: g.cityId, hasWarehouse: false, truckCount: 0);
      citiesWithStuff[g.cityId] = _CityInfo(cityId: g.cityId, hasWarehouse: existing.hasWarehouse || false, truckCount: existing.truckCount);
    }
    for (final t in game.myTrucks.where((t) => t.isIdle && t.currentCityId != null)) {
      final cityId = t.currentCityId!;
      final existing = citiesWithStuff[cityId] ?? _CityInfo(cityId: cityId, hasWarehouse: false, truckCount: 0);
      citiesWithStuff[cityId] = _CityInfo(cityId: cityId, hasWarehouse: existing.hasWarehouse, truckCount: existing.truckCount + 1);
    }

    if (citiesWithStuff.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
        child: const Text('Нет филиалов или гаражей', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${citiesWithStuff.length} ${citiesWithStuff.length == 1 ? "город" : "города"} в сети',
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 11)),
          const SizedBox(height: 8),
          ...citiesWithStuff.values.map((info) {
            final city = game.getCityById(info.cityId);
            final name = city?.name ?? 'Город #${info.cityId}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  if (info.hasWarehouse)
                    const Icon(AppIcons.warehouses, size: 14, color: Color(0xFF66BB6A))
                  else
                    const Icon(AppIcons.garage, size: 14, color: Color(0xFFFF9800)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12))),
                  if (info.truckCount > 0) ...[
                    const Icon(AppIcons.truck, size: 12, color: Color(0xFFF5C542)),
                    const SizedBox(width: 3),
                    Text('${info.truckCount}', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 11, fontFamily: 'monospace')),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CityInfo {
  final int cityId;
  final bool hasWarehouse;
  final int truckCount;
  const _CityInfo({required this.cityId, required this.hasWarehouse, required this.truckCount});
}

class _RecentActivitySection extends StatelessWidget {
  final GameProvider game;
  const _RecentActivitySection({required this.game});

  @override
  Widget build(BuildContext context) {
    final events = game.eventLog.take(5).toList();
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
        child: const Text('Пока нет событий', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: events.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: e.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(e.icon, size: 13, color: e.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12, fontWeight: FontWeight.w600)),
                    if (e.description.isNotEmpty) Text(e.description, style: const TextStyle(color: Color(0xFF888888), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(e.timeAgo, style: const TextStyle(color: Color(0xFF666666), fontSize: 10)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
