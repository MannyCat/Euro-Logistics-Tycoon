import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  bool _hasError = false;
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
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final resp = await Supabase.instance.client.from('transactions').select().eq('company_id', companyId).order('created_at', ascending: false).limit(100);
      _transactions = resp.map<Transaction>((e) => Transaction.fromJson(e)).toList();
      _totalIncome = 0; _totalExpense = 0;
      for (final t in _transactions) {
        if (t.isIncome) _totalIncome += t.amount;
        else _totalExpense += t.amount;
      }
    } catch (e) {
      debugPrint('Load transactions error: $e');
      setState(() => _hasError = true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    return ETS2Modal(
      title: 'Финансы',
      icon: Icons.receipt_long,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF999999), size: 18),
          tooltip: 'Обновить',
          onPressed: _loadTransactions,
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5C542)))
          : Column(
              children: [
                // Summary
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _summaryItem('Доход', _totalIncome, const Color(0xFF66BB6A)),
                    Container(width: 1, height: 36, color: const Color(0xFF3A3A3A)),
                    _summaryItem('Расход', _totalExpense, const Color(0xFFEF5350)),
                    Container(width: 1, height: 36, color: const Color(0xFF3A3A3A)),
                    Column(
                      children: [
                        const Text('Баланс', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(GameConstants.formatMoney(game.company?.money ?? 0), style: TextStyle(color: (game.company?.money ?? 0) >= 0 ? const Color(0xFF42A5F5) : const Color(0xFFEF5350), fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace')),
                      ],
                    ),
                  ]),
                ),
                const Divider(height: 1, color: Color(0xFF3A3A3A)),
                Expanded(
                  child: _hasError
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off, size: 48, color: Color(0xFFEF5350)),
                              const SizedBox(height: 12),
                              Text('Ошибка загрузки', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
                              const SizedBox(height: 4),
                              const Text('Проверьте подключение и попробуйте снова', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadTransactions,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Повторить'),
                              ),
                            ],
                          ),
                        )
                      : _transactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.receipt_long_outlined, size: 48, color: Color(0xFF666666)),
                                  const SizedBox(height: 12),
                                  Text('Нет транзакций', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
                                  const SizedBox(height: 4),
                                  const Text('Совершайте операции, чтобы увидеть историю', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
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
      Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
      const SizedBox(height: 4),
      Text(GameConstants.formatMoney(amount.abs()), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace')),
    ],
  );
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
      child: Row(
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: transaction.typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(transaction.typeIcon, color: transaction.typeColor, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_formatDate(transaction.createdAt), style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
              ],
            ),
          ),
          Text('${transaction.isIncome ? '+' : ''}${GameConstants.formatMoney(transaction.amount)}', style: TextStyle(color: transaction.isIncome ? const Color(0xFF66BB6A) : const Color(0xFFEF5350), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return '${diff.inHours}ч назад';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
