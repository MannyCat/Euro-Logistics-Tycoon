import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../config/game_constants.dart';

class ShipCard extends StatelessWidget {
  final String name;
  final String shipTypeId;
  final String status;
  final int condition;
  final double fuelLevel;
  final double maxFuel;
  final String? currentPortId;
  final VoidCallback? onTap;

  const ShipCard({
    super.key,
    required this.name,
    required this.shipTypeId,
    required this.status,
    required this.condition,
    required this.fuelLevel,
    required this.maxFuel,
    this.currentPortId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shipType = GameConstants.findShipType(shipTypeId);
    final port = currentPortId != null
        ? GameConstants.findPort(currentPortId!)
        : null;
    final fuelPercent = maxFuel > 0 ? (fuelLevel / maxFuel * 100).clamp(0, 100) : 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor(status),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Ship info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: AppTheme.labelMedium,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: AppTheme.bodyTextSmall.copyWith(
                              color: _statusColor(status),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          shipType?.name ?? shipTypeId,
                          style: AppTheme.bodyTextSmall,
                        ),
                        if (port != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '📍 ${port.name}',
                            style: AppTheme.bodyTextSmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Stats column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${condition}%',
                    style: AppTheme.monoNumberSmall.copyWith(
                      color: condition > 60
                          ? AppTheme.profitGreen
                          : condition > 30
                              ? AppTheme.warningAmber
                              : AppTheme.lossRed,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '⛽ ${fuelPercent.toStringAsFixed(0)}%',
                    style: AppTheme.monoNumberSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'idle':
        return AppTheme.profitGreen;
      case 'in_transit':
        return AppTheme.accentBlue;
      case 'in_dock':
        return AppTheme.warningAmber;
      case 'maintenance':
        return AppTheme.lossRed;
      case 'on_market':
        return const Color(0xFF9C27B0);
      default:
        return AppTheme.textGray;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'idle':
        return 'Готов';
      case 'in_transit':
        return 'В рейсе';
      case 'in_dock':
        return 'В доке';
      case 'maintenance':
        return 'Ремонт';
      case 'on_market':
        return 'Продажа';
      default:
        return status;
    }
  }
}
