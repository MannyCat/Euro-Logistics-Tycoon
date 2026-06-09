import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_icons.dart';
import '../../providers/auth_provider.dart';

/// ETS2-style splash screen — shows while session is being restored.
/// If session exists → auto-login to map. If not → redirect to login.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Once loading is done, the router redirect handles navigation.
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ETS2-style logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF5C542).withOpacity(0.08),
                border: Border.all(
                  color: const Color(0xFFF5C542).withOpacity(0.25),
                  width: 2,
                ),
              ),
              child: const Icon(
                AppIcons.truck,
                size: 44,
                color: Color(0xFFF5C542),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'EURO LOGISTICS\nTYCOON',
              textAlign: TextAlign.center,
              style: AppTheme.h1.copyWith(
                color: const Color(0xFFD0D0D0),
                letterSpacing: 4,
                fontSize: 26,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Постройте логистическую империю',
              style: AppTheme.bodySm.copyWith(
                color: const Color(0xFF666666),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: const Color(0xFFF5C542).withOpacity(0.7),
                backgroundColor: const Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),
            if (auth.isLoading)
              Text(
                'Восстановление сессии...',
                style: AppTheme.bodySm.copyWith(
                  color: const Color(0xFF666666),
                  fontSize: 11,
                ),
              )
            else
              Text(
                auth.isAuthenticated ? 'Вход выполнен' : 'Войдите в аккаунт',
                style: AppTheme.bodySm.copyWith(
                  color: const Color(0xFF666666),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
