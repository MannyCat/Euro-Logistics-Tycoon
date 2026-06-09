import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../models/event_log.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/ets2_modal.dart';
import '../config/app_icons.dart';

class EventLogScreen extends StatefulWidget {
  const EventLogScreen({super.key});
  @override
  State<EventLogScreen> createState() => _EventLogScreenState();
}

class _EventLogScreenState extends State<EventLogScreen> {
  List<EventLog> _events = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _activeFilter = 'Все'; // 'Все', 'Финансы', 'Флот', 'Водители', 'Кланы'

  static const _filters = ['Все', 'Финансы', 'Флот', 'Водители', 'Кланы'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEvents());
  }

  Future<void> _loadEvents() async {
    final auth = context.read<AuthProvider>();
    final companyId = auth.companyId;
    if (companyId == null) return;
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final resp = await Supabase.instance.client
          .from('event_log')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false)
          .limit(50);
      _events = resp.map<EventLog>((e) => EventLog.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Load event log error: $e');
      setState(() => _hasError = true);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<EventLog> get _filteredEvents {
    return _events.where((e) {
      switch (_activeFilter) {
        case 'Финансы':
          return e.isFinance;
        case 'Флот':
          return e.isFleet;
        case 'Водители':
          return e.isDrivers;
        case 'Кланы':
          return e.isClan;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ETS2Modal(
      title: 'Журнал событий',
      icon: AppIcons.eventLog,
      actions: [
        IconButton(
          icon: const Icon(AppIcons.refreshCw, color: Color(0xFF999999), size: 18),
          tooltip: 'Обновить',
          onPressed: _loadEvents,
        ),
      ],
      child: Column(
        children: [
          // Filter tabs
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: _filters.map((filter) {
                final isActive = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isActive ? const Color(0xFF1A1A1A) : const Color(0xFF999999),
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    selected: isActive,
                    selectedColor: const Color(0xFFF5C542),
                    backgroundColor: const Color(0xFF2C2C2C),
                    side: BorderSide(
                      color: isActive ? const Color(0xFFF5C542) : const Color(0xFF444444),
                      width: 0.5,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onSelected: (_) => setState(() => _activeFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: Color(0xFF3A3A3A)),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF5C542)))
                : _hasError
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(AppIcons.warning, size: 48, color: Color(0xFFEF5350)),
                            const SizedBox(height: 12),
                            Text('Ошибка загрузки', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
                            const SizedBox(height: 4),
                            const Text('Проверьте подключение и попробуйте снова', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadEvents,
                              icon: const Icon(AppIcons.refreshCw),
                              label: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _filteredEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(AppIcons.eventLog, size: 48, color: Color(0xFF666666)),
                                const SizedBox(height: 12),
                                Text('Пока нет событий', style: AppTheme.h2.copyWith(color: const Color(0xFFAAAAAA))),
                                const SizedBox(height: 4),
                                const Text('Совершайте действия, чтобы увидеть журнал', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredEvents.length,
                            itemBuilder: (context, i) => _EventCard(event: _filteredEvents[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventLog event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    // Determine card border color
    Color borderColor = const Color(0xFF3A3A3A);
    if (event.isAchievement) borderColor = const Color(0xFFF5C542);
    if (event.isWarning) borderColor = const Color(0xFFEF5350);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: event.isAchievement || event.isWarning ? 1.5 : 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(event.icon, color: event.color, size: 20),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          color: Color(0xFFD0D0D0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (event.moneyAmount != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (event.moneyAmount! >= 0
                              ? const Color(0xFF66BB6A)
                              : const Color(0xFFEF5350))
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: event.moneyAmount! >= 0
                                ? const Color(0xFF66BB6A).withOpacity(0.4)
                                : const Color(0xFFEF5350).withOpacity(0.4),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          '${event.moneyAmount! >= 0 ? '+' : ''}${GameConstants.formatMoney(event.moneyAmount!)}',
                          style: TextStyle(
                            color: event.moneyAmount! >= 0
                                ? const Color(0xFF66BB6A)
                                : const Color(0xFFEF5350),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    event.description,
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  event.timeAgo,
                  style: const TextStyle(color: Color(0xFF666666), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
