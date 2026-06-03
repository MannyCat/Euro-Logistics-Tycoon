import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Theme
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SwitchListTile(
                title: const Text('Тёмная тема'),
                subtitle: const Text('Включена (по умолчанию)'),
                value: true,
                onChanged: null, // Dark only for now
                activeColor: AppTheme.accentBlue,
                secondary: const Icon(Icons.dark_mode_outlined),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Language
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SwitchListTile(
                title: const Text('Язык'),
                subtitle: const Text('Русский (RU)'),
                value: true,
                onChanged: null, // Russian only for now
                activeColor: AppTheme.accentBlue,
                secondary: const Icon(Icons.language),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Notifications placeholder
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SwitchListTile(
                title: const Text('Уведомления о рейсах'),
                subtitle: const Text('Прибытие, задержки, ETA'),
                value: true,
                onChanged: (v) {},
                activeColor: AppTheme.accentBlue,
                secondary:
                    const Icon(Icons.notifications_outlined),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Divider with label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                const Expanded(
                    child: Divider(color: Color(0xFF1E3A5F))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Аккаунт',
                      style: AppTheme.bodyTextSmall),
                ),
                const Expanded(
                    child: Divider(color: Color(0xFF1E3A5F))),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Profile
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.business_outlined,
                  color: AppTheme.accentBlue),
              title: Text('Профиль компании',
                  style: AppTheme.labelMedium),
              subtitle: Text(
                  auth.profile?.companyName ?? 'Загрузка...',
                  style: AppTheme.bodyTextSmall),
              trailing: const Icon(Icons.chevron_right,
                  color: Color(0xFF4A4A6A)),
              onTap: () => context.go('/profile'),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 2),
            ),
          ),

          // Logout
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.logout,
                  color: AppTheme.lossRed),
              title: Text('Выйти из аккаунта',
                  style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.lossRed)),
              onTap: () => _showLogoutDialog(context, auth),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 2),
            ),
          ),

          const SizedBox(height: 24),

          // About
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                const Expanded(
                    child: Divider(color: Color(0xFF1E3A5F))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('О приложении',
                      style: AppTheme.bodyTextSmall),
                ),
                const Expanded(
                    child: Divider(color: Color(0xFF1E3A5F))),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shipping Manager',
                      style: AppTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text('Версия 1.0.0', style: AppTheme.bodyTextSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Экономическая стратегия — менеджер морских перевозок. '
                    'Стройте флот, торгуйте грузами, конкурируйте с другими компаниями.',
                    style: AppTheme.bodyText,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Подтверждение'),
          content: const Text(
              'Вы уверены, что хотите выйти из аккаунта?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                auth.logout();
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lossRed,
              ),
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );
  }
}
