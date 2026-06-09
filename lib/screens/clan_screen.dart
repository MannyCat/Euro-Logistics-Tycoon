import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../models/clan.dart';
import '../models/clan_mission.dart';
import '../models/chat_message.dart';
import '../widgets/ets2_modal.dart';
import '../config/app_icons.dart';

class ClanScreen extends StatefulWidget {
  const ClanScreen({super.key});

  @override
  State<ClanScreen> createState() => _ClanScreenState();
}

class _ClanScreenState extends State<ClanScreen> {
  int _activeTab = 0; // 0 = my clan, 1 = missions, 2 = leaderboard

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final game = context.watch<GameProvider>();
    final companyId = auth.companyId ?? '';

    return ETS2Modal(
      title: 'Кланы',
      icon: AppIcons.shield,
      actions: [
        IconButton(
          icon: const Icon(AppIcons.refreshCw, color: Color(0xFF999999), size: 18),
          tooltip: 'Обновить',
          onPressed: () => game.refreshClan(companyId),
        ),
      ],
      child: Column(
        children: [
          // Tab bar
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF252525),
              border: Border(bottom: BorderSide(color: Color(0xFF3A3A3A))),
            ),
            child: Row(
              children: [
                _tabButton('Мой клан', 0),
                const SizedBox(width: 4),
                _tabButton('Миссии', 1),
                const SizedBox(width: 4),
                _tabButton('Рейтинг кланов', 2),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_activeTab),
                child: _activeTab == 0
                    ? _MyClanTab(game: game, companyId: companyId)
                    : _activeTab == 1
                        ? _ClanMissionsTab(game: game, companyId: companyId)
                        : _ClanLeaderboardTab(game: game),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isActive = _activeTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _activeTab = index),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 32,
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF5C542).withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isActive ? Border.all(color: const Color(0xFFF5C542).withOpacity(0.4)) : null,
            ),
            alignment: Alignment.center,
            child: Text(label, textAlign: TextAlign.center, style: TextStyle(
              color: isActive ? const Color(0xFFF5C542) : const Color(0xFF888888),
              fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            )),
          ),
        ),
      ),
    );
  }
}

// ===== MY CLAN TAB =====
class _MyClanTab extends StatelessWidget {
  final GameProvider game;
  final String companyId;
  const _MyClanTab({required this.game, required this.companyId});

  @override
  Widget build(BuildContext context) {
    if (!game.isInClan) {
      return _NoClanView(game: game, companyId: companyId);
    }
    return _ClanDetailView(game: game, companyId: companyId);
  }
}

// ===== NO CLAN VIEW =====
class _NoClanView extends StatelessWidget {
  final GameProvider game;
  final String companyId;
  const _NoClanView({required this.game, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final money = game.company?.money ?? 0;
    final canAfford = money >= GameConstants.clanCreateCost;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5C542).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF5C542).withOpacity(0.3)),
              ),
              child: const Icon(AppIcons.shield, color: Color(0xFFF5C542), size: 36),
            ),
            const SizedBox(height: 16),
            Text('Вы не состоите в клане', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
            const SizedBox(height: 8),
            const Text('Создайте свой клан или вступите в существующий,\nчтобы получать бонусы и соревноваться с другими.', style: TextStyle(color: Color(0xFF666666), fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            // Create clan button
            Container(
              width: 280,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3A3A3A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(AppIcons.addBusiness, color: Color(0xFFF5C542), size: 18),
                      const SizedBox(width: 8),
                      const Text('Создать клан', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 14, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(GameConstants.formatMoney(GameConstants.clanCreateCost), style: TextStyle(color: canAfford ? const Color(0xFF66BB6A) : const Color(0xFFEF5350), fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Стоимость создания: €50K', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: canAfford ? () => _showCreateDialog(context) : null,
                      icon: const Icon(AppIcons.gavel, size: 16),
                      label: const Text('Создать клан'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5C542),
                        foregroundColor: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Available clans to join
            if (game.clanLeaderboard.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Доступные кланы', style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...game.clanLeaderboard.take(5).map((clan) => _ClanJoinCard(
                clan: clan, game: game, companyId: companyId,
              )),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => _CreateClanDialog(game: game, companyId: companyId));
  }
}

// ===== CLAN JOIN CARD =====
class _ClanJoinCard extends StatelessWidget {
  final Map<String, dynamic> clan;
  final GameProvider game;
  final String companyId;
  const _ClanJoinCard({required this.clan, required this.game, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final name = clan['clan_name'] as String? ?? '???';
    final tag = clan['clan_tag'] as String? ?? '???';
    final memberCount = (clan['member_count'] as num?)?.toInt() ?? 0;
    final totalMoney = (clan['total_money'] as num?)?.toInt() ?? 0;
    final leaderName = clan['leader_name'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFCE93D8).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCE93D8).withOpacity(0.3)),
            ),
            child: const Icon(AppIcons.shield, color: Color(0xFFCE93D8), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFFF5C542).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text(tag, style: const TextStyle(color: Color(0xFFF5C542), fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('$memberCount уч.', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                    const SizedBox(width: 12),
                    Text(GameConstants.formatMoney(totalMoney), style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: ElevatedButton(
              onPressed: () => _join(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66BB6A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: const Text('Вступить', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _join(BuildContext context) async {
    final clanId = clan['clan_id'] as String?;
    if (clanId == null) return;
    final ok = await game.joinClan(companyId, clanId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Вы вступили в клан!' : game.error ?? 'Ошибка'),
        backgroundColor: ok ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ===== CREATE CLAN DIALOG =====
class _CreateClanDialog extends StatefulWidget {
  final GameProvider game;
  final String companyId;
  const _CreateClanDialog({required this.game, required this.companyId});

  @override
  State<_CreateClanDialog> createState() => _CreateClanDialogState();
}

class _CreateClanDialogState extends State<_CreateClanDialog> {
  final _nameCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() { _nameCtrl.dispose(); _tagCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final canCreate = _nameCtrl.text.trim().isNotEmpty &&
        _tagCtrl.text.trim().isNotEmpty &&
        _tagCtrl.text.trim().length >= 2 && _tagCtrl.text.trim().length <= 5;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
      child: Container(
        width: 440,
        constraints: const BoxConstraints(maxHeight: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const Icon(AppIcons.shield, color: Color(0xFFF5C542), size: 22),
                const SizedBox(width: 10),
                Text('Создать клан', style: AppTheme.h2.copyWith(color: const Color(0xFFD0D0D0))),
                const Spacer(),
                Text(GameConstants.formatMoney(GameConstants.clanCreateCost), style: AppTheme.mono.copyWith(color: const Color(0xFF66BB6A), fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Color(0xFFD0D0D0)),
                decoration: const InputDecoration(
                  labelText: 'Название клана',
                  labelStyle: TextStyle(color: Color(0xFF888888)),
                  hintStyle: TextStyle(color: Color(0xFF666666)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagCtrl,
                style: const TextStyle(color: Color(0xFFD0D0D0)),
                textCapitalization: TextCapitalization.characters,
                maxLength: 5,
                decoration: const InputDecoration(
                  labelText: 'Тег (2-5 символов)',
                  labelStyle: TextStyle(color: Color(0xFF888888)),
                  hintStyle: TextStyle(color: Color(0xFF666666)),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                style: const TextStyle(color: Color(0xFFD0D0D0)),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  labelStyle: TextStyle(color: Color(0xFF888888)),
                  hintStyle: TextStyle(color: Color(0xFF666666)),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canCreate && !_isCreating ? () => _create() : null,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5C542), foregroundColor: const Color(0xFF1A1A1A)),
                  child: _isCreating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF1A1A1A), strokeWidth: 2))
                      : const Text('Создать за €50K', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _create() async {
    setState(() { _isCreating = true; _error = null; });
    final ok = await widget.game.createClan(
      widget.companyId,
      _nameCtrl.text.trim(),
      _tagCtrl.text.trim(),
      _descCtrl.text.trim(),
    );
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Клан создан!'),
          backgroundColor: Color(0xFF66BB6A),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        setState(() => _error = widget.game.error ?? 'Ошибка');
      }
    }
  }
}

// ===== CLAN DETAIL VIEW =====
class _ClanDetailView extends StatelessWidget {
  final GameProvider game;
  final String companyId;
  const _ClanDetailView({required this.game, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final clan = game.myClan;
    if (clan == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clan header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(color: Color(0xFF252525)),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C542).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF5C542).withOpacity(0.35)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(AppIcons.shield, color: Color(0xFFF5C542), size: 22),
                    Text(clan.tag, style: const TextStyle(color: Color(0xFFF5C542), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: Text(clan.name, style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 16, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFF5C542).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text('Lv.${clan.level}', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(clan.description.isNotEmpty ? clan.description : 'Без описания', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: const Color(0xFF1E1E1E),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat(AppIcons.users, '${game.clanMembers.length}', 'Участников'),
              _miniStat(AppIcons.star, '${clan.xp}', 'XP'),
              _miniStat(AppIcons.shield, '${clan.maxMembers}', 'Макс.'),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF3A3A3A)),
        // Members header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              const Text('Участники', style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (game.canManageClan || game.isClanLeader)
                TextButton.icon(
                  onPressed: () => _showLeaveConfirm(context),
                  icon: const Icon(AppIcons.logOut, color: Color(0xFFEF5350), size: 14),
                  label: const Text('Покинуть', style: TextStyle(color: Color(0xFFEF5350), fontSize: 11)),
                ),
            ],
          ),
        ),
        // Members list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            itemCount: game.clanMembers.length + 1, // +1 for chat section header
            itemBuilder: (context, i) {
              if (i == game.clanMembers.length) {
                return _ClanChatSection(game: game, companyId: companyId);
              }
              return _MemberCard(
                member: game.clanMembers[i],
                game: game,
                companyId: companyId,
                isMe: game.clanMembers[i].companyId == companyId,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _miniStat(IconData icon, String value, String label) => Column(
    children: [
      Icon(icon, size: 16, color: const Color(0xFFF5C542)),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(color: Color(0xFFD0D0D0), fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'monospace')),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Color(0xFF666666), fontSize: 10)),
    ],
  );

  void _showLeaveConfirm(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
      title: const Text('Покинуть клан?', style: TextStyle(color: Color(0xFFD0D0D0))),
      content: const Text('Вы уверены?', style: TextStyle(color: Color(0xFF888888))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888)))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Покинуть', style: TextStyle(color: Color(0xFFEF5350)))),
      ],
    )).then((confirmed) async {
      if (confirmed == true) {
        final ok = await game.leaveClan(companyId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok ? 'Вы покинули клан' : game.error ?? 'Ошибка'),
            backgroundColor: ok ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    });
  }
}

// ===== CLAN CHAT SECTION =====
class _ClanChatSection extends StatefulWidget {
  final GameProvider game;
  final String companyId;
  const _ClanChatSection({required this.game, required this.companyId});

  @override
  State<_ClanChatSection> createState() => _ClanChatSectionState();
}

class _ClanChatSectionState extends State<_ClanChatSection> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    final ok = await widget.game.sendClanMessage(widget.companyId, text);
    if (ok) {
      _msgCtrl.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.game.clanMessages;
    final isMe = (ChatMessage msg) => msg.companyId == widget.companyId;

    return Column(
      children: [
        // Chat header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(
            children: [
              const Icon(AppIcons.chatOutline, color: Color(0xFF42A5F5), size: 16),
              const SizedBox(width: 8),
              const Text('Чат клана', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${messages.length} сообщ.', style: const TextStyle(color: Color(0xFF666666), fontSize: 11)),
            ],
          ),
        ),
        // Messages list (reversed: newest at top, scroll up for older)
        if (messages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Пока нет сообщений', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
          )
        else
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border(top: BorderSide(color: Color(0xFF3A3A3A))),
            ),
            child: ListView.builder(
              controller: _scrollCtrl,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                final own = isMe(msg);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: own ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!own) ...[
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF42A5F5).withOpacity(0.15),
                          child: const Icon(AppIcons.person, color: Color(0xFF42A5F5), size: 14),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: own ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!own)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(msg.senderName ?? '???', style: const TextStyle(color: Color(0xFF42A5F5), fontSize: 10, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 6),
                                    Text(msg.timeAgo, style: const TextStyle(color: Color(0xFF555555), fontSize: 9)),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                              decoration: BoxDecoration(
                                color: own
                                    ? const Color(0xFFF5C542).withOpacity(0.15)
                                    : const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(10),
                                  topRight: const Radius.circular(10),
                                  bottomLeft: Radius.circular(own ? 10 : 2),
                                  bottomRight: Radius.circular(own ? 2 : 10),
                                ),
                                border: Border.all(
                                  color: own
                                      ? const Color(0xFFF5C542).withOpacity(0.3)
                                      : const Color(0xFF3A3A3A),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: own ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(msg.content, style: TextStyle(color: own ? const Color(0xFFF5C542) : const Color(0xFFD0D0D0), fontSize: 12)),
                                  if (own)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(msg.timeAgo, style: const TextStyle(color: Color(0xFF888866), fontSize: 9)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (own) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFF5C542).withOpacity(0.15),
                          child: const Icon(AppIcons.person, color: Color(0xFFF5C542), size: 14),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        // Input
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFF252525),
            border: Border(top: BorderSide(color: Color(0xFF3A3A3A))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  style: const TextStyle(color: Color(0xFFD0D0D0), fontSize: 13),
                  maxLength: 500,
                  maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
                  decoration: const InputDecoration(
                    hintText: 'Написать сообщение...',
                    hintStyle: TextStyle(color: Color(0xFF666666), fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF3A3A3A)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF3A3A3A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF42A5F5)),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: Color(0xFF1E1E1E),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                height: 36,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF42A5F5),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(AppIcons.send, size: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===== MEMBER CARD =====
class _MemberCard extends StatelessWidget {
  final ClanMember member;
  final GameProvider game;
  final String companyId;
  final bool isMe;

  const _MemberCard({required this.member, required this.game, required this.companyId, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final roleColor = Color(int.parse(member.roleColorHex));

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFF5C542).withOpacity(0.05) : const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isMe ? const Color(0xFFF5C542).withOpacity(0.3) : const Color(0xFF3A3A3A)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: roleColor.withOpacity(0.15),
            child: Icon(AppIcons.person, color: roleColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(member.companyName ?? '???', style: TextStyle(color: const Color(0xFFD0D0D0), fontSize: 13, fontWeight: isMe ? FontWeight.w700 : FontWeight.w600), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    if (isMe)
                      const Text('(вы)', style: TextStyle(color: Color(0xFFF5C542), fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: roleColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text(member.roleDisplay, style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    if (member.companyLevel != null) Text('Ур. ${member.companyLevel}', style: const TextStyle(color: Color(0xFFFF9800), fontSize: 11)),
                    const SizedBox(width: 8),
                    if (member.truckCount != null) Text('${member.truckCount} 🚛', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          // Actions (can't manage self or leader)
          if (!isMe && game.canManageClan && !member.isLeader)
            PopupMenuButton<String>(
              icon: const Icon(AppIcons.more, color: Color(0xFF888888), size: 18),
              color: const Color(0xFF2C2C2C),
              onSelected: (value) => _handleAction(context, value),
              itemBuilder: (context) => [
                if (game.isClanLeader && member.isOfficer)
                  const PopupMenuItem(value: 'demote', child: Text('Понизить до участника', style: TextStyle(color: Color(0xFF888888)))),
                if (game.isClanLeader && !member.isOfficer)
                  const PopupMenuItem(value: 'promote', child: Text('Повысить до офицера', style: TextStyle(color: Color(0xFF42A5F5)))),
                const PopupMenuItem(value: 'kick', child: Text('Исключить', style: TextStyle(color: Color(0xFFEF5350)))),
              ],
            ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) async {
    bool ok = false;
    switch (action) {
      case 'promote':
        ok = await game.promoteMember(companyId, member.companyId, 'officer');
        break;
      case 'demote':
        ok = await game.promoteMember(companyId, member.companyId, 'member');
        break;
      case 'kick':
        final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF444444))),
          title: Text('Исключить ${member.companyName ?? ''}?', style: const TextStyle(color: Color(0xFFD0D0D0))),
          content: const Text('Участник будет удалён из клана.', style: TextStyle(color: Color(0xFF888888))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена', style: TextStyle(color: Color(0xFF888888)))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Исключить', style: TextStyle(color: Color(0xFFEF5350)))),
          ],
        ));
        if (confirm == true) ok = await game.kickClanMember(companyId, member.companyId);
        break;
    }
    if (context.mounted && !ok && game.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(game.error!), backgroundColor: const Color(0xFFEF5350), behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ===== CLAN MISSIONS TAB =====
class _ClanMissionsTab extends StatelessWidget {
  final GameProvider game;
  final String companyId;
  const _ClanMissionsTab({required this.game, required this.companyId});

  @override
  Widget build(BuildContext context) {
    if (!game.isInClan) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.shield, size: 48, color: Color(0xFF666666)),
            const SizedBox(height: 12),
            Text('Вступите в клан', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
            const SizedBox(height: 4),
            const Text('Миссии доступны только членам клана', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
          ],
        ),
      );
    }

    final missions = game.clanMissions;

    return Column(
      children: [
        // Generate button
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: Row(
            children: [
              const Icon(AppIcons.assignmentOutlined, color: Color(0xFFF5C542), size: 16),
              const SizedBox(width: 8),
              const Text('Клановые миссии', style: TextStyle(color: Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => game.generateClanMissions(),
                icon: const Icon(AppIcons.refreshCw, size: 14),
                label: const Text('Сгенерировать', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF5C542),
                  side: const BorderSide(color: Color(0xFFF5C542).withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF3A3A3A)),
        // Missions list
        Expanded(
          child: missions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(AppIcons.inventory2, size: 48, color: Color(0xFF666666)),
                      const SizedBox(height: 12),
                      const Text('Нет активных миссий', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text('Нажмите «Сгенерировать» для новых заданий', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: missions.length,
                  itemBuilder: (context, i) => _MissionCard(mission: missions[i]),
                ),
        ),
      ],
    );
  }
}

// ===== MISSION CARD =====
class _MissionCard extends StatelessWidget {
  final ClanMission mission;
  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final pct = mission.progressPercent;
    final pctText = '${(pct * 100).toStringAsFixed(0)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mission.completed ? const Color(0xFF66BB6A).withOpacity(0.05) : const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: mission.completed
              ? const Color(0xFF66BB6A).withOpacity(0.4)
              : mission.isExpired
                  ? const Color(0xFFEF5350).withOpacity(0.3)
                  : const Color(0xFF3A3A3A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: icon + title + type badge + time
          Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: mission.progressColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(mission.missionIcon, color: mission.progressColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            mission.title,
                            style: TextStyle(
                              color: mission.completed ? const Color(0xFF66BB6A) : const Color(0xFFD0D0D0),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: mission.completed ? TextDecoration.lineThrough : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCE93D8).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(mission.typeLabel, style: const TextStyle(color: Color(0xFFCE93D8), fontSize: 9, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (mission.description.isNotEmpty)
                      Text(mission.description, style: const TextStyle(color: Color(0xFF888888), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    mission.timeLeft,
                    style: TextStyle(
                      color: mission.isExpired ? const Color(0xFFEF5350) : mission.completed ? const Color(0xFF66BB6A) : const Color(0xFF888888),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (mission.completed)
                    const Text('✓ Выполнено', style: TextStyle(color: Color(0xFF66BB6A), fontSize: 9, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: const Color(0xFF333333),
                    valueColor: AlwaysStoppedAnimation(mission.progressColor),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                child: Text(
                  '$pctText ${mission.progressText}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: mission.completed ? const Color(0xFF66BB6A) : const Color(0xFFD0D0D0),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Rewards
          Row(
            children: [
              if (mission.rewardXp > 0) ...[
                const Icon(AppIcons.star, color: Color(0xFFF5C542), size: 13),
                const SizedBox(width: 3),
                Text('+${mission.rewardXp} XP', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
              if (mission.rewardXp > 0 && mission.rewardMoney > 0)
                const SizedBox(width: 12),
              if (mission.rewardMoney > 0) ...[
                const Icon(AppIcons.euro, color: Color(0xFF66BB6A), size: 13),
                const SizedBox(width: 3),
                Text(GameConstants.formatMoney(mission.rewardMoney), style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ===== CLAN LEADERBOARD TAB =====
class _ClanLeaderboardTab extends StatelessWidget {
  final GameProvider game;
  const _ClanLeaderboardTab({required this.game});

  @override
  Widget build(BuildContext context) {
    final clans = game.clanLeaderboard;

    if (clans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.leaderboard, size: 48, color: Color(0xFF666666)),
            const SizedBox(height: 12),
            Text('Нет кланов', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
            const SizedBox(height: 4),
            const Text('Создайте первый клан!', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: clans.length,
      itemBuilder: (context, i) {
        final clan = clans[i];
        final isMyClan = game.myClan != null && clan['clan_id'] == game.myClan!.id;
        final rank = i + 1;

        Color medalColor;
        if (rank == 1) medalColor = const Color(0xFFFFC107);
        else if (rank == 2) medalColor = const Color(0xFFB0BEC5);
        else if (rank == 3) medalColor = const Color(0xFFCD7F32);
        else medalColor = const Color(0xFF888888);

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMyClan ? const Color(0xFFF5C542).withOpacity(0.05) : const Color(0xFF252525),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isMyClan ? const Color(0xFFF5C542).withOpacity(0.4) : const Color(0xFF3A3A3A)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text('$rank', textAlign: TextAlign.center, style: TextStyle(
                  color: medalColor, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace',
                )),
              ),
              const SizedBox(width: 10),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: medalColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(AppIcons.shield, color: medalColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: Text(clan['clan_name'] as String? ?? '???', style: TextStyle(color: isMyClan ? const Color(0xFFF5C542) : const Color(0xFFD0D0D0), fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: const Color(0xFFF5C542).withOpacity(0.15), borderRadius: BorderRadius.circular(3)),
                        child: Text(clan['clan_tag'] as String? ?? '??', style: const TextStyle(color: Color(0xFFF5C542), fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      '${(clan['member_count'] as num?)?.toInt() ?? 0} уч.  •  Ср. ур. ${((clan['avg_level'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}',
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                GameConstants.formatMoney((clan['total_money'] as num?)?.toInt() ?? 0),
                style: const TextStyle(color: Color(0xFF66BB6A), fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
              ),
            ],
          ),
        );
      },
    );
  }
}