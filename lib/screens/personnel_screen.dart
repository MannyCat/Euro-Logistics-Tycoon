import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/game_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/money_display.dart';

class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({super.key});

  @override
  State<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final game = context.read<GameProvider>();
    await game.loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final employees = game.employees;
    final auth = context.watch<AuthProvider>();

    int totalSalary = 0;
    for (final e in employees) {
      totalSalary += e.salary;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Персонал'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHireDialog(context, auth, game),
        backgroundColor: AppTheme.accentBlue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: game.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentBlue,
              ),
            )
          : employees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outlined,
                          size: 48, color: Color(0xFF4A4A6A)),
                      const SizedBox(height: 12),
                      Text('Нет сотрудников',
                          style: AppTheme.bodyText),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            _showHireDialog(context, auth, game),
                        child: const Text('Нанять сотрудника'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // Summary
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Card(
                                margin: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Text('Сотрудников',
                                          style: AppTheme
                                              .bodyTextSmall),
                                      Text(
                                          '${employees.length}',
                                          style: AppTheme
                                              .monoNumberLarge
                                              .copyWith(
                                                  fontSize: 18)),
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
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Text('Зарплаты/мес.',
                                          style: AppTheme
                                              .bodyTextSmall),
                                      MoneyDisplay(
                                          amount: -totalSalary,
                                          fontSize: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Employee list
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final emp = employees[index];
                          final port = emp.assignedPortId != null
                              ? GameConstants.findPort(
                                  emp.assignedPortId!)
                              : null;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: _roleColor(
                                        emp.role)
                                        .withOpacity(0.15),
                                    child: Icon(
                                      _roleIcon(emp.role),
                                      color: _roleColor(emp.role),
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
                                        Text(emp.name,
                                            style: AppTheme
                                                .labelMedium),
                                        Row(
                                          children: [
                                            Text(
                                              _roleLabel(
                                                  emp.role),
                                              style: AppTheme
                                                  .bodyTextSmall
                                                  .copyWith(
                                                color:
                                                    _roleColor(emp.role),
                                              ),
                                            ),
                                            if (port != null) ...[
                                              const SizedBox(
                                                  width: 6),
                                              Text(
                                                  '📍 ${port.name}',
                                                  style: AppTheme
                                                      .bodyTextSmall),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      MoneyDisplay(
                                          amount: emp.salary),
                                      Text(
                                          'Навык: ${emp.skill}',
                                          style: AppTheme
                                              .bodyTextSmall),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: employees.length,
                      ),
                    ),

                    const SliverToBoxAdapter(
                        child: SizedBox(height: 80)),
                  ],
                ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'captain':
        return 'Капитан';
      case 'engineer':
        return 'Инженер';
      case 'sailor':
        return 'Моряк';
      case 'broker':
        return 'Брокер';
      default:
        return role;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'captain':
        return Icons.badge;
      case 'engineer':
        return Icons.build;
      case 'sailor':
        return Icons.sailing;
      case 'broker':
        return Icons.handshake;
      default:
        return Icons.person;
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'captain':
        return AppTheme.accentBlue;
      case 'engineer':
        return AppTheme.warningAmber;
      case 'sailor':
        return AppTheme.profitGreen;
      case 'broker':
        return const Color(0xFF9C27B0);
      default:
        return AppTheme.textGray;
    }
  }

  void _showHireDialog(
      BuildContext context, AuthProvider auth, GameProvider game) {
    final roles = [
      {
        'id': 'captain',
        'name': 'Капитан',
        'salary': GameConstants.baseCaptainSalary,
        'icon': Icons.badge,
      },
      {
        'id': 'engineer',
        'name': 'Инженер',
        'salary': GameConstants.baseEngineerSalary,
        'icon': Icons.build,
      },
      {
        'id': 'sailor',
        'name': 'Моряк',
        'salary': GameConstants.baseSailorSalary,
        'icon': Icons.sailing,
      },
      {
        'id': 'broker',
        'name': 'Брокер',
        'salary': GameConstants.baseBrokerSalary,
        'icon': Icons.handshake,
      },
    ];

    final nameController = TextEditingController();
    String? selectedRole;
    String? selectedPort;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Нанять сотрудника'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Имя сотрудника',
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Иван Петров',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Должность', style: AppTheme.bodyTextSmall),
                    const SizedBox(height: 8),
                    ...roles.map((role) {
                      final isSelected =
                          selectedRole == role['id'];
                      return RadioListTile<String>(
                        value: role['id'] as String,
                        groupValue: selectedRole,
                        title: Row(
                          children: [
                            Icon(role['icon'] as IconData,
                                size: 18,
                                color: _roleColor(
                                    role['id'] as String)),
                            const SizedBox(width: 8),
                            Text(role['name'] as String,
                                style:
                                    AppTheme.labelMedium),
                            const Spacer(),
                            Text(
                                '\$${role['salary']} /мес.',
                                style: AppTheme
                                    .monoNumberSmall),
                          ],
                        ),
                        activeColor: AppTheme.accentBlue,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedRole = value;
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 8),
                    Text('Порт назначения',
                        style: AppTheme.bodyTextSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedPort,
                      decoration: const InputDecoration(
                        labelText: 'Порт',
                        prefixIcon:
                            Icon(Icons.anchor_outlined),
                      ),
                      dropdownColor: AppTheme.cardBackground,
                      items: GameConstants.ports.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(
                              '${p.name} (${p.country})',
                              style: AppTheme.bodyText),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPort = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    nameController.dispose();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: (selectedRole != null &&
                          nameController.text.trim().isNotEmpty)
                      ? () async {
                          Navigator.pop(ctx);
                          await game.hireEmployee(
                            selectedRole!,
                            nameController.text.trim(),
                            selectedPort,
                          );
                          nameController.dispose();
                          if (context.mounted) {
                            final msg = game.errorMessage ??
                                'Сотрудник нанят!';
                            final color = game.errorMessage != null
                                ? AppTheme.lossRed
                                : AppTheme.profitGreen;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: color,
                              ),
                            );
                          }
                        }
                      : null,
                  child: const Text('Нанять'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
