import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/game_provider.dart';
import '../widgets/voyage_progress_bar.dart';

class VoyagesScreen extends StatefulWidget {
  const VoyagesScreen({super.key});

  @override
  State<VoyagesScreen> createState() => _VoyagesScreenState();
}

class _VoyagesScreenState extends State<VoyagesScreen> {
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
      game.loadMyVoyages(),
      game.loadMyShips(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final voyages = game.myVoyages;
    final activeVoyages =
        voyages.where((v) => v.isActive).toList();
    final completedVoyages =
        voyages.where((v) => v.status == 'completed').toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Рейсы'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Активные (${''})'),
              Tab(text: 'История'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Active voyages
            game.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentBlue,
                    ),
                  )
                : activeVoyages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sailing_outlined,
                                size: 48, color: Color(0xFF4A4A6A)),
                            const SizedBox(height: 12),
                            Text('Нет активных рейсов',
                                style: AppTheme.bodyText),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: activeVoyages.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final v = activeVoyages[index];
                          final ship = game.myShips
                              .where((s) => s.id == v.shipId)
                              .firstOrNull;
                          final originPort = GameConstants.findPort(
                              v.originPortId);
                          final destPort = GameConstants.findPort(
                              v.destinationPortId);
                          final good = v.goodId != null
                              ? GameConstants.findGood(v.goodId!)
                              : null;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                          Icons.directions_boat,
                                          color: AppTheme.accentBlue,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ship?.name ?? v.shipId,
                                          style:
                                              AppTheme.labelMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          originPort?.name ?? '?',
                                          style: AppTheme.labelSmall,
                                          textAlign:
                                              TextAlign.center,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets
                                            .symmetric(horizontal: 8),
                                        child: Icon(
                                            Icons.arrow_forward,
                                            color: AppTheme.textGray,
                                            size: 16),
                                      ),
                                      Expanded(
                                        child: Text(
                                          destPort?.name ?? '?',
                                          style: AppTheme.labelSmall,
                                          textAlign:
                                              TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  VoyageProgressBar(
                                    progress: v.progress,
                                    etaText: v.eta != null
                                        ? 'ETA: ${DateFormat('dd.MM HH:mm').format(v.eta!)}'
                                        : null,
                                  ),
                                  if (good != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text('Груз: ',
                                            style:
                                                AppTheme.bodyTextSmall),
                                        Text(
                                            '${good.name} × ${v.quantity}',
                                            style:
                                                AppTheme.monoNumberSmall),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'Расстояние: ${v.distance.toStringAsFixed(0)} м.миль  •  '
                                    '~${v.estimatedHours.toStringAsFixed(1)} ч.',
                                    style: AppTheme.bodyTextSmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

            // History
            completedVoyages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history,
                            size: 48, color: Color(0xFF4A4A6A)),
                        const SizedBox(height: 12),
                        Text('Нет завершённых рейсов',
                            style: AppTheme.bodyText),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: completedVoyages.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final v = completedVoyages[index];
                      final ship = game.myShips
                          .where((s) => s.id == v.shipId)
                          .firstOrNull;
                      final originPort = GameConstants.findPort(
                          v.originPortId);
                      final destPort = GameConstants.findPort(
                          v.destinationPortId);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        ship?.name ?? v.shipId,
                                        style:
                                            AppTheme.labelMedium),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${originPort?.name ?? '?'} → ${destPort?.name ?? '?'}',
                                      style: AppTheme.bodyTextSmall,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    DateFormat('dd.MM').format(
                                        v.startedAt),
                                    style: AppTheme.bodyTextSmall,
                                  ),
                                  if (v.revenue != null)
                                    Text(
                                      v.revenue! >= 0
                                          ? '+\$${v.revenue}'
                                          : '-\$${v.revenue!.abs()}',
                                      style: AppTheme.monoNumberSmall
                                          .copyWith(
                                        color: v.revenue! >= 0
                                            ? AppTheme.profitGreen
                                            : AppTheme.lossRed,
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
          ],
        ),
      ),
    );
  }
}
