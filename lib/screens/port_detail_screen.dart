import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/money_display.dart';

class PortDetailScreen extends StatefulWidget {
  final String portId;

  const PortDetailScreen({super.key, required this.portId});

  @override
  State<PortDetailScreen> createState() => _PortDetailScreenState();
}

class _PortDetailScreenState extends State<PortDetailScreen> {
  bool _isLoadingPrices = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final game = context.read<GameProvider>();
    setState(() => _isLoadingPrices = true);
    await game.loadMarketPrices(widget.portId);
    if (mounted) setState(() => _isLoadingPrices = false);
  }

  @override
  Widget build(BuildContext context) {
    final port = GameConstants.findPort(widget.portId);
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();

    if (port == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Порт')),
        body: Center(
          child: Text('Порт не найден', style: AppTheme.bodyText),
        ),
      );
    }

    final shipsInPort = game.getShipsInPort(port.id);
    final prices = game.currentPortPrices;

    return Scaffold(
      appBar: AppBar(
        title: Text(port.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.accentBlue,
        backgroundColor: AppTheme.cardBackground,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Port info
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: AppTheme.accentBlue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(port.name,
                                    style: AppTheme.labelLarge),
                                Text(
                                  '${port.country}  •  ${port.region}',
                                  style: AppTheme.bodyText,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFF1E3A5F)),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Координаты',
                        value:
                            '${port.latitude.toStringAsFixed(2)}°, ${port.longitude.toStringAsFixed(2)}°',
                      ),
                      _InfoRow(
                        label: 'Налог',
                        value: '${(port.taxRate * 100).toStringAsFixed(1)}%',
                      ),
                      _InfoRow(
                        label: 'Топливо',
                        value: port.hasFuel ? 'Доступно' : 'Нет',
                        valueColor: port.hasFuel
                            ? AppTheme.profitGreen
                            : AppTheme.lossRed,
                      ),
                      _InfoRow(
                        label: 'Док / ремонт',
                        value: port.hasDock ? 'Доступен' : 'Нет',
                        valueColor: port.hasDock
                            ? AppTheme.profitGreen
                            : AppTheme.lossRed,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Market prices
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('Рынок', style: AppTheme.labelMedium),
                    const Spacer(),
                    if (port.hasFuel)
                      OutlinedButton.icon(
                        onPressed: () => _showFuelDialog(context, auth),
                        icon: const Icon(Icons.local_gas_station, size: 16),
                        label: const Text('Заправка'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            if (_isLoadingPrices)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ),
              )
            else if (prices.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.store_outlined,
                            size: 40, color: Color(0xFF4A4A6A)),
                        SizedBox(height: 8),
                        Text('Нет данных о ценах',
                            style: TextStyle(color: Color(0xFF9E9E9E))),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D1B30),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text('Товар',
                                    style: AppTheme.bodyTextSmall)),
                            Expanded(
                                flex: 2,
                                child: Text('Покупка',
                                    style: AppTheme.bodyTextSmall,
                                    textAlign: TextAlign.right)),
                            Expanded(
                                flex: 2,
                                child: Text('Продажа',
                                    style: AppTheme.bodyTextSmall,
                                    textAlign: TextAlign.right)),
                            Expanded(
                                flex: 2,
                                child: Text('Наличие',
                                    style: AppTheme.bodyTextSmall,
                                    textAlign: TextAlign.right)),
                          ],
                        ),
                      ),
                      // Table rows
                      ...prices.map((pp) {
                        final good = GameConstants.findGood(pp.goodId);
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  good?.name ?? pp.goodId,
                                  style: AppTheme.bodyText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '\$${pp.buyPrice}',
                                  style: AppTheme.monoNumberSmall,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '\$${pp.sellPrice}',
                                  style: AppTheme.monoNumberSmall.copyWith(
                                    color: AppTheme.profitGreen,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${pp.available}',
                                  style: AppTheme.monoNumberSmall,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

            // Ships in port
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Мои корабли в порту',
                    style: AppTheme.labelMedium),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            if (shipsInPort.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Нет свободных кораблей',
                      style: AppTheme.bodyText,
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ship = shipsInPort[index];
                    final shipType =
                        GameConstants.findShipType(ship.shipTypeId);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 2),
                        title: Text(ship.name,
                            style: AppTheme.labelMedium),
                        subtitle: Text(
                          '${shipType?.name ?? ''}  •  Сост.: ${ship.condition}%',
                          style: AppTheme.bodyTextSmall,
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => context.go('/fleet/${ship.id}'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: const Text('Рейс'),
                        ),
                      ),
                    );
                  },
                  childCount: shipsInPort.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  void _showFuelDialog(BuildContext context, AuthProvider auth) {
    final game = context.read<GameProvider>();
    final shipsInPort = game.getShipsInPort(widget.portId);
    if (shipsInPort.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Заправка'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Выберите корабль для заправки',
                  style: AppTheme.bodyText),
              const SizedBox(height: 12),
              ...shipsInPort.map((ship) {
                final shipType =
                    GameConstants.findShipType(ship.shipTypeId);
                final needed = ship.maxFuel - ship.fuelLevel;
                final cost =
                    (needed * GameConstants.fuelPricePerLiter).ceil();
                return ListTile(
                  title: Text(ship.name),
                  subtitle: Text(
                    '${shipType?.name ?? ''}  •  '
                    'Бак: ${ship.fuelLevel.toStringAsFixed(0)}/${ship.maxFuel.toStringAsFixed(0)} л.  •  '
                    'Стоимость: \$$cost',
                    style: AppTheme.bodyTextSmall,
                  ),
                  trailing: needed > 0
                      ? ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await game.buyFuel(
                                widget.portId, ship.id, needed);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Заправлено ${needed.toStringAsFixed(0)} л.'),
                                  backgroundColor: AppTheme.profitGreen,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: Text('\$$cost'),
                        )
                      : const Text(
                          'Полон',
                          style: AppTheme.bodyTextSmall,
                        ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyText),
          Text(
            value,
            style: AppTheme.monoNumber.copyWith(
              color: valueColor ?? AppTheme.textWhite,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
