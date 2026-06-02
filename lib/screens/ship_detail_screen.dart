import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/money_display.dart';
import '../widgets/voyage_progress_bar.dart';

class ShipDetailScreen extends StatefulWidget {
  final String shipId;

  const ShipDetailScreen({super.key, required this.shipId});

  @override
  State<ShipDetailScreen> createState() => _ShipDetailScreenState();
}

class _ShipDetailScreenState extends State<ShipDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final game = context.read<GameProvider>();
    await Future.wait([
      game.loadMyShips(),
      game.loadMyVoyages(),
    ]);
  }

  Ship? _findShip() {
    final game = context.read<GameProvider>();
    try {
      return game.myShips.firstWhere((s) => s.id == widget.shipId);
    } catch (_) {
      return null;
    }
  }

  Voyage? _findActiveVoyage() {
    final game = context.read<GameProvider>();
    try {
      return game.myVoyages.firstWhere(
        (v) => v.shipId == widget.shipId && v.status == 'active',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ship = _findShip();
    final voyage = _findActiveVoyage();

    if (ship == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Корабль')),
        body: const Center(
          child: Text('Корабль не найден', style: AppTheme.bodyText),
        ),
      );
    }

    final shipType = GameConstants.findShipType(ship.shipTypeId);
    final fuelPercent =
        ship.maxFuel > 0 ? (ship.fuelLevel / ship.maxFuel * 100) : 0;
    final port = ship.currentPortId != null
        ? GameConstants.findPort(ship.currentPortId!)
        : null;
    final destPort = ship.destinationPortId != null
        ? GameConstants.findPort(ship.destinationPortId!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(ship.name),
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
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Ship info card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_boat,
                          color: AppTheme.accentBlue,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(ship.name,
                                  style: AppTheme.labelLarge),
                              Text(
                                '${shipType?.name ?? ''}  •  ${shipType?.type ?? ''}',
                                style: AppTheme.bodyText,
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: ship.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF1E3A5F)),
                    const SizedBox(height: 12),
                    if (shipType != null) ...[
                      _DetailRow(
                          label: 'Водоизмещение',
                          value: '${shipType.dwt} DWT'),
                      _DetailRow(
                          label: 'Контейнеровместимость',
                          value: '${shipType.teu} TEU'),
                      _DetailRow(
                          label: 'Скорость',
                          value: '${shipType.speed} уз.'),
                      _DetailRow(
                          label: 'Расход топлива',
                          value:
                              '${shipType.fuelPerNm.toStringAsFixed(1)} л/м.милю'),
                      _DetailRow(
                          label: 'Экипаж',
                          value: '${shipType.crewSize} чел.'),
                    ],
                    const Divider(color: Color(0xFF1E3A5F)),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Состояние',
                      value: '${ship.condition}%',
                      valueColor: ship.condition > 60
                          ? AppTheme.profitGreen
                          : ship.condition > 30
                              ? AppTheme.warningAmber
                              : AppTheme.lossRed,
                    ),
                    _DetailRow(
                      label: 'Топливо',
                      value: '${fuelPercent.toStringAsFixed(0)}%',
                      subtitle:
                          '${ship.fuelLevel.toStringAsFixed(0)} / ${ship.maxFuel.toStringAsFixed(0)} л.',
                    ),
                    _DetailRow(
                      label: 'Порт',
                      value: port?.name ?? 'В пути',
                    ),
                    if (destPort != null)
                      _DetailRow(
                        label: 'Пункт назначения',
                        value: destPort.name,
                      ),
                  ],
                ),
              ),
            ),

            // Active voyage card
            if (voyage != null) ...[
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Текущий рейс', style: AppTheme.labelMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.circle,
                                    size: 10,
                                    color: AppTheme.accentBlue),
                                const SizedBox(height: 4),
                                Text(
                                  GameConstants
                                          .findPort(voyage
                                              .originPortId)
                                          ?.name ??
                                      voyage.originPortId,
                                  style: AppTheme.labelSmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8),
                            child: Icon(Icons.arrow_forward,
                                color: AppTheme.textGray),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on,
                                    size: 10,
                                    color: AppTheme
                                        .profitGreen),
                                const SizedBox(height: 4),
                                Text(
                                  GameConstants
                                          .findPort(voyage
                                              .destinationPortId)
                                          ?.name ??
                                      voyage.destinationPortId,
                                  style: AppTheme.labelSmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      VoyageProgressBar(
                        progress: voyage.progress,
                        etaText: voyage.eta != null
                            ? 'ETA: ${_formatDateTime(voyage.eta!)}'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(
                        label: 'Расстояние',
                        value:
                            '${voyage.distance.toStringAsFixed(0)} м.миль'),
                      _DetailRow(
                        label: 'Время в пути',
                        value:
                            '${voyage.estimatedHours.toStringAsFixed(1)} ч.'),
                      if (voyage.goodId != null)
                        _DetailRow(
                          label: 'Груз',
                          value:
                              '${GameConstants.findGood(voyage.goodId!)?.name ?? ''} × ${voyage.quantity}',
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Actions card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Действия', style: AppTheme.labelMedium),
                    const SizedBox(height: 12),
                    if (ship.status == 'idle')
                      _ActionButton(
                        icon: Icons.route,
                        label: 'Назначить рейс',
                        color: AppTheme.accentBlue,
                        onTap: () => _showAssignVoyageDialog(
                            context, ship),
                      ),
                    if (port != null && port.hasFuel && ship.status == 'idle')
                      _ActionButton(
                        icon: Icons.local_gas_station,
                        label: 'Заправить',
                        color: AppTheme.profitGreen,
                        onTap: () async {
                          final game = context.read<GameProvider>();
                          final needed = ship.maxFuel - ship.fuelLevel;
                          if (needed > 0) {
                            await game.buyFuel(
                                port.id, ship.id, needed);
                          }
                        },
                      ),
                    if (ship.condition < 100 && ship.status == 'idle')
                      _ActionButton(
                        icon: Icons.build,
                        label: 'Ремонтировать',
                        color: AppTheme.warningAmber,
                        onTap: () => _showRepairDialog(context, ship),
                      ),
                    if (ship.status != 'in_transit')
                      _ActionButton(
                        icon: Icons.sell,
                        label: 'Продать корабль',
                        color: AppTheme.lossRed,
                        onTap: () =>
                            _showSellDialog(context, ship),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showAssignVoyageDialog(BuildContext context, Ship ship) {
    final ports = GameConstants.ports
        .where((p) => p.id != ship.currentPortId)
        .toList();
    String? selectedPortId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            AppTheme.accentBlue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Назначить рейс', style: AppTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Из: ${GameConstants.findPort(ship.currentPortId ?? '')?.name ?? '?'}',
                    style: AppTheme.bodyText,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: ports.length,
                      itemBuilder: (context, index) {
                        final port = ports[index];
                        return ListTile(
                          title: Text(port.name),
                          subtitle: Text(
                            '${port.country}  •  ${port.region}',
                            style: AppTheme.bodyTextSmall,
                          ),
                          onTap: () {
                            selectedPortId = port.id;
                            Navigator.pop(ctx);
                            _confirmVoyage(
                                context, ship, port.id);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmVoyage(
      BuildContext context, Ship ship, String destPortId) {
    final shipType = GameConstants.findShipType(ship.shipTypeId);
    final originPort =
        GameConstants.findPort(ship.currentPortId ?? '');
    final destPort = GameConstants.findPort(destPortId);

    if (shipType == null || originPort == null || destPort == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Подтверждение рейса'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Корабль: ${ship.name}',
                  style: AppTheme.bodyText),
              Text('Маршрут: ${originPort.name} → ${destPort.name}',
                  style: AppTheme.bodyText),
              Text(
                  'Расход топлива: ~${_estimateFuel(ship, originPort, destPort, shipType).toStringAsFixed(0)} л.',
                  style: AppTheme.bodyText),
              const SizedBox(height: 12),
              Text(
                  'У вас ${ship.fuelLevel.toStringAsFixed(0)} л. топлива',
                  style: AppTheme.bodyTextSmall),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final game = context.read<GameProvider>();
                await game.startVoyage(
                    ship.id, destPortId, null, 0);
                if (context.mounted) {
                  final msg = game.errorMessage ??
                      'Рейс назначен!';
                  final color = game.errorMessage != null
                      ? AppTheme.lossRed
                      : AppTheme.profitGreen;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: color,
                    ),
                  );
                }
              },
              child: const Text('Отплыть'),
            ),
          ],
        );
      },
    );
  }

  double _estimateFuel(Ship ship, PortDefinition origin, PortDefinition dest,
      ShipTypeDefinition shipType) {
    // Simplified distance
    const R = 6371.0;
    final dLat = (dest.latitude - origin.latitude) * 0.017453292519943295;
    final dLon = (dest.longitude - origin.longitude) * 0.017453292519943295;
    final a = 1 * 1 +
        1 * 1 * (dLon / 2) * (dLon / 2);
    final c = 2 * (dLon / (2 * (1 + 1)));
    final distance = R * (dLat.abs() + dLon.abs()) * 1.5;
    return distance * shipType.fuelPerNm;
  }

  void _showRepairDialog(BuildContext context, Ship ship) {
    final repairPoints = 100 - ship.condition;
    final cost = repairPoints * GameConstants.repairCostPerPoint;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Ремонт'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Текущее состояние: ${ship.condition}%',
                  style: AppTheme.bodyText),
              Text('Восстановление до 100%',
                  style: AppTheme.bodyText),
              const SizedBox(height: 8),
              MoneyDisplay(amount: -cost.round(), fontSize: 18),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                // Repair logic would deduct money and update condition
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ремонт начат. Стоимость: \$$cost'),
                    backgroundColor: AppTheme.accentBlue,
                  ),
                );
              },
              child: const Text('Ремонтировать'),
            ),
          ],
        );
      },
    );
  }

  void _showSellDialog(BuildContext context, Ship ship) {
    final shipType = GameConstants.findShipType(ship.shipTypeId);
    final basePrice = shipType?.basePrice ?? 0;
    final condMultiplier = ship.condition / 100.0;
    final suggestedPrice = (basePrice * condMultiplier * 0.8).round();

    final priceController =
        TextEditingController(text: suggestedPrice.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Продать корабль'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Корабль: ${ship.name}', style: AppTheme.bodyText),
              Text(
                  'Тип: ${shipType?.name ?? ''}  •  Сост.: ${ship.condition}%',
                  style: AppTheme.bodyTextSmall),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType:
                    TextInputType.numberWithOptions(signed: false),
                decoration: const InputDecoration(
                  labelText: 'Цена (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                style: AppTheme.monoNumber,
              ),
              const SizedBox(height: 4),
              Text(
                'Комиссия: ${GameConstants.marketFee * 100}% от цены',
                style: AppTheme.bodyTextSmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                priceController.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final price = int.tryParse(priceController.text) ?? 0;
                priceController.dispose();
                if (price > 0) {
                  final game = context.read<GameProvider>();
                  await game.sellShip(ship.id, price);
                  if (context.mounted) {
                    final msg = game.errorMessage ??
                        'Корабль выставлен на продажу';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                }
              },
              child: const Text('Выставить'),
            ),
          ],
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'idle':
        color = AppTheme.profitGreen;
        label = 'Готов';
        break;
      case 'in_transit':
        color = AppTheme.accentBlue;
        label = 'В рейсе';
        break;
      case 'in_dock':
        color = AppTheme.warningAmber;
        label = 'В доке';
        break;
      case 'maintenance':
        color = AppTheme.lossRed;
        label = 'Ремонт';
        break;
      default:
        color = AppTheme.textGray;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: AppTheme.labelSmall.copyWith(color: color, fontSize: 11)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: AppTheme.bodyText),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTheme.monoNumber.copyWith(
                  color: valueColor ?? AppTheme.textWhite,
                  fontSize: 13,
                ),
              ),
              if (subtitle != null)
                Text(subtitle!, style: AppTheme.bodyTextSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Text(label,
                  style: AppTheme.labelMedium.copyWith(color: color)),
              const Spacer(),
              Icon(Icons.chevron_right, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
