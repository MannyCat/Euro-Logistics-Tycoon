import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: ListTile(
          leading: const Icon(Icons.info_outline, color: AppTheme.accent),
          title: Text('Euro Logistics Tycoon', style: AppTheme.label),
          subtitle: const Text('Версия 1.0.0 — Прототип', style: AppTheme.bodySm),
        )),
        Card(child: ListTile(
          leading: const Icon(Icons.logout, color: AppTheme.red),
          title: Text('Выйти', style: AppTheme.label.copyWith(color: AppTheme.red)),
          onTap: () async { await auth.logout(); if (context.mounted) Navigator.pop(context); },
        )),
      ]),
    );
  }
}
