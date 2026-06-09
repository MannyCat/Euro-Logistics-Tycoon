import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/driver.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  int _selectedFilter = 0; // 0=All, 1=Available, 2=Assigned, 3=Tired

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final companyId = auth.companyId ?? '';

    final filteredDrivers = switch (_selectedFilter) {
      1 => game.availableDrivers,
      2 => game.assignedDrivers,
      3 => game.tiredDrivers,
      _ => game.myDrivers,
    };

    return ETS2Modal(
      title: 'Водители',
      icon: Icons.people,
      actions: [
        TextButton.icon(
          onPressed: game.isLoading ? null : () => _hireDriver(context, game, companyId),
          icon: const Icon(Icons.person_add, color: Color(0xFFF5C542), size: 18),
          label: Text('Нанять (${GameConstants.formatMoney(GameConstants.driverBaseSalary * GameConstants.driverHireCostMultiplier)})', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 12)),
        ),
      ],
      child: game.isLoading && game.myDrivers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5C542)))
          : game.myDrivers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 48, color: Color(0xFF666666)),
                      const SizedBox(height: 12),
                      Text('Нет водителей', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
                      const SizedBox(height: 4),
                      const Text('Нанимайте водителей для управления грузовиками', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _hireDriver(context, game, companyId),
                        icon: const Icon(Icons.person_add),
                        label: Text('Нанять за ${GameConstants.formatMoney(GameConstants.driverBaseSalary * GameConstants.driverHireCostMultiplier)}'),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: const Color(0xFF252525),
                      child: Row(
                        children: [
                          Text('Всего: ${game.myDrivers.length}', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                          const SizedBox(width: 12),
                          Text('Свободных: ${game.availableDrivers.length}', style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          Text('Назначенных: ${game.assignedDrivers.length}', style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          Text('Ср. ур.: ${game.avgSkillLevel.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    // Filter tabs
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: const Color(0xFF202020),
                      child: Row(
                        children: [
                          _filterChip('Все', 0, count: game.myDrivers.length),
                          const SizedBox(width: 6),
                          _filterChip('Свободные', 1, count: game.availableDrivers.length),
                          const SizedBox(width: 6),
                          _filterChip('Назначенные', 2, count: game.assignedDrivers.length),
                          const SizedBox(width: 6),
                          _filterChip('Уставшие', 3, count: game.tiredDrivers.length),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF3A3A3A)),
                    Expanded(
                      child: filteredDrivers.isEmpty
                          ? Center(child: Text('Нет водителей в этой категории', style: AppTheme.bodySm))
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: filteredDrivers.length,
                              itemBuilder: (context, i) => _DriverCard(
                                driver: filteredDrivers[i],
                                game: game,
                                companyId: companyId,
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _filterChip(String label, int index, {int? count}) {
    final selected = _selectedFilter == index;
    final text = count != null ? '$label ($count)' : label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5C542).withOpacity(0.15) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFFF5C542).withOpacity(0.4) : const Color(0xFF3A3A3A)),
        ),
        child: Text(text, style: TextStyle(
          color: selected ? const Color(0xFFF5C542) : const Color(0xFF888888),
          fontSize: 11,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }

  Future<void> _hireDriver(BuildContext context, GameProvider game, String companyId) async {
    final cost = GameConstants.driverBaseSalary * GameConstants.driverHireCostMultiplier;
    final money = game.company?.money ?? 0;
    if (money < cost) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Недостаточно средств (нужно: ${GameConstants.formatMoney(cost)})'),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
        title: const Text('Нанять водителя?', style: TextStyle(color: Color(0xFFD0D0D0))),
        content: Text('Стоимость: ${GameConstants.formatMoney(cost)} (зарплата за 30 дней)', style: const TextStyle(color: Color(0xFF888888))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Нанять', style: TextStyle(color: Color(0xFF66BB6A)))),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await game.hireDriver(companyId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Водитель нанят!' : game.error ?? 'Ошибка'),
        backgroundColor: ok ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

class _DriverCard extends StatefulWidget {
  final Driver driver;
  final GameProvider game;
  final String companyId;
  const _DriverCard({required this.driver, required this.game, required this.companyId});

  @override
  State<_DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<_DriverCard> {
  bool _isActionLoading = false;

  Driver get d => widget.driver;
  GameProvider get game => widget.game;
  String get companyId => widget.companyId;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor;
    final statusIcon = _statusIcon;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: avatar, name, level, status
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: statusColor.withOpacity(0.15),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(d.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 14, fontWeight: FontWeight.w600))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 12),
                              const SizedBox(width: 4),
                              Text(d.statusDisplay, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFF5C542).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: Text(d.skillLevelDisplay, style: const TextStyle(color: Color(0xFFF5C542), fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 10),
                        Text('${GameConstants.formatMoney(d.salaryDaily)}/день', style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontFamily: 'monospace')),
                        const SizedBox(width: 10),
                        Text('Рейсов: ${d.tripsCompleted}', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // XP bar
          const SizedBox(height: 8),
          _xpBar,
          // Skill bars
          const SizedBox(height: 6),
          _skillBar('⚡ Скорость', d.speedSkill, const Color(0xFF42A5F5)),
          const SizedBox(height: 4),
          _skillBar('⛽ Экономия топлива', d.fuelEfficiencySkill, const Color(0xFF66BB6A)),
          const SizedBox(height: 4),
          _skillBar('🛡️ Надёжность', d.reliabilitySkill, const Color(0xFFCE93D8)),
          // Fatigue bar
          if (d.fatigue > 0) ...[
            const SizedBox(height: 4),
            _fatigueBar,
          ],
          // Action buttons
          const SizedBox(height: 8),
          _actionButtons,
        ],
      ),
    );
  }

  Color get _statusColor => switch (d.status) {
    'available' => const Color(0xFF66BB6A),
    'assigned' => const Color(0xFF42A5F5),
    'resting' => const Color(0xFFCE93D8),
    'in_transit' => const Color(0xFFF5C542),
    _ => const Color(0xFF888888),
  };

  IconData get _statusIcon => switch (d.status) {
    'available' => Icons.person,
    'assigned' => Icons.person_pin,
    'resting' => Icons.bedtime,
    'in_transit' => Icons.local_shipping,
    _ => Icons.person,
  };

  Widget get _xpBar {
    final xpInLevel = d.xp % 100;
    final xpPercent = d.skillLevel >= 20 ? 1.0 : xpInLevel / 100.0;
    return Row(
      children: [
        const Text('XP', style: TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: xpPercent,
              backgroundColor: const Color(0xFF1A1A1A),
              valueColor: AlwaysStoppedAnimation<Color>(d.skillLevel >= 20 ? const Color(0xFFF5C542) : const Color(0xFF42A5F5)),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (d.skillLevel < 20)
          Text('${d.xpToNextLevel} до след.', style: const TextStyle(color: Color(0xFF666666), fontSize: 10, fontFamily: 'monospace'))
        else
          const Text('MAX', style: TextStyle(color: Color(0xFFF5C542), fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _skillBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value / 100.0,
              backgroundColor: const Color(0xFF1A1A1A),
              valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.8)),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text('$value', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
        ),
      ],
    );
  }

  Widget get _fatigueBar {
    final fatigueColor = d.fatigue >= 90
        ? const Color(0xFFEF5350)
        : d.fatigue >= 50
            ? const Color(0xFFFF9800)
            : const Color(0xFFF5C542);
    return Row(
      children: [
        const SizedBox(
          width: 120,
          child: Text('😴 Усталость', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: d.fatigue / 100.0,
              backgroundColor: const Color(0xFF1A1A1A),
              valueColor: AlwaysStoppedAnimation<Color>(fatigueColor),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text('${d.fatigue}%', style: TextStyle(color: fatigueColor, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
        ),
      ],
    );
  }

  Widget get _actionButtons {
    final idleTrucks = game.idleTrucks;
    return Row(
      children: [
        // Assign to truck (if available and idle trucks exist)
        if (d.isAvailable && idleTrucks.isNotEmpty) ...[
          Expanded(
            child: _actionBtn(
              icon: Icons.directions_car,
              label: 'Назначить',
              color: const Color(0xFF42A5F5),
              isLoading: _isActionLoading,
              onPressed: _isActionLoading ? null : () => _showAssignDialog(context),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Unassign from truck (if assigned)
        if (d.isAssigned) ...[
          Expanded(
            child: _actionBtn(
              icon: Icons.person_remove,
              label: 'Снять',
              color: const Color(0xFFEF5350),
              isLoading: _isActionLoading,
              onPressed: _isActionLoading ? null : () => _unassign(),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Rest button (if tired)
        if (d.isTired) ...[
          Expanded(
            child: _actionBtn(
              icon: Icons.bedtime,
              label: 'Отдых (-50%)',
              color: const Color(0xFFCE93D8),
              isLoading: _isActionLoading,
              onPressed: _isActionLoading ? null : () => _rest(),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Rest button even if not super tired but has some fatigue
        if (!d.isTired && d.fatigue > 0 && !d.isAssigned) ...[
          Expanded(
            child: _actionBtn(
              icon: Icons.bedtime,
              label: 'Отдых',
              color: const Color(0xFFCE93D8).withOpacity(0.6),
              isLoading: _isActionLoading,
              onPressed: _isActionLoading ? null : () => _rest(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool isLoading,
    VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: color, strokeWidth: 2))
          : Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: onPressed != null ? color : const Color(0xFF3A3A3A)),
        minimumSize: const Size(double.infinity, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 11),
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    final idleTrucks = game.idleTrucks;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
        title: Text('Назначить ${d.name} на грузовик', style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 14)),
        children: idleTrucks.map((truck) {
          final typeInfo = GameConstants.findTruckType(truck.truckType);
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _assign(truck.id);
            },
            child: Row(
              children: [
                const Icon(Icons.local_shipping, color: Color(0xFF42A5F5), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(truck.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 13)),
                      Text('${typeInfo?.name ?? truck.truckType} • Сост. ${truck.condition}%', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _assign(String truckId) async {
    setState(() => _isActionLoading = true);
    final ok = await game.assignDriver(d.id, truckId, companyId);
    if (mounted) setState(() => _isActionLoading = false);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(game.error ?? 'Ошибка назначения'),
        backgroundColor: const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _unassign() async {
    setState(() => _isActionLoading = true);
    final ok = await game.unassignDriver(d.id, companyId);
    if (mounted) setState(() => _isActionLoading = false);
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(game.error ?? 'Ошибка снятия'),
        backgroundColor: const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _rest() async {
    setState(() => _isActionLoading = true);
    final ok = await game.restDriver(d.id, companyId);
    if (mounted) setState(() => _isActionLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '${d.name} отдохнул!' : game.error ?? 'Ошибка'),
        backgroundColor: ok ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}
