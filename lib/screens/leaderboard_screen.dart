import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';
import '../config/app_icons.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final leaderboard = game.leaderboard;
    final myCompanyId = context.watch<AuthProvider>().companyId ?? '';

    return ETS2Modal(
      title: 'Рейтинг',
      icon: AppIcons.leaderboard,
      actions: [
        IconButton(
          icon: const Icon(AppIcons.refreshCw, color: Color(0xFF999999), size: 18),
          tooltip: 'Обновить',
          onPressed: () => game.loadLeaderboard(),
        ),
      ],
      child: leaderboard.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(AppIcons.leaderboard, size: 48, color: Color(0xFF666666)),
                      const SizedBox(height: 12),
                      Text('Нет данных', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
                      const SizedBox(height: 4),
                      const Text(
                        'Рейтинг пока недоступен. Попробуйте позже.',
                        style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => game.loadLeaderboard(),
                        icon: const Icon(AppIcons.refreshCw, size: 16),
                        label: const Text('Обновить'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Top 3 podium
                    if (leaderboard.length >= 3) _PodiumSection(
                      leaderboard: leaderboard,
                      myCompanyId: myCompanyId,
                    ),
                    // Compact list for 4th+
                    if (leaderboard.length > 3) ...[
                      const Divider(height: 1, color: Color(0xFF3A3A3A)),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(6),
                          itemCount: leaderboard.length - 3,
                          itemBuilder: (context, i) {
                            final entry = leaderboard[i + 3];
                            final rank = i + 4;
                            final isMe = entry['id'] == myCompanyId;
                            return _PlayerRow(
                              entry: entry,
                              rank: rank,
                              isMe: isMe,
                            );
                          },
                        ),
                      ),
                    ] else if (leaderboard.length <= 3) ...[
                      const Divider(height: 1, color: Color(0xFF3A3A3A)),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Недостаточно игроков для полного рейтинга',
                            style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _PodiumSection extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboard;
  final String myCompanyId;

  const _PodiumSection({
    required this.leaderboard,
    required this.myCompanyId,
  });

  @override
  Widget build(BuildContext context) {
    final first = leaderboard[0];
    final second = leaderboard[1];
    final third = leaderboard[2];

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF252525),
      ),
      child: Column(
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.leaderboard, color: Color(0xFFF5C542), size: 16),
                SizedBox(width: 8),
                Text(
                  'ТОП-3 ИГРОКОВ',
                  style: TextStyle(
                    color: Color(0xFFF5C542),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Podium cards: 2nd | 1st | 3rd
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd place
                Expanded(
                  child: _PodiumCard(
                    entry: second,
                    rank: 2,
                    isMe: second['id'] == myCompanyId,
                    medalColor: const Color(0xFFB0BEC5),
                    bgColor: const Color(0xFFB0BEC5).withOpacity(0.06),
                    borderColor: const Color(0xFFB0BEC5).withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 6),
                // 1st place (taller)
                Expanded(
                  child: _PodiumCard(
                    entry: first,
                    rank: 1,
                    isMe: first['id'] == myCompanyId,
                    medalColor: const Color(0xFFFFC107),
                    bgColor: const Color(0xFFFFC107).withOpacity(0.08),
                    borderColor: const Color(0xFFFFC107).withOpacity(0.4),
                    isFirst: true,
                  ),
                ),
                const SizedBox(width: 6),
                // 3rd place
                Expanded(
                  child: _PodiumCard(
                    entry: third,
                    rank: 3,
                    isMe: third['id'] == myCompanyId,
                    medalColor: const Color(0xFFCD7F32),
                    bgColor: const Color(0xFFCD7F32).withOpacity(0.06),
                    borderColor: const Color(0xFFCD7F32).withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int rank;
  final bool isMe;
  final Color medalColor;
  final Color bgColor;
  final Color borderColor;
  final bool isFirst;

  const _PodiumCard({
    required this.entry,
    required this.rank,
    required this.isMe,
    required this.medalColor,
    required this.bgColor,
    required this.borderColor,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = entry['name'] as String? ?? '???';
    final level = entry['level'] as int? ?? 1;
    final money = entry['money'] as int? ?? 0;
    final truckCount = entry['truck_count'] as int? ?? 0;
    final clanTag = entry['clan_tag'] as String?;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: isFirst ? 18 : 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe ? const Color(0xFFF5C542) : borderColor,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: isFirst
            ? [
                BoxShadow(
                  color: medalColor.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Medal circle
          Container(
            width: isFirst ? 40 : 34,
            height: isFirst ? 40 : 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medalColor.withOpacity(0.2),
              border: Border.all(color: medalColor, width: 2),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: medalColor,
                  fontSize: isFirst ? 20 : 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            name,
            style: TextStyle(
              color: const Color(0xFFD0D0D0),
              fontSize: isFirst ? 13 : 12,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Clan tag badge
          if (clanTag != null && clanTag.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFCE93D8).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCE93D8).withOpacity(0.3)),
              ),
              child: Text(
                clanTag,
                style: const TextStyle(
                  color: Color(0xFFCE93D8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (clanTag != null && clanTag.isNotEmpty) const SizedBox(height: 4),
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
            ),
            child: Text(
              'Ур. $level',
              style: const TextStyle(
                color: Color(0xFFFF9800),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isFirst) const SizedBox(height: 8),
          // Stats
          Column(
            children: [
              const SizedBox(height: 6),
              Text(
                GameConstants.formatMoney(money),
                style: TextStyle(
                  color: const Color(0xFF66BB6A),
                  fontSize: isFirst ? 13 : 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.truck, size: 11, color: Color(0xFF888888)),
                  const SizedBox(width: 3),
                  Text(
                    '$truckCount',
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int rank;
  final bool isMe;

  const _PlayerRow({
    required this.entry,
    required this.rank,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final name = entry['name'] as String? ?? '???';
    final level = entry['level'] as int? ?? 1;
    final money = entry['money'] as int? ?? 0;
    final truckCount = entry['truck_count'] as int? ?? 0;
    final completedContracts = entry['completed_contracts'] as int? ?? 0;
    final achievementCount = entry['achievement_count'] as int? ?? 0;
    final clanTag = entry['clan_tag'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFF5C542).withOpacity(0.06) : const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMe ? const Color(0xFFF5C542).withOpacity(0.5) : const Color(0xFF3A3A3A),
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isMe ? const Color(0xFFF5C542) : const Color(0xFF888888),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + clan tag + level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isMe ? const Color(0xFFF5C542) : const Color(0xFFD0D0D0),
                          fontSize: 13,
                          fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (clanTag != null && clanTag.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCE93D8).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFCE93D8).withOpacity(0.3)),
                        ),
                        child: Text(
                          clanTag,
                          style: const TextStyle(
                            color: Color(0xFFCE93D8),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Ур. $level',
                  style: const TextStyle(color: Color(0xFFFF9800), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Stats
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Money
              _miniStat(
                icon: AppIcons.euro,
                value: GameConstants.formatMoney(money),
                color: const Color(0xFF66BB6A),
              ),
              const SizedBox(width: 12),
              // Trucks
              _miniStat(
                icon: AppIcons.truck,
                value: '$truckCount',
                color: const Color(0xFF42A5F5),
              ),
              const SizedBox(width: 12),
              // Contracts
              _miniStat(
                icon: AppIcons.checkCircle,
                value: '$completedContracts',
                color: const Color(0xFFCE93D8),
              ),
              const SizedBox(width: 12),
              // Achievements
              _miniStat(
                icon: AppIcons.militaryTech,
                value: '$achievementCount',
                color: const Color(0xFFF5C542),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
