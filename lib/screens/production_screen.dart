import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/money_display.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final game = context.read<GameProvider>();
    await game.loadFactories();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final factories = game.factories;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Производство'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBuildFactoryDialog(context, auth, game),
        backgroundColor: AppTheme.accentBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: game.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentBlue,
              ),
            )
          : factories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.factory_outlined,
                          size: 48, color: Color(0xFF4A4A6A)),
                      const SizedBox(height: 12),
                      Text('Нет фабрик',
                          style: AppTheme.bodyText),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _showBuildFactoryDialog(
                            context, auth, game),
                        child: const Text('Построить фабрику'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: factories.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final factory = factories[index];
                    final port = factory.portId != null
                        ? GameConstants.findPort(factory.portId!)
                        : null;
                    final inputGood = factory.inputGoodId != null
                        ? GameConstants.findGood(factory.inputGoodId!)
                        : null;
                    final outputGood = factory.outputGoodId != null
                        ? GameConstants.findGood(factory.outputGoodId!)
                        : null;

                    Color statusColor;
                    String statusLabel;
                    switch (factory.status) {
                      case 'active':
                        statusColor = AppTheme.profitGreen;
                        statusLabel = 'Работает';
                        break;
                      case 'building':
                        statusColor = AppTheme.warningAmber;
                        statusLabel = 'Строится';
                        break;
                      case 'idle':
                        statusColor = AppTheme.textGray;
                        statusLabel = 'Простой';
                        break;
                      default:
                        statusColor = AppTheme.textGray;
                        statusLabel = factory.status;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.factory,
                                      color: statusColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _factoryTypeLabel(
                                                factory.type),
                                            style: AppTheme
                                                .labelMedium,
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusColor
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(4),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: AppTheme
                                                  .bodyTextSmall
                                                  .copyWith(
                                                color: statusColor,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (port != null)
                                        Text(
                                          port.name,
                                          style: AppTheme
                                              .bodyTextSmall,
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text('Ур. ${factory.level}',
                                        style:
                                            AppTheme.monoNumberSmall),
                                    Text(
                                      DateFormat('dd.MM.yyyy')
                                          .format(factory.createdAt),
                                      style: AppTheme
                                          .bodyTextSmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (inputGood != null || outputGood != null) ...[
                              const Divider(
                                  color: Color(0xFF1E3A5F)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (inputGood != null) ...[
                                    Icon(Icons.arrow_downward,
                                        color: AppTheme.lossRed,
                                        size: 14),
                                    const SizedBox(width: 4),
                                    Text(inputGood.name,
                                        style: AppTheme
                                            .bodyTextSmall),
                                  ],
                                  if (inputGood != null &&
                                      outputGood != null) ...[
                                    Padding(
                                      padding: const EdgeInsets
                                          .symmetric(
                                              horizontal: 8),
                                      child: Icon(Icons
                                          .arrow_forward,
                                          color: AppTheme
                                              .textGray,
                                          size: 14),
                                    ),
                                  ],
                                  if (outputGood != null) ...[
                                    Icon(Icons.arrow_upward,
                                        color: AppTheme.profitGreen,
                                        size: 14),
                                    const SizedBox(width: 4),
                                    Text(outputGood.name,
                                        style: AppTheme
                                            .bodyTextSmall),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _factoryTypeLabel(String type) {
    switch (type) {
      case 'refinery':
        return 'Нефтепереработка';
      case 'steel_mill':
        return 'Металлургия';
      case 'food_processing':
        return 'Пищевая';
      case 'textile_mill':
        return 'Текстильная';
      case 'electronics_factory':
        return 'Электроника';
      case 'chemical_plant':
        return 'Химическая';
      case 'lumber_mill':
        return 'Лесопилка';
      default:
        return type;
    }
  }

  void _showBuildFactoryDialog(
      BuildContext context, AuthProvider auth, GameProvider game) {
    final factoryTypes = [
      {'id': 'refinery', 'name': 'Нефтепереработка', 'cost': 300000},
      {'id': 'steel_mill', 'name': 'Металлургия', 'cost': 250000},
      {'id': 'food_processing', 'name': 'Пищевая', 'cost': 150000},
      {'id': 'textile_mill', 'name': 'Текстильная', 'cost': 180000},
      {'id': 'electronics_factory', 'name': 'Электроника', 'cost': 400000},
      {'id': 'chemical_plant', 'name': 'Химическая', 'cost': 350000},
      {'id': 'lumber_mill', 'name': 'Лесопилка', 'cost': 120000},
    ];
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
                  Row(
                    children: [
                      Text('Построить фабрику',
                          style: AppTheme.labelLarge),
                      const Spacer(),
                      MoneyDisplay(amount: money),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: factoryTypes.length,
                      itemBuilder: (context, index) {
                        final ft = factoryTypes[index];
                        final cost = ft['cost'] as int;
                        final canAfford = money >= cost;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: canAfford
                                        ? AppTheme.accentBlue
                                            .withOpacity(0.1)
                                        : AppTheme.lossRed
                                            .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.factory,
                                    color: canAfford
                                        ? AppTheme.accentBlue
                                        : AppTheme.lossRed,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(ft['name'] as String,
                                          style: AppTheme
                                              .labelMedium),
                                      Text(
                                          'Стоимость: \$$cost',
                                          style: AppTheme
                                              .bodyTextSmall),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: canAfford
                                      ? () {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(
                                                  context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Фабрика «${ft['name']}» — строительство начато!'),
                                              backgroundColor:
                                                  AppTheme
                                                      .profitGreen,
                                            ),
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                            horizontal: 16,
                                            vertical: 8),
                                    textStyle:
                                        const TextStyle(fontSize: 13),
                                  ),
                                  child: const Text(
                                      'Построить'),
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
