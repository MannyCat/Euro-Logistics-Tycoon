import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';

class MoneyDisplay extends StatelessWidget {
  final int amount;
  final double? fontSize;
  final bool showSign;
  final FontWeight? fontWeight;

  const MoneyDisplay({
    super.key,
    required this.amount,
    this.fontSize,
    this.showSign = false,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'en_US',
    );
    final formatted = formatter.format(amount.abs());
    final prefix = showSign ? (amount >= 0 ? '+' : '-') : (amount < 0 ? '-' : '');
    final finalText = amount < 0 ? '$prefix$formatted' : (showSign ? '$prefix$formatted' : formatted);

    Color color;
    if (amount > 0) {
      color = AppTheme.profitGreen;
    } else if (amount < 0) {
      color = AppTheme.lossRed;
    } else {
      color = AppTheme.textWhite;
    }

    return Text(
      finalText,
      style: (fontSize != null && fontSize! > 18
              ? AppTheme.monoNumberLarge
              : AppTheme.monoNumber)
          .copyWith(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
