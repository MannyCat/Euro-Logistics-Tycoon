import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';
import '../config/app_icons.dart';
import '../models/company.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Timer? _statsTimer;
  Duration _uptime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _uptime += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final userId = auth.userId ?? '';
    final company = game.company;

    return ETS2Modal(
      title: 'Настройки',
      icon: AppIcons.settings,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // App info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
            child: Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF5C542).withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(AppIcons.truck, color: Color(0xFFF5C542), size: 22)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Euro Logistics Tycoon', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Версия 1.1.0  •  Сессия: ${_fmtDuration(_uptime)}', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Company stats
          if (company != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Статистика компании', style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  _statRow('Название', company.name),
                  _statRow('Баланс', GameConstants.formatMoney(company.money)),
                  _statRow('Уровень', 'Lv.${company.level}  (${company.xp} XP)'),
                  _statRow('Репутация', '${company.reputation}/${GameConstants.maxReputation}'),
                  const SizedBox(height: 8),
                  // XP progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (company.xp % GameConstants.xpPerLevel) / GameConstants.xpPerLevel,
                      backgroundColor: const Color(0xFF1A1A1A),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF5C542)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${GameConstants.xpPerLevel - (company.xp % GameConstants.xpPerLevel)} XP до след. уровня', style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
                ],
              ),
            ),

          if (company != null) const SizedBox(height: 10),

          // Fleet stats
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Активность', style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniStat(AppIcons.truck, '${game.myTrucks.length}', 'Грузовиков'),
                    _miniStat(AppIcons.users, '${game.myDrivers.length}', 'Водителей'),
                    _miniStat(AppIcons.warehouses, '${game.myWarehouses.length}', 'Складов'),
                    _miniStat(AppIcons.description, '${game.availableContracts.length}', 'Контрактов'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Company customization section
          _CompanyCustomizationSection(game: game),

          const SizedBox(height: 10),

          // User info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
            child: Row(
              children: [
                const Icon(AppIcons.person, color: Color(0xFFF5C542), size: 20),
                const SizedBox(width: 10),
                const Text('Профиль', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('ID: ${userId.length > 12 ? '${userId.substring(0, 12)}...' : userId}', style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontFamily: 'monospace')),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Game tips
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Советы', style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _tip(AppIcons.truck, 'Купите грузовики — без них нет рейсов'),
                const SizedBox(height: 6),
                _tip(AppIcons.description, 'Примите контракт — грузовик сам поедет'),
                const SizedBox(height: 6),
                _tip(AppIcons.wrench, 'Следите за топливом и состоянием'),
                const SizedBox(height: 6),
                _tip(AppIcons.warehouses, 'Склады в городах расширяют сеть'),
                const SizedBox(height: 6),
                _tip(AppIcons.star, 'Выполняйте рейсы для опыта и уровней'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===== PRESTIGE SECTION =====
          if (company != null)
            _PrestigeSection(company: company),

          if (company != null) const SizedBox(height: 16),

          // Logout
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
                  title: const Text('Выйти?', style: TextStyle(color: Color(0xFFD0D0D0))),
                  content: const Text('Вы уверены что хотите выйти из аккаунта?', style: TextStyle(color: Color(0xFF888888))),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888)))),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти', style: TextStyle(color: Color(0xFFEF5350)))),
                  ],
                ),
              );
              if (confirm == true) {
                if (mounted) await auth.logout();
              }
            },
            icon: const Icon(AppIcons.logOut, color: Color(0xFFEF5350)),
            label: const Text('Выйти из аккаунта', style: TextStyle(color: Color(0xFFEF5350))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEF5350)),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace'))),
      ],
    ),
  );

  Widget _miniStat(IconData icon, String value, String label) => Column(
    children: [
      Icon(icon, size: 18, color: const Color(0xFFF5C542)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Color(0xFFD0D0D0), fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'monospace')),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 10)),
    ],
  );

  Widget _tip(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFFF5C542).withOpacity(0.6)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF888888), fontSize: 12))),
    ],
  );
}

/// Company customization section — logo icon and color
class _CompanyCustomizationSection extends StatelessWidget {
  final GameProvider game;
  const _CompanyCustomizationSection({required this.game});

  static const _iconNames = [
    'local_shipping', 'star', 'lightning', 'shield', 'rocket',
    'crown', 'diamond', 'public', 'anchor', 'eco',
    'local_fire_department', 'bolt', 'settings', 'flag', 'favorite',
  ];

  static const _iconLabels = [
    'Грузовик', 'Звезда', 'Молния', 'Щит', 'Ракета',
    'Корона', 'Бриллиант', 'Глобус', 'Якорь', 'Лист',
    'Пламя', 'Болт', 'Шестерня', 'Флаг', 'Сердце',
  ];

  static const _colorHexes = [
    'F5C542', // Gold
    '42A5F5', // Blue
    '66BB6A', // Green
    'EF5350', // Red
    'CE93D8', // Purple
    'FF9800', // Orange
    '26C6DA', // Cyan
    '78909C', // Blue Grey
  ];

  static const _colorLabels = [
    'Золото', 'Синий', 'Зелёный', 'Красный', 'Фиолетовый', 'Оранжевый', 'Голубой', 'Серый',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Компания', style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),

          // Logo icon grid
          const Text('Логотип:', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(_iconNames.length, (i) {
              final isSelected = game.companyIcon == _iconNames[i];
              return InkWell(
                onTap: () => game.setCompanyIcon(_iconNames[i]),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(int.parse('FF${game.companyColorHex}', radix: 16)).withOpacity(0.15)
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? Color(int.parse('FF${game.companyColorHex}', radix: 16))
                          : const Color(0xFF3A3A3A),
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_iconDataFromName(_iconNames[i]),
                        size: 16,
                        color: isSelected
                            ? Color(int.parse('FF${game.companyColorHex}', radix: 16))
                            : const Color(0xFF888888)),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 14),

          // Color picker
          const Text('Цвет компании:', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_colorHexes.length, (i) {
              final isSelected = game.companyColorHex == _colorHexes[i];
              final color = Color(int.parse('FF${_colorHexes[i]}', radix: 16));
              return InkWell(
                onTap: () => game.setCompanyColor(_colorHexes[i]),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFD0D0D0) : const Color(0xFF555555),
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)] : null,
                  ),
                  child: isSelected
                      ? const Icon(AppIcons.check, size: 16, color: Color(0xFF1A1A1A))
                      : null,
                ),
              );
            }),
          ),

          const SizedBox(height: 10),

          // Preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF3A3A3A)),
            ),
            child: Row(
              children: [
                const Text('Превью: ', style: TextStyle(color: Color(0xFF666666), fontSize: 11)),
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: Color(int.parse('FF${game.companyColorHex}', radix: 16)).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(_iconDataFromName(game.companyIcon),
                    size: 14,
                    color: Color(int.parse('FF${game.companyColorHex}', radix: 16))),
                ),
                const SizedBox(width: 8),
                Text(game.company?.name ?? 'Company',
                  style: TextStyle(
                    color: Color(int.parse('FF${game.companyColorHex}', radix: 16)),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconDataFromName(String name) => switch (name) {
    'local_shipping' => AppIcons.truck,
    'star' => AppIcons.star,
    'lightning' => AppIcons.lightning,
    'shield' => AppIcons.shield,
    'rocket' => AppIcons.rocket,
    'crown' => AppIcons.crown,
    'diamond' => AppIcons.diamond,
    'public' => AppIcons.public,
    'anchor' => AppIcons.anchor,
    'eco' => AppIcons.eco,
    'local_fire_department' => AppIcons.fire,
    'bolt' => AppIcons.bolt,
    'settings' => AppIcons.settings,
    'flag' => AppIcons.flag,
    'favorite' => AppIcons.heart,
    _ => AppIcons.truck,
  };
}

/// Prestige section — shows prestige level, bonuses, and reset button
class _PrestigeSection extends StatelessWidget {
  final Company company;
  const _PrestigeSection({required this.company});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final auth = context.watch<AuthProvider>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: company.prestigeLevel > 0
              ? const Color(0xFFF5C542).withOpacity(0.5)
              : const Color(0xFF3A3A3A),
          width: company.prestigeLevel > 0 ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.star, color: Color(0xFFF5C542), size: 16),
              const SizedBox(width: 6),
              const Text('Престиж', style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (company.prestigeLevel > 0)
                Text(
                  company.prestigeDisplay,
                  style: const TextStyle(fontSize: 16),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Current level
          Row(
            children: [
              const Text('Уровень престижа: ', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              Text(
                '${company.prestigeLevel}',
                style: const TextStyle(
                  color: Color(0xFFF5C542),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),

          if (company.prestigeLevel > 0) ...[
            const SizedBox(height: 8),

            // Bonuses
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5C542).withOpacity(0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF5C542).withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Бонусы престижа:', style: TextStyle(color: Color(0xFFF5C542), fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _bonusRow('💰 Доход', '+${(company.prestigeIncomeBonus * 100).toStringAsFixed(0)}%', const Color(0xFF66BB6A)),
                  _bonusRow('⭐ Опыт', '+${(company.prestigeXpBonus * 100).toStringAsFixed(0)}%', const Color(0xFF42A5F5)),
                  _bonusRow('⛽ Топливо', '-${(company.prestigeFuelDiscount * 100).toStringAsFixed(0)}%', const Color(0xFFFF9800)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Requirement text
          if (company.canPrestige)
            const Text(
              'Доступен престиж-сброс!',
              style: TextStyle(color: Color(0xFF66BB6A), fontSize: 11),
            )
          else
            Text(
              'Нужен ${10 - company.level > 0 ? 10 - company.level : 0} ур. до престижа (мин. 10)',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
            ),

          const SizedBox(height: 10),

          // Prestige reset button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: company.canPrestige && !game.isLoading
                  ? () => _showPrestigeConfirmDialog(context, auth.companyId ?? '', game)
                  : null,
              icon: const Icon(AppIcons.refreshCw, size: 18),
              label: const Text('Престиж-сброс', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: company.canPrestige ? const Color(0xFFEF5350) : const Color(0xFF444444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bonusRow(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.5),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
      ],
    ),
  );

  void _showPrestigeConfirmDialog(BuildContext context, String companyId, GameProvider game) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: const Color(0xFFEF5350).withOpacity(0.5), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(AppIcons.warning, color: Color(0xFFEF5350), size: 24),
            SizedBox(width: 10),
            Text('ПРЕСТИЖ-СБРОС', style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Это необратимое действие!',
              style: TextStyle(color: Color(0xFFEF5350), fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text('❌ Все грузовики будут удалены', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13)),
            const Text('❌ Все водители будут удалены', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13)),
            const Text('❌ Все склады и гаражи будут удалены', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13)),
            const Text('❌ Вы покинете клан', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5C542).withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF5C542).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Вы получите:', style: TextStyle(color: Color(0xFFF5C542), fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('✅ +1 уровень престижа и постоянные бонусы', style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12)),
                  Text('✅ Начало с €1M', style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12)),
                  Text('✅ Уровень 1, репутация 50', style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await game.prestigeReset(companyId);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? '⭐ Престиж-сброс выполнен!'
                        : 'Ошибка престиж-сброса: ${game.error ?? "неизвестная ошибка"}'),
                    backgroundColor: success ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
            ),
            child: const Text('Сбросить (ПРЕСТИЖ!)', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
