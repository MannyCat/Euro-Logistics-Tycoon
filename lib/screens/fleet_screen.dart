import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/money_display.dart';

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  String _statusFilter = 'Все';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().loadMyShips();
    });
  }

  List<Ship> get _filteredShips {
    final game = context.read<GameProvider>();
    if (_statusFilter == 'Все') return game.myShips;
    return game.myShips.where((s) => s.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();
    final ships = _filteredShips;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Флот'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => game.loadMyShips(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBuyShipDialog(context, auth),
        backgroundColor: AppTheme.accentBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Status filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: ['Все', 'idle', 'in_transit', 'in_dock', 'maintenance']
                  .map((status) {
                final label = _statusName(status);
                final isSelected = _statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : AppTheme.textGrayLight,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _statusFilter = status;
                      });
                    },
                    backgroundColor: AppTheme.inputBackground,
                    selectedColor: AppTheme.accentBlue,
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          // Ship count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Корабли: ${ships.length}',
                  style: AppTheme.bodyTextSmall,
                ),
                const Spacer(),
                Text(
                  '${game.myShips.where((s) => s.status == 'idle').length} свободн.  •  '
                  '${game.myShips.where((s) => s.status == 'in_transit').length} в рейсе',
                  style: AppTheme.bodyTextSmall,
                ),
              ],
            ),
          ),
          const Divider(),
          // Ship list
          Expanded(
            child: game.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentBlue,
                    ),
                  )
                : ships.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_boat_outlined,
                                size: 48, color: Color(0xFF4A4A6A)),
                            const SizedBox(height: 12),
                            Text('Нет кораблей', style: AppTheme.bodyText),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () =>
                                  _showBuyShipDialog(context, auth),
                              child: const Text('Купить корабль'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: ships.length,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemBuilder: (context, index) {
                          final ship = ships[index];
                          final shipType =
                              GameConstants.findShipType(ship.shipTypeId);
                          final port = ship.currentPortId != null
                              ? GameConstants.findPort(ship.currentPortId!)
                              : null;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  context.go('/fleet/${ship.id}'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: _shipStatusColor(
                                            ship.status),
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  ship.name,
                                                  style: AppTheme
                                                      .labelMedium,
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _shipStatusColor(
                                                          ship.status)
                                                      .withOpacity(0.15),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(4),
                                                ),
                                                child: Text(
                                                  _statusName(ship.status),
                                                  style: AppTheme
                                                      .bodyTextSmall
                                                      .copyWith(
                                                    color:
                                                        _shipStatusColor(
                                                            ship.status),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${shipType?.name ?? ''}  •  '
                                            'Сост.: ${ship.condition}%  •  '
                                            '${port?.name ?? 'В пути'}',
                                            style: AppTheme
                                                .bodyTextSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF4A4A6A),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _statusName(String status) {
    switch (status) {
      case 'Все':
        return 'Все';
      case 'idle':
        return 'Готов';
      case 'in_transit':
        return 'В рейсе';
      case 'in_dock':
        return 'В доке';
      case 'maintenance':
        return 'Ремонт';
      case 'on_market':
        return 'Продажа';
      default:
        return status;
    }
  }

  Color _shipStatusColor(String status) {
    switch (status) {
      case 'idle':
        return AppTheme.profitGreen;
      case 'in_transit':
        return AppTheme.accentBlue;
      case 'in_dock':
        return AppTheme.warningAmber;
      case 'maintenance':
        return AppTheme.lossRed;
      default:
        return AppTheme.textGray;
    }
  }

  void _showBuyShipDialog(BuildContext context, AuthProvider auth) {
    final money = auth.profile?.money ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
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
                  Row(
                    children: [
                      Text('Купить корабль',
                          style: AppTheme.labelLarge),
                      const Spacer(),
                      MoneyDisplay(amount: money),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount:
                          GameConstants.shipTypes.length,
                      itemBuilder: (context, index) {
                        final st =
                            GameConstants.shipTypes[index];
                        final canAfford = money >= st.basePrice;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(st.name,
                                              style: AppTheme
                                                  .labelMedium),
                                          Text(
                                            '${st.type}  •  ${st.dwt} DWT  •  ${st.teu} TEU',
                                            style: AppTheme
                                                .bodyTextSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    MoneyDisplay(
                                      amount: st.basePrice),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _SpecChip(
                                        '${st.speed} уз.'),
                                    _SpecChip(
                                        '${st.crewSize} чел.'),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Align(
                                        alignment:
                                            Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: canAfford
                                              ? () async {
                                                  final nameCtrl =
                                                      TextEditingController(
                                                          text:
                                                              '${st.name}-${DateTime.now().millisecondsSinceEpoch % 1000}');
                                                  final name =
                                                      await showDialog<
                                                          String>(
                                                    context:
                                                        ctx,
                                                    builder: (dctx) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                            'Название корабля'),
                                                        content:
                                                            TextField(
                                                          controller:
                                                              nameCtrl,
                                                          autofocus:
                                                              true,
                                                          decoration:
                                                              const InputDecoration(
                                                            labelText:
                                                                'Название',
                                                          ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    dctx),
                                                            child: const Text(
                                                                'Отмена'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    dctx,
                                                                    nameCtrl
                                                                        .text),
                                                            child: const Text(
                                                                'Купить'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                  nameCtrl.dispose();
                                                  if (name != null &&
                                                      name
                                                          .trim()
                                                          .isNotEmpty) {
                                                    await context
                                                        .read<
                                                            GameProvider>()
                                                        .buyShip(st
                                                            .id, name);
                                                    if (ctx
                                                        .mounted) {
                                                      Navigator.pop(
                                                          ctx);
                                                    }
                                                  }
                                                }
                                              : null,
                                          style: ElevatedButton
                                              .styleFrom(
                                            minimumSize:
                                                Size.zero,
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal:
                                                        16,
                                                    vertical:
                                                        8),
                                            textStyle:
                                                const TextStyle(
                                                    fontSize:
                                                        13),
                                          ),
                                          child: const Text(
                                              'Купить'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
}

class _SpecChip extends StatelessWidget {
  final String label;
  const _SpecChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.inputBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTheme.monoNumberSmall.copyWith(fontSize: 11),
      ),
    );
  }
}
