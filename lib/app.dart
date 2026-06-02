import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'config/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ports_screen.dart';
import 'screens/port_detail_screen.dart';
import 'screens/fleet_screen.dart';
import 'screens/ship_detail_screen.dart';
import 'screens/voyages_screen.dart';
import 'screens/market_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/production_screen.dart';
import 'screens/personnel_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/navigation_shell.dart';

late final GoRouter _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    if (!auth.isAuthenticated && !isAuthRoute) {
      return '/login';
    }
    if (auth.isAuthenticated && isAuthRoute) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => NavigationShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/ports',
          builder: (context, state) => const PortsScreen(),
        ),
        GoRoute(
          path: '/ports/:id',
          builder: (context, state) {
            final portId = state.pathParameters['id'] ?? '';
            return PortDetailScreen(portId: portId);
          },
        ),
        GoRoute(
          path: '/fleet',
          builder: (context, state) => const FleetScreen(),
        ),
        GoRoute(
          path: '/fleet/:id',
          builder: (context, state) {
            final shipId = state.pathParameters['id'] ?? '';
            return ShipDetailScreen(shipId: shipId);
          },
        ),
        GoRoute(
          path: '/market',
          builder: (context, state) => const ShipMarketScreen(),
        ),
        GoRoute(
          path: '/voyages',
          builder: (context, state) => const VoyagesScreen(),
        ),
        GoRoute(
          path: '/finance',
          builder: (context, state) => const FinanceScreen(),
        ),
        GoRoute(
          path: '/production',
          builder: (context, state) => const ProductionScreen(),
        ),
        GoRoute(
          path: '/personnel',
          builder: (context, state) => const PersonnelScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

class ShippingManagerApp extends StatelessWidget {
  const ShippingManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MaterialApp.router(
        title: 'Shipping Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}
