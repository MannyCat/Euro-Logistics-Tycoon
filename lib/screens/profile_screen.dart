import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/money_display.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    await auth.loadProfile();
    final game = context.read<GameProvider>();
    await Future.wait([
      game.loadMyShips(),
      game.loadMyVoyages(),
      game.loadTransactions(),
    ]);
    _nameController.text = auth.profile?.companyName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final profile = auth.profile;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Профиль')),
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentBlue,
          ),
        ),
      );
    }

    final level = profile.level;
    final currentXp = profile.xp;
    final xpForNext = level * GameConstants.xpPerLevel;
    final xpProgress = currentXp / xpForNext.clamp(1, 999999);
    final completedVoyages =
        game.myVoyages.where((v) => v.status == 'completed').length;

    int totalProfit = 0;
    for (final t in game.transactions) {
      totalProfit += t.amount;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль компании'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                _nameController.text = profile.companyName;
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Company card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor:
                        AppTheme.accentBlue.withOpacity(0.15),
                    child: Icon(Icons.domain,
                        color: AppTheme.accentBlue, size: 32),
                  ),
                  const SizedBox(height: 12),
                  if (_isEditing)
                    TextField(
                      controller: _nameController,
                      textCapitalization:
                          TextCapitalization.words,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Название компании',
                        isDense: true,
                        border: const OutlineInputBorder(),
                        focusedBorder:
                            const OutlineInputBorder(
                          borderSide: BorderSide(
                              color: AppTheme.accentBlue),
                        ),
                      ),
                      style: AppTheme.labelLarge,
                    )
                  else
                    Text(
                      profile.companyName,
                      style: AppTheme.labelLarge.copyWith(
                        fontSize: 22,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: AppTheme.bodyTextSmall,
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _isEditing = false);
                            },
                            child: const Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await auth.updateCompanyName(
                                  _nameController.text);
                              if (context.mounted) {
                                setState(() => _isEditing = false);
                                if (auth.errorMessage ==
                                    null) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Название обновлено!'),
                                      backgroundColor: AppTheme
                                          .profitGreen,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Сохранить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Balance
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Баланс компании',
                          style: AppTheme.bodyTextSmall),
                      const SizedBox(height: 4),
                      MoneyDisplay(
                        amount: profile.money,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Репутация',
                          style: AppTheme.bodyTextSmall),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star,
                              color: AppTheme.warningAmber,
                              size: 18),
                          const SizedBox(width: 4),
                          Text('${profile.reputation}',
                              style: AppTheme.monoNumberLarge
                                  .copyWith(fontSize: 18)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Level / XP
          Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Уровень $level',
                          style: AppTheme.labelMedium),
                      Text('$currentXp / $xpForNext XP',
                          style: AppTheme.monoNumberSmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: xpProgress.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: AppTheme.inputBackground,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                              AppTheme.accentBlue),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Статистика',
                style: AppTheme.labelMedium),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Корабли',
                    value: '${game.myShips.length}',
                    icon: Icons.directions_boat,
                    color: AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatItem(
                    label: 'Рейсы',
                    value: '$completedVoyages',
                    icon: Icons.sailing,
                    color: AppTheme.profitGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Прибыль',
                    value: totalProfit >= 0 ? '+' : '',
                    valueSuffix:
                        '\$${_compactNumber(totalProfit.abs())}',
                    icon: totalProfit >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: totalProfit >= 0
                        ? AppTheme.profitGreen
                        : AppTheme.lossRed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatItem(
                    label: 'Сотрудники',
                    value: '${game.employees.length}',
                    icon: Icons.people,
                    color: AppTheme.warningAmber,
                  ),
                ),
              ],
            ),
          ),

          // Date joined
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Компания основана: ${_formatDate(profile.createdAt)}',
              style: AppTheme.bodyTextSmall,
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _compactNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String valueSuffix;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueSuffix = '',
    required this.icon,
    required this.color,
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
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(label, style: AppTheme.bodyTextSmall),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$value$valueSuffix',
              style: AppTheme.monoNumberLarge.copyWith(
                fontSize: 18,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
