import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/auth_provider.dart';

class Transaction {
  final String id;
  final String type;
  final String description;
  final int amount;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] as String? ?? '',
    type: json['type'] as String? ?? '',
    description: json['description'] as String? ?? '',
    amount: (json['amount'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  bool get isIncome => amount > 0;
  bool get isExpense => amount < 0;

  IconData get typeIcon => switch (type) {
    'contract_completed' => Icons.check_circle,
    'contract_accepted' => Icons.description,
    'truck_purchase' => Icons.local_shipping,
    'driver_hire' => Icons.person_add,
    'refuel' => Icons.local_gas_station,
    'repair' => Icons.build,
    'warehouse' => Icons.warehouse,
    'salary' => Icons.account_balance_wallet,
    _ => Icons.receipt,
  };

  Color get typeColor => switch (type) {
    'contract_completed' => AppTheme.green,
    'truck_purchase' => AppTheme.accent,
    'driver_hire' => AppTheme.accentLight,
    'refuel' => AppTheme.amber,
    'repair' => AppTheme.red,
    'warehouse' => AppTheme.accent,
    _ => AppTheme.textDim,
  };
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  int _totalIncome = 0;
  int _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransactions());
  }

  Future<void> _loadTransactions() async {
    final auth = context.read<AuthProvider>();
    final companyId = auth.companyId;
    if (companyId == null) return;

    setState(() => _isLoading = true);
    try {
      final resp = await Supabase.instance.client
          .from('transactions')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false)
          .limit(100);
      _transactions = resp.map<Transaction>((e) => Transaction.fromJson(e)).toList();

      _totalIncome = 0;
      _totalExpense = 0;
      for (final t in _transactions) {
        if (t.isIncome) _totalIncome += t.amount;
        if (t.isExpense) _totalExpense += t.amount;
      }
    } catch (e) {
      debugPrint('Load transactions error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Финансы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.accent),
            tooltip: 'Обновить',
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : Column(
              children: [
                // Summary card
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _summaryItem('Доход', _totalIncome, AppTheme.green),
                    Container(width: 1, height: 40, color: AppTheme.divider),
                    _summaryItem('Расход', _totalExpense, AppTheme.red),
                    Container(width: 1, height: 40, color: AppTheme.divider),
                    _summaryItem('Баланс', _totalIncome + _totalExpense,
                        (_totalIncome + _totalExpense) >= 0 ? AppTheme.accent : AppTheme.red),
                  ]),
                ),

                const Divider(height: 1, color: AppTheme.divider),

                // Transaction list
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text('Нет транзакций', style: AppTheme.h2),
                              const SizedBox(height: 4),
                              Text('Совершайте операции, чтобы увидеть историю', style: AppTheme.bodySm),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _transactions.length,
                          itemBuilder: (context, i) => _TransactionTile(transaction: _transactions[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _summaryItem(String label, int amount, Color color) => Column(
    children: [
      Text(label, style: AppTheme.bodySm),
      const SizedBox(height: 4),
      Text(
        GameConstants.formatMoney(amount.abs()),
        style: AppTheme.mono.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ],
  );
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: transaction.typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(transaction.typeIcon, color: transaction.typeColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(transaction.description, style: AppTheme.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(_formatDate(transaction.createdAt), style: AppTheme.bodySm),
          ])),
          Text(
            '${isIncome ? '+' : ''}${GameConstants.formatMoney(transaction.amount)}',
            style: AppTheme.mono.copyWith(
              color: isIncome ? AppTheme.green : AppTheme.red,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ]),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return '${diff.inHours}ч назад';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
