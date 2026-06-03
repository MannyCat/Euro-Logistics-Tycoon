import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/money_display.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final game = context.read<GameProvider>();
    await game.loadDashboard();
    final auth = context.read<AuthProvider>();
    await auth.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final profile = auth.profile;
    final dash = game.dashboardData;

    return RefreshIndicator(
      color: AppTheme.accentBlue,
      backgroundColor: AppTheme.cardBackground,
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // App bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.companyName ?? 'Загрузка...',
                          style: AppTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ур. ${profile?.level ?? 0}  •  Репутация: ${profile?.reputation ?? 0}',
                          style: AppTheme.bodyTextSmall,
                        ),
                      ],
                    ),
                  ),
                  if (profile != null)
                    MoneyDisplay(
                      amount: profile.money,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Stats cards
          if (dash != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.4,
                ),
                delegate: SliverChildListDelegate([
                  _StatCard(
                    label: 'Корабли',
                    value: '${dash.activeShips}',
                    subtitle: '${dash.idleShips} свободн.',
                    icon: Icons.directions_boat,
                    iconColor: AppTheme.accentBlue,
                  ),
                  _StatCard(
                    label: 'В рейсе',
                    value: '${dash.inTransitShips}',
                    subtitle: 'в пути',
                    icon: Icons.route,
                    iconColor: AppTheme.warningAmber,
                  ),
                  _StatCard(
                    label: 'Рейсы',
                    value: '${dash.activeVoyages}',
                    subtitle: 'активных',
                    icon: Icons.sailing,
                    iconColor: AppTheme.profitGreen,
                  ),
                  _StatCard(
                    label: 'Прибыль',
                    value: dash.totalProfit >= 0 ? '+' : '',
                    valueSuffix: '\$${NumberFormat.compact().format(dash.totalProfit.abs())}',
                    subtitle: 'всего',
                    icon: dash.totalProfit >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    iconColor: dash.totalProfit >= 0
                        ? AppTheme.profitGreen
                        : AppTheme.lossRed,
                  ),
                ]),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Быстрые действия', style: AppTheme.labelMedium),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _QuickAction(
                    icon: Icons.route,
                    label: 'Назначить\nрейс',
                    onTap: () => context.go('/fleet'),
                  ),
                  _QuickAction(
                    icon: Icons.add_shopping_cart,
                    label: 'Купить\nкорабль',
                    onTap: () => context.go('/fleet'),
                  ),
                  _QuickAction(
                    icon: Icons.store,
                    label: 'Рынок\nкораблей',
                    onTap: () => context.go('/market'),
                  ),
                  _QuickAction(
                    icon: Icons.account_balance,
                    label: 'Финансы',
                    onTap: () => context.go('/finance'),
                  ),
                  _QuickAction(
                    icon: Icons.people,
                    label: 'Персонал',
                    onTap: () => context.go('/personnel'),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Recent transactions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Последние операции', style: AppTheme.labelMedium),
                  TextButton(
                    onPressed: () => context.go('/finance'),
                    child: Text(
                      'Все',
                      style: AppTheme.bodyTextSmall.copyWith(
                        color: AppTheme.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          if (dash != null && dash.recentTransactions.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 40, color: Color(0xFF4A4A6A)),
                      SizedBox(height: 8),
                      Text('Нет операций',
                          style: TextStyle(color: Color(0xFF9E9E9E))),
                    ],
                  ),
                ),
              ),
            )
          else if (dash != null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tx = dash.recentTransactions[index];
                  return _TransactionTile(transaction: tx);
                },
                childCount: dash.recentTransactions.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String valueSuffix;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.valueSuffix = '',
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: AppTheme.labelSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$value$valueSuffix',
              style: AppTheme.monoNumberLarge.copyWith(
                fontSize: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTheme.bodyTextSmall),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppTheme.accentBlue, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyTextSmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    // Handle both Transaction model and Map
    final String description;
    final int amount;
    final DateTime createdAt;

    if (transaction is Map) {
      description = transaction['description'] as String? ?? '';
      amount = (transaction['amount'] as num?)?.toInt() ?? 0;
      createdAt = DateTime.tryParse(transaction['created_at'] as String? ?? '') ??
          DateTime.now();
    } else {
      description = transaction.description;
      amount = transaction.amount;
      createdAt = transaction.createdAt;
    }

    final formatter = DateFormat('dd.MM HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: AppTheme.bodyText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatter.format(createdAt),
                    style: AppTheme.bodyTextSmall,
                  ),
                ],
              ),
            ),
            MoneyDisplay(amount: amount),
          ],
        ),
      ),
    );
  }
}
