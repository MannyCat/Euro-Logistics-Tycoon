import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedCategory = 'all'; // 'all', 'fleet', 'logistics', 'finance', 'infra', 'level'

  static const _categoryLabels = {
    'all': 'Все',
    'fleet': 'Автопарк',
    'logistics': 'Логистика',
    'finance': 'Финансы',
    'infra': 'Инфраструктура',
    'level': 'Уровни',
  };

  static const _categoryIcons = {
    'all': Icons.apps,
    'fleet': Icons.local_shipping,
    'logistics': Icons.check_circle,
    'finance': Icons.euro,
    'infra': Icons.warehouse,
    'level': Icons.star,
  };

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final unlockedIds = game.unlockedAchievementIds;
    final totalCount = GameConstants.achievements.length;
    final unlockedCount = game.achievementCount;
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    // Filter achievements by selected category
    final filteredAchievements = _selectedCategory == 'all'
        ? GameConstants.achievements
        : GameConstants.achievements.where((a) => a.category == _selectedCategory).toList();

    return ETS2Modal(
      title: 'Достижения',
      icon: Icons.military_tech,
      child: game.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5C542)))
          : Column(
              children: [
                // Summary card
                Container(
                  margin: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF3A3A3A)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.military_tech, color: Color(0xFFF5C542), size: 20),
                              const SizedBox(width: 10),
                              Text(
                                '$unlockedCount / $totalCount достижений',
                                style: const TextStyle(
                                  color: Color(0xFFD0D0D0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Color(0xFFF5C542),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFF1A1A1A),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF5C542)),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                // Category filter chips
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: const Color(0xFF252525),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _categoryLabels.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _filterChip(entry.key, entry.value),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF3A3A3A)),
                // Achievement list
                Expanded(
                  child: filteredAchievements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.military_tech_outlined, size: 48, color: Color(0xFF666666)),
                              const SizedBox(height: 12),
                              Text('Нет достижений', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
                              const SizedBox(height: 4),
                              const Text(
                                'Достижения в этой категории пока отсутствуют',
                                style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredAchievements.length,
                          itemBuilder: (context, i) {
                            final def = filteredAchievements[i];
                            final isUnlocked = unlockedIds.contains(def.id);
                            final userAchievement = isUnlocked
                                ? game.myAchievements.where((a) => a.id == def.id).firstOrNull
                                : null;
                            return _AchievementCard(
                              def: def,
                              isUnlocked: isUnlocked,
                              unlockedAt: userAchievement?.unlockedAt,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(String key, String label) {
    final selected = _selectedCategory == key;
    final icon = _categoryIcons[key] ?? Icons.apps;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5C542).withOpacity(0.15) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFF5C542).withOpacity(0.4) : const Color(0xFF3A3A3A),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? const Color(0xFFF5C542) : const Color(0xFF888888)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFFF5C542) : const Color(0xFF888888),
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementDef def;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const _AchievementCard({
    required this.def,
    required this.isUnlocked,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    // Tier border / glow
    Color borderColor;
    Color? glowColor;
    String tierLabel;

    switch (def.tier) {
      case 3:
        borderColor = const Color(0xFFFFC107);
        glowColor = const Color(0xFFFFC107).withOpacity(0.15);
        tierLabel = 'GOLD';
        break;
      case 2:
        borderColor = const Color(0xFF42A5F5);
        glowColor = const Color(0xFF42A5F5).withOpacity(0.1);
        tierLabel = 'SILVER';
        break;
      default:
        borderColor = const Color(0xFF3A3A3A);
        glowColor = null;
        tierLabel = '';
    }

    // For locked achievements, override colors
    final effectiveBorderColor = isUnlocked ? borderColor : const Color(0xFF3A3A3A);
    final effectiveGlowColor = isUnlocked ? glowColor : null;
    final effectiveIconColor = isUnlocked ? def.color : const Color(0xFF666666);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: effectiveBorderColor),
        boxShadow: effectiveGlowColor != null
            ? [
                BoxShadow(
                  color: effectiveGlowColor,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isUnlocked ? def.color : const Color(0xFF666666)).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                def.icon,
                color: effectiveIconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          def.name,
                          style: TextStyle(
                            color: isUnlocked ? const Color(0xFFD0D0D0) : const Color(0xFF888888),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Tier badge (only show for tier >= 2)
                      if (def.tier >= 2) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: borderColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: borderColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            tierLabel,
                            style: TextStyle(
                              color: borderColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    def.description,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status indicator
            if (isUnlocked) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF66BB6A), size: 18),
                  const SizedBox(height: 2),
                  Text(
                    unlockedAt != null ? _formatDate(unlockedAt!) : '',
                    style: const TextStyle(color: Color(0xFF666666), fontSize: 10),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Разблокировано',
                    style: TextStyle(color: Color(0xFF66BB6A), fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ] else ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFF666666), size: 18),
                  const SizedBox(height: 4),
                  Text(
                    '+${def.reward} XP',
                    style: const TextStyle(
                      color: Color(0xFF42A5F5),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return '${diff.inHours}ч назад';
    if (diff.inDays < 7) return '${diff.inDays}д назад';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
