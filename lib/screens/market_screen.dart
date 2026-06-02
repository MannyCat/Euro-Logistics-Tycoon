import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/money_display.dart';

class ShipMarketScreen extends StatefulWidget {
  const ShipMarketScreen({super.key});

  @override
  State<ShipMarketScreen> createState() => _ShipMarketScreenState();
}

class _ShipMarketScreenState extends State<ShipMarketScreen> {
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
      game.loadShipMarket(),
      game.loadMyShips(),
      game.loadMyListings(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final listings = game.shipMarketListings;
    final auth = context.watch<AuthProvider>();
    final userId = auth.profile?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Рынок кораблей'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sell_outlined),
            onPressed: () => _showSellDialog(context, game, auth),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: game.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentBlue,
              ),
            )
          : listings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.store_outlined,
                          size: 48, color: Color(0xFF4A4A6A)),
                      const SizedBox(height: 12),
                      Text('Нет предложений на рынке',
                          style: AppTheme.bodyText),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            _showSellDialog(context, game, auth),
                        child: const Text('Продать свой корабль'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: listings.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    final shipType =
                        GameConstants.findShipType(listing.shipTypeId);
                    final isOwn = listing.sellerId == userId;

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
                                    color: isOwn
                                        ? AppTheme.warningAmber
                                            .withOpacity(0.15)
                                        : AppTheme.accentBlue
                                            .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.directions_boat,
                                    color: isOwn
                                        ? AppTheme.warningAmber
                                        : AppTheme.accentBlue,
                                    size: 20,
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
                                          Text(
                                            listing.shipName,
                                            style:
                                                AppTheme.labelMedium,
                                          ),
                                          if (isOwn) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme
                                                    .warningAmber
                                                    .withOpacity(
                                                        0.15),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(4),
                                              ),
                                              child: Text(
                                                'МОЙ',
                                                style: AppTheme
                                                    .bodyTextSmall
                                                    .copyWith(
                                                  color: AppTheme
                                                      .warningAmber,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        '${shipType?.name ?? listing.shipTypeId}  •  '
                                        'Сост.: ${listing.condition}%',
                                        style:
                                            AppTheme.bodyTextSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFF1E3A5F)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Продавец',
                                        style: AppTheme.bodyTextSmall),
                                    Text(listing.sellerName,
                                        style: AppTheme.bodyText),
                                  ],
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text('Цена',
                                        style: AppTheme.bodyTextSmall),
                                    MoneyDisplay(amount: listing.price),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd.MM HH:mm')
                                      .format(listing.listedAt),
                                  style: AppTheme.bodyTextSmall,
                                ),
                                if (!isOwn)
                                  ElevatedButton(
                                    onPressed: () => _confirmBuy(
                                        context, game, auth,
                                        listing),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8),
                                      textStyle:
                                          const TextStyle(fontSize: 13),
                                    ),
                                    child: const Text('Купить'),
                                  )
                                else
                                  const Text(
                                    'Ваше объявление',
                                    style: AppTheme.bodyTextSmall,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _confirmBuy(
      BuildContext context, GameProvider game, AuthProvider auth,
      ShipMarketListing listing) {
    final shipType = GameConstants.findShipType(listing.shipTypeId);
    final fee = (listing.price * GameConstants.marketFee).ceil();
    final total = listing.price + fee;
    final money = auth.profile?.money ?? 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Подтверждение покупки'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Корабль: ${listing.shipName}',
                  style: AppTheme.bodyText),
              Text(
                  'Тип: ${shipType?.name ?? ''}  •  Сост.: ${listing.condition}%',
                  style: AppTheme.bodyTextSmall),
              Text('Продавец: ${listing.sellerName}',
                  style: AppTheme.bodyTextSmall),
              const Divider(color: Color(0xFF1E3A5F)),
              _BuyRow(label: 'Цена', value: '\$${listing.price}'),
              _BuyRow(label: 'Комиссия 5%', value: '\$$fee'),
              const Divider(color: Color(0xFF1E3A5F)),
              _BuyRow(
                label: 'Итого',
                value: '\$$total',
                isTotal: true,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ваш баланс:',
                      style: AppTheme.bodyTextSmall),
                  MoneyDisplay(amount: money),
                ],
              ),
              if (money < total)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Недостаточно средств!',
                    style: AppTheme.bodyTextSmall.copyWith(
                        color: AppTheme.lossRed),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: money >= total
                  ? () async {
                      Navigator.pop(ctx);
                      await game.buyFromMarket(listing.id);
                      if (context.mounted) {
                        final msg = game.errorMessage ??
                            'Корабль приобретён!';
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
                    }
                  : null,
              child: const Text('Купить'),
            ),
          ],
        );
      },
    );
  }

  void _showSellDialog(
      BuildContext context, GameProvider game, AuthProvider auth) {
    final idleShips = game.myShips
        .where((s) => s.status == 'idle')
        .toList();

    if (idleShips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет свободных кораблей для продажи'),
          backgroundColor: AppTheme.warningAmber,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        String? selectedShipId;

        return AlertDialog(
          title: const Text('Продать корабль'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Выберите корабль:',
                  style: AppTheme.bodyText),
              const SizedBox(height: 12),
              ...idleShips.map((ship) {
                final shipType =
                    GameConstants.findShipType(ship.shipTypeId);
                final condMultiplier = ship.condition / 100.0;
                final basePrice = shipType?.basePrice ?? 0;
                final suggested =
                    (basePrice * condMultiplier * 0.8).round();

                return RadioListTile<String>(
                  value: ship.id,
                  groupValue: selectedShipId,
                  title: Text(ship.name,
                      style: AppTheme.labelMedium),
                  subtitle: Text(
                    '${shipType?.name ?? ''}  •  '
                    'Сост.: ${ship.condition}%  •  '
                    '~\$$suggested',
                    style: AppTheme.bodyTextSmall,
                  ),
                  activeColor: AppTheme.accentBlue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    selectedShipId = value;
                    (ctx as dynamic).setState(() {});
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: selectedShipId != null
                  ? () async {
                      Navigator.pop(ctx);
                      final ship = idleShips.firstWhere(
                          (s) => s.id == selectedShipId);
                      final shipType =
                          GameConstants.findShipType(ship.shipTypeId);
                      final condMultiplier = ship.condition / 100.0;
                      final basePrice = shipType?.basePrice ?? 0;
                      final suggested =
                          (basePrice * condMultiplier * 0.8).round();

                      final priceCtrl =
                          TextEditingController(text: suggested.toString());

                      final price = await showDialog<int>(
                        context: context,
                        builder: (dctx) {
                          return AlertDialog(
                            title: const Text('Установить цену'),
                            content: TextField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Цена (\$)',
                                prefixIcon:
                                    Icon(Icons.attach_money),
                              ),
                              style: AppTheme.monoNumber,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  priceCtrl.dispose();
                                  Navigator.pop(dctx);
                                },
                                child: const Text('Отмена'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final p = int.tryParse(
                                          priceCtrl.text) ??
                                      0;
                                  priceCtrl.dispose();
                                  Navigator.pop(dctx, p);
                                },
                                child: const Text('Продать'),
                              ),
                            ],
                          );
                        },
                      );

                      if (price != null && price > 0) {
                        await game.sellShip(ship.id, price);
                        if (context.mounted) {
                          final msg = game.errorMessage ??
                              'Корабль выставлен на продажу!';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        }
                      }
                    }
                  : null,
              child: const Text('Далее'),
            ),
          ],
        );
      },
    );
  }
}

class _BuyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _BuyRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: isTotal
                  ? AppTheme.labelMedium
                  : AppTheme.bodyText),
          Text(
            value,
            style: isTotal
                ? AppTheme.monoNumberLarge.copyWith(fontSize: 16)
                : AppTheme.monoNumber,
          ),
        ],
      ),
    );
  }
}
