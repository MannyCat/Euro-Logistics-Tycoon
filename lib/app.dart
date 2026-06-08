import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/map_screen.dart';
import 'screens/fleet_screen.dart';
import 'screens/contracts_screen.dart';
import 'screens/drivers_screen.dart';
import 'screens/warehouses_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/settings_screen.dart';

/// A simple Listenable that GoRouter can listen to for auth state changes.
class _AuthNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class ELTApp extends StatefulWidget {
  const ELTApp({super.key});

  @override
  State<ELTApp> createState() => _ELTAppState();
}

class _ELTAppState extends State<ELTApp> {
  final AuthProvider _authProvider = AuthProvider();
  final GameProvider _gameProvider = GameProvider();
  final _authNotifier = _AuthNotifier();
  bool _startedGameInit = false;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();

    // Create router with refreshListenable tied to auth state
    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: _authNotifier,
      redirect: _redirect,
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/', builder: (_, __) => const MapScreen()),
        GoRoute(path: '/contracts', builder: (_, __) => const ContractsScreen()),
        GoRoute(path: '/fleet', builder: (_, __) => const FleetScreen()),
        GoRoute(path: '/drivers', builder: (_, __) => const DriversScreen()),
        GoRoute(path: '/warehouses', builder: (_, __) => const WarehousesScreen()),
        GoRoute(
            path: '/transactions',
            builder: (_, __) => const TransactionsScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    );

    // Listen to auth changes — notify router + start game
    _authProvider.addListener(_onAuthChanged);
  }

  /// Router redirect logic — called on every navigation and auth state change.
  String? _redirect(BuildContext context, GoRouterState state) {
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    final isSplash = state.matchedLocation == '/splash';
    final isLoading = _authProvider.isLoading;
    final isAuthenticated = _authProvider.isAuthenticated;

    // Stay on splash while session is being restored
    if (isSplash && isLoading) return null;

    // Splash done: redirect based on auth state
    if (isSplash) {
      return isAuthenticated ? '/' : '/login';
    }

    // If not authenticated and not on auth routes → login
    if (!isAuthenticated && !isAuthRoute) return '/login';

    // If authenticated and on auth routes → map
    if (isAuthenticated && isAuthRoute) return '/';

    return null;
  }

  void _onAuthChanged() {
    // Notify GoRouter to re-evaluate redirects
    _authNotifier.notify();

    // Start/stop game data loading
    if (_authProvider.isAuthenticated && !_startedGameInit) {
      _startedGameInit = true;
      _gameProvider.startRealtime();
      _gameProvider.loadAll(_authProvider.companyId!);
    }
    if (!_authProvider.isAuthenticated) {
      _startedGameInit = false;
      _gameProvider.stopRealtime();
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    _authProvider.dispose();
    _gameProvider.dispose();
    _authNotifier.dispose();
    super.dispose();
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
