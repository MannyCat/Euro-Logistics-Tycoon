import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSub;
  String? _userId;
  String? _companyId;
  bool _isLoading = true;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _userId;
  String? get companyId => _companyId;
  bool get isAuthenticated => _userId != null && _companyId != null;

  AuthProvider() {
    _restoreSession();
    _authSub = _supabase.auth.onAuthStateChange.listen(_onAuthState);
  }

  Future<void> _restoreSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _userId = session.user.id;
        await _loadCompany();
      }
    } catch (e) {
      debugPrint('Session restore error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void _onAuthState(AuthState state) async {
    if (state.event == AuthChangeEvent.signedIn && state.session != null) {
      _userId = state.session!.user.id;
      await _loadCompany();
    } else if (state.event == AuthChangeEvent.signedOut) {
      _userId = null;
      _companyId = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCompany() async {
    if (_userId == null) return;
    try {
      final resp = await _supabase.from('companies').select('id').eq('owner_id', _userId!).maybeSingle();
      _companyId = resp?['id'] as String?;
      if (_companyId == null) {
        // Trigger should auto-create, but fallback
        await _supabase.from('companies').insert({
          'owner_id': _userId,
          'name': 'New Logistics Co.',
          'money': 1000000,
        });
        final newResp = await _supabase.from('companies').select('id').eq('owner_id', _userId!).maybeSingle();
        _companyId = newResp?['id'] as String?;
      }
    } catch (e) {
      debugPrint('Load company error: $e');
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final resp = await _supabase.auth.signInWithPassword(email: email.trim(), password: password);
      // After successful login, wait for auth state change to set companyId
      if (resp.session != null) {
        _userId = resp.session!.user.id;
        await _loadCompany();
      }
      return _companyId != null;
    } on AuthException catch (e) {
      _error = e.message.contains('Invalid') ? 'Неверный email или пароль' : e.message;
      return false;
    } catch (e) {
      _error = 'Ошибка подключения';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String companyName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'company_name': companyName.trim()},
      );
      // Wait for session then create company + starter truck from Flutter
      await Future.delayed(const Duration(seconds: 1));
      final session = _supabase.auth.currentSession;
      if (session != null) {
        _userId = session.user.id;
        await _createCompanyAndTruck(companyName.trim());
      }
      return true;
    } on AuthException catch (e) {
      if (e.message.contains('already')) {
        _error = 'Email уже зарегистрирован';
      } else if (e.message.contains('password')) {
        _error = 'Пароль слишком простой (мин. 6 символов)';
      } else {
        _error = e.message;
      }
      return false;
    } catch (e) {
      _error = 'Ошибка подключения';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> _createCompanyAndTruck(String companyName) async {
    if (_userId == null) return;
    try {
      // Check if company already exists
      final existing = await _supabase.from('companies').select('id').eq('owner_id', _userId!).maybeSingle();
      if (existing != null) {
        _companyId = existing['id'] as String?;
        return;
      }
      // Create company
      await _supabase.from('companies').insert({
        'owner_id': _userId,
        'name': companyName,
        'money': 1000000,
      });
      final comp = await _supabase.from('companies').select('id').eq('owner_id', _userId!).maybeSingle();
      _companyId = comp?['id'] as String?;
      if (_companyId != null) {
        // Create starter truck in London
        await _supabase.from('trucks').insert({
          'company_id': _companyId,
          'truck_type': 'light',
          'name': 'Starter Truck',
          'status': 'idle',
          'condition_pct': 100,
          'fuel_level': 100.0,
          'max_fuel': 120.0,
          'current_city_id': 1,
          'purchase_price': 0,
        });
      }
    } catch (e) {
      debugPrint('Create company error: $e');
    }
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }

  @override
  void dispose() { _authSub?.cancel(); super.dispose(); }
}
