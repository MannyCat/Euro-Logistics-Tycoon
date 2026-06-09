import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/market_listing.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  int _selectedTab = 0; // 0=Транспорт, 1=Всё
  bool _isLoading = false;
  List<MarketListing> _listings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() { _isLoading = true; _error = null; });
    final game = context.read<GameProvider>();
    await game.loadMarketListings();
    if (mounted) {
      setState(() {
        _listings = game.marketListings.where((l) => !l.isExpired).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _buyListing(MarketListing listing) async {
    final auth = context.read<AuthProvider>();
    final game = context.read<GameProvider>();
    final companyId = auth.companyId;
    if (companyId == null) return;

    setState(() => _isLoading = true);
    final ok = await game.buyFromMarket(listing.id, companyId);
    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${listing.itemName} куплен на рынке!'),
          backgroundColor: const Color(0xFF66BB6A),
          behavior: SnackBarBehavior.floating,
        ));
        await _loadListings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(game.error ?? 'Ошибка покупки'),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ));
      }
      setState(() => _isLoading = false);
    }
  }

  List<MarketListing> get _filtered {
    if (_selectedTab == 0) return _listings.where((l) => l.listingType == 'truck').toList();
    return _listings;
  }

  @override
  Widget build(BuildContext context) {
    return ETS2Modal(
      title: 'Рынок',
      icon: Icons.store,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF999999), size: 20),
          tooltip: 'Обновить',
          onPressed: _isLoading ? null : _loadListings,
        ),
      ],
      child: Column(
        children: [
          // Tab row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF252525),
            child: Row(
              children: [
                _tabChip('Транспорт', 0),
                const SizedBox(width: 6),
                _tabChip('Всё', 1),
                const Spacer(),
                Text('${_filtered.length} ${_filtered.length == 1 ? "лот" : "лотов"}',
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF3A3A3A)),
          Expanded(
            child: _isLoading && _listings.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5C542)))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.store, size: 48, color: Color(0xFF666666)),
                            const SizedBox(height: 12),
                            Text('Нет предложений', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
                            const SizedBox(height: 4),
                            const Text('Лоты появятся здесь когда игроки выставят грузовики', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) => _ListingCard(
                          listing: _filtered[i],
                          companyId: context.watch<AuthProvider>().companyId ?? '',
                          onBuy: () => _buyListing(_filtered[i]),
                          isLoading: _isLoading,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index) {
    final selected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5C542).withOpacity(0.15) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFFF5C542).withOpacity(0.4) : const Color(0xFF3A3A3A)),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? const Color(0xFFF5C542) : const Color(0xFF888888),
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final MarketListing listing;
  final String companyId;
  final VoidCallback onBuy;
  final bool isLoading;

  const _ListingCard({required this.listing, required this.companyId, required this.onBuy, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final isOwn = listing.sellerId == companyId;
    final game = context.watch<GameProvider>();
    final money = game.company?.money ?? 0;
    final canAfford = money >= listing.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isOwn ? const Color(0xFFF5C542).withOpacity(0.3) : const Color(0xFF3A3A3A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5C542).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_shipping, color: Color(0xFFF5C542), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(listing.itemName, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600)),
                          if (isOwn) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5C542).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Ваш', style: TextStyle(color: Color(0xFFF5C542), fontSize: 9, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${_typeLabel(listing.truckType)}  •  Сост: ${listing.condition}%',
                        style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(GameConstants.formatMoney(listing.price),
                      style: const TextStyle(color: Color(0xFFF5C542), fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 11, color: Color(0xFF888888)),
                        const SizedBox(width: 3),
                        Text(listing.timeLeft, style: TextStyle(
                          color: listing.isExpired ? const Color(0xFFEF5350) : const Color(0xFF888888),
                          fontSize: 10,
                        )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Buy button
            if (!isOwn) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (canAfford && !isLoading) ? onBuy : null,
                  icon: isLoading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFF66BB6A), strokeWidth: 2))
                      : const Icon(Icons.shopping_cart, size: 16),
                  label: Text(canAfford ? 'Купить' : 'Недостаточно средств'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF66BB6A),
                    side: BorderSide(color: canAfford ? const Color(0xFF66BB6A) : const Color(0xFF3A3A3A)),
                    minimumSize: const Size(double.infinity, 34),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(String truckType) {
    switch (truckType) {
      case 'light': return 'Лёгкий';
      case 'medium': return 'Средний';
      case 'heavy': return 'Тяжёлый';
      case 'special': return 'Спец.';
      default: return truckType.isNotEmpty ? truckType : 'Грузовик';
    }
  }
}
