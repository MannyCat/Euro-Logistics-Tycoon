import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/map_screen.dart';
import 'screens/fleet_screen.dart';
import 'screens/contracts_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/settings_screen.dart';

late final GoRouter _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
    if (!auth.isAuthenticated && !isAuthRoute) return '/login';
    if (auth.isAuthenticated && isAuthRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/', builder: (_, __) => const MapScreen()),
    GoRoute(path: '/contracts', builder: (_, __) => const ContractsScreen()),
    GoRoute(path: '/fleet', builder: (_, __) => const FleetScreen()),
    GoRoute(path: '/drivers', builder: (_, __) => const DriversScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);

class ELTApp extends StatelessWidget {
  const ELTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MaterialApp.router(
        title: 'Euro Logistics Tycoon',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: _router,
      ),
    );
  }
}
