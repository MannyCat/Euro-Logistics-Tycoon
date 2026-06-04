import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/money_display.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final game = context.read<GameProvider>();
    final auth = context.read<AuthProvider>();
    await Future.wait([
      game.loadTransactions(),
      game.loadLoans(),
      auth.loadProfile(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final profile = auth.profile;
    final transactions = game.transactions;
    final loans = game.loans;

    int totalIncome = 0;
    int totalExpense = 0;
    for (final t in transactions) {
      if (t.amount > 0) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount.abs();
      }
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Финансы'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Обзор'),
              Tab(text: 'Кредиты'),
              Tab(text: 'Операции'),
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
            // Overview tab
            ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Balance card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Баланс компании',
                            style: AppTheme.bodyTextSmall),
                        const SizedBox(height: 8),
                        if (profile != null)
                          MoneyDisplay(
                            amount: profile.money,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                      ],
                    ),
                  ),
                ),

                // Income/Expense cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_upward,
                                        color: AppTheme.profitGreen,
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Text('Доходы',
                                        style: AppTheme.bodyTextSmall),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                MoneyDisplay(
                                    amount: totalIncome,
                                    fontSize: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_downward,
                                        color: AppTheme.lossRed,
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Text('Расходы',
                                        style: AppTheme.bodyTextSmall),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                MoneyDisplay(
                                    amount: -totalExpense,
                                    fontSize: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Take loan button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showLoanDialog(context, auth, game),
                    icon: const Icon(Icons.account_balance),
                    label: const Text('Взять кредит'),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Последние операции',
                      style: AppTheme.labelMedium),
                ),
                const SizedBox(height: 8),

                if (transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text('Нет операций',
                          style: AppTheme.bodyText),
                    ),
                  )
                else
                  ...transactions.take(5).map((tx) => Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 3),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(tx.description,
                                        style: AppTheme.bodyText,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis),
                                    Text(
                                      DateFormat('dd.MM HH:mm')
                                          .format(tx.createdAt),
                                      style:
                                          AppTheme.bodyTextSmall,
                                    ),
                                  ],
                                ),
                              ),
                              MoneyDisplay(amount: tx.amount),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 80),
              ],
            ),

            // Loans tab
            loans.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_outlined,
                            size: 48, color: Color(0xFF4A4A6A)),
                        const SizedBox(height: 12),
                        Text('Нет активных кредитов',
                            style: AppTheme.bodyText),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _showLoanDialog(context, auth, game),
                          child: const Text('Взять кредит'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: loans.length + 1,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton.icon(
                            onPressed: () => _showLoanDialog(
                                context, auth, game),
                            icon: const Icon(Icons.add),
                            label:
                                const Text('Взять новый кредит'),
                          ),
                        );
                      }
                      final loan = loans[index - 1];
                      final monthlyPayment = loan.termMonths > 0
                          ? (loan.remaining / loan.monthsRemaining)
                              .ceil()
                          : loan.remaining;

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
                                  Icon(Icons.account_balance,
                                      color: AppTheme.accentBlue,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text('Кредит №${index}',
                                      style: AppTheme.labelMedium),
                                  const Spacer(),
                                  MoneyDisplay(
                                      amount: -loan.remaining),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _FinRow(
                                label: 'Сумма кредита',
                                value: '\$${loan.amount}',
                              ),
                              _FinRow(
                                label: 'Ставка',
                                value:
                                    '${(loan.interestRate * 100).toStringAsFixed(1)}% год.',
                              ),
                              _FinRow(
                                label: 'Срок',
                                value:
                                    '${loan.termMonths} мес. (${loan.monthsRemaining} ост.)',
                              ),
                              _FinRow(
                                label: 'Ежемесячный платёж',
                                value: '\$$monthlyPayment',
                                valueColor: AppTheme.warningAmber,
                              ),
                              _FinRow(
                                label: 'Дата выдачи',
                                value: DateFormat('dd.MM.yyyy')
                                    .format(loan.takenAt),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            // Transactions tab
            transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 48, color: Color(0xFF4A4A6A)),
                        const SizedBox(height: 12),
                        Text('Нет операций',
                            style: AppTheme.bodyText),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: transactions.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 3),
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
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: tx.amount >= 0
                                                ? AppTheme
                                                    .profitGreen
                                                : AppTheme
                                                    .lossRed,
                                            borderRadius:
                                                BorderRadius
                                                    .circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                tx.description,
                                                style: AppTheme
                                                    .bodyText,
                                                maxLines: 1,
                                                overflow: TextOverflow
                                                    .ellipsis,
                                              ),
                                              Text(
                                                _txTypeLabel(
                                                    tx.type),
                                                style: AppTheme
                                                    .bodyTextSmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Padding(
                                      padding: const EdgeInsets
                                          .only(left: 14),
                                      child: Text(
                                        DateFormat('dd.MM.yyyy HH:mm')
                                            .format(tx.createdAt),
                                        style: AppTheme
                                            .bodyTextSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                                MoneyDisplay(amount: tx.amount),
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

  String _txTypeLabel(String type) {
    switch (type) {
      case 'cargo_sale':
        return 'Продажа груза';
      case 'cargo_buy':
        return 'Покупка груза';
      case 'fuel':
        return 'Топливо';
      case 'loan_payment':
        return 'Погашение кредита';
      case 'salary':
        return 'Зарплата';
      case 'ship_purchase':
        return 'Покупка корабля';
      case 'ship_sale':
        return 'Продажа корабля';
      case 'factory_build':
        return 'Строительство фабрики';
      case 'repair':
        return 'Ремонт';
      case 'tax':
        return 'Налог';
      case 'credit':
        return 'Кредит';
      case 'factory_output_sale':
        return 'Продажа продукции';
      case 'factory_input_buy':
        return 'Закупка сырья';
      case 'ship_market_sale':
        return 'Продажа на рынке';
      case 'ship_market_purchase':
        return 'Покупка на рынке';
      case 'employee_hire':
        return 'Найм сотрудника';
      case 'loan_disbursement':
        return 'Выдача кредита';
      default:
        return type;
    }
  }

  void _showLoanDialog(
      BuildContext context, AuthProvider auth, GameProvider game) {
    double amount = 100000.0;
    int termMonths = 12;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final interest = GameConstants.maxLoanInterest;
            final totalRepay =
                (amount * (1 + interest * termMonths / 12)).ceil();
            final monthlyPayment =
                termMonths > 0 ? (totalRepay / termMonths).ceil() : totalRepay;

            return AlertDialog(
              title: const Text('Оформить кредит'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ставка: ${(interest * 100).toStringAsFixed(0)}% годовых',
                    style: AppTheme.bodyTextSmall,
                  ),
                  const SizedBox(height: 16),
                  // Amount slider
                  Text(
                    'Сумма: \$${NumberFormat.compact().format(amount.round())}',
                    style: AppTheme.monoNumber,
                  ),
                  Slider(
                    value: amount.toDouble(),
                    min: GameConstants.minLoanAmount.toDouble(),
                    max: GameConstants.maxLoanAmount.toDouble(),
                    divisions: 50,
                    activeColor: AppTheme.accentBlue,
                    inactiveColor: AppTheme.dividerColor,
                    label: '\$${amount.round()}',
                    onChanged: (v) {
                      setDialogState(() {
                        amount = v.roundToDouble();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  // Term selector
                  Text('Срок: $termMonths мес.',
                      style: AppTheme.monoNumber),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        GameConstants.loanTerms.map((term) {
                      final isSelected = termMonths == term;
                      return ChoiceChip(
                        label: Text('$term мес.'),
                        selected: isSelected,
                        onSelected: (_) {
                          setDialogState(() {
                            termMonths = term;
                          });
                        },
                        selectedColor: AppTheme.accentBlue,
                        backgroundColor: AppTheme.inputBackground,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textGrayLight,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF1E3A5F)),
                  _FinRow(label: 'Сумма', value: '\$${amount.round()}'),
                  _FinRow(
                      label: 'К возврату',
                      value: '\$$totalRepay'),
                  _FinRow(
                      label: 'Ежемес. платёж',
                      value: '\$$monthlyPayment',
                      valueColor: AppTheme.warningAmber),
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
                    await game.takeLoan(amount.round(), termMonths);
                    if (context.mounted) {
                      final msg = game.errorMessage ??
                          'Кредит оформлен!';
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
                  child: const Text('Оформить'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FinRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _FinRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
