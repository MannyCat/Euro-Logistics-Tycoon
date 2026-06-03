import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';
import '../providers/game_provider.dart';

class PortsScreen extends StatefulWidget {
  const PortsScreen({super.key});

  @override
  State<PortsScreen> createState() => _PortsScreenState();
}

class _PortsScreenState extends State<PortsScreen> {
  String _searchQuery = '';
  String _selectedRegion = 'Все';
  List<String> _regions = ['Все'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final game = context.read<GameProvider>();
    game.loadPorts();
    _regions = ['Все', ...GameConstants.allRegions];
    if (mounted) setState(() {});
  }

  List<PortDefinition> _getFilteredPorts() {
    var ports = GameConstants.ports;

    if (_selectedRegion != 'Все') {
      ports = ports.where((p) => p.region == _selectedRegion).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      ports = ports
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              p.country.toLowerCase().contains(query))
          .toList();
    }

    return ports;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredPorts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Порты'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Поиск порта...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  style: AppTheme.bodyText,
                ),
              ),
              // Region filter chips
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _regions.map((region) {
                    final isSelected = _selectedRegion == region;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          region,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textGrayLight,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedRegion = region;
                          });
                        },
                        backgroundColor: AppTheme.inputBackground,
                        selectedColor: AppTheme.accentBlue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 0),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.anchor_outlined,
                      size: 48, color: Color(0xFF4A4A6A)),
                  const SizedBox(height: 12),
                  Text(
                    'Порты не найдены',
                    style: AppTheme.bodyText,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: filtered.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final port = filtered[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.go('/ports/${port.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.accentBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.anchor,
                              color: AppTheme.accentBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  port.name,
                                  style: AppTheme.labelMedium,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${port.country}  •  ${port.region}',
                                      style: AppTheme.bodyTextSmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (port.hasFuel)
                                    const Icon(Icons.local_gas_station,
                                        size: 14, color: AppTheme.profitGreen)
                                  else
                                    const Icon(Icons.local_gas_station,
                                        size: 14, color: Color(0xFF4A4A6A)),
                                  const SizedBox(width: 6),
                                  if (port.hasDock)
                                    const Icon(Icons.build,
                                        size: 14, color: AppTheme.accentBlue)
                                  else
                                    const Icon(Icons.build,
                                        size: 14, color: Color(0xFF4A4A6A)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Налог ${(port.taxRate * 100).toStringAsFixed(0)}%',
                                style: AppTheme.monoNumberSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
