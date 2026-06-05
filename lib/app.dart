import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
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
  initialLocation: '/login',
  redirect: (context, state) {
    final authProvider = context.read<AuthProvider>();

    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
    final isLoading = authProvider.isLoading;
    final isAuthenticated = authProvider.isAuthenticated;

    // While loading session, show nothing (stay on splash/loading)
    if (isLoading && !isAuthRoute) {
      return '/login'; // Will be replaced once auth state resolves
    }

    // Not authenticated → go to login
    if (!isAuthenticated && !isAuthRoute) return '/login';
    // Authenticated → redirect away from auth routes
    if (isAuthenticated && isAuthRoute) return '/';
    // Otherwise, no redirect needed
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

class ELTApp extends StatefulWidget {
  const ELTApp({super.key});

  @override
  State<ELTApp> createState() => _ELTAppState();
}

class _ELTAppState extends State<ELTApp> {
  final AuthProvider _authProvider = AuthProvider();
  final GameProvider _gameProvider = GameProvider();
  bool _startedGameInit = false;

  @override
  void initState() {
    super.initState();
    _authProvider.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    _authProvider.dispose();
    _gameProvider.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    // When user becomes authenticated, start realtime and initial load
    if (_authProvider.isAuthenticated && !_startedGameInit) {
      _startedGameInit = true;
      _gameProvider.startRealtime();
      _gameProvider.loadAll(_authProvider.companyId!);
    }
    // When user logs out, stop realtime
    if (!_authProvider.isAuthenticated) {
      _startedGameInit = false;
      _gameProvider.stopRealtime();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<GameProvider>.value(value: _gameProvider),
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
