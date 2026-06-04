import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerProfile {
  final String id;
  final String email;
  final String companyName;
  final int money;
  final int reputation;
  final int level;
  final int xp;
  final DateTime createdAt;

  const PlayerProfile({
    required this.id,
    required this.email,
    required this.companyName,
    required this.money,
    required this.reputation,
    required this.level,
    required this.xp,
    required this.createdAt,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    // profiles table does NOT have an email column — it lives in auth.users
    return PlayerProfile(
      id: json['id'] as String? ?? '',
      email: '', // Must be injected separately from Supabase.auth.currentUser?.email
      companyName: json['company_name'] as String? ?? 'Моя компания',
      money: (json['money'] as num?)?.toInt() ?? 0,
      reputation: (json['reputation'] as num?)?.toInt() ?? 50,
      level: (json['level'] as num?)?.toInt() ?? 1,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // WARNING: toJson is for in-memory use only; 'email' is NOT a profiles table column.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'money': money,
      'reputation': reputation,
      'level': level,
      'xp': xp,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PlayerProfile copyWith({
    String? companyName,
    int? money,
    int? reputation,
    int? level,
    int? xp,
  }) {
    return PlayerProfile(
      id: id,
      email: email,
      companyName: companyName ?? this.companyName,
      money: money ?? this.money,
      reputation: reputation ?? this.reputation,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      createdAt: createdAt,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  SupabaseClient? _supabase;
  StreamSubscription<AuthState>? _authSubscription;

  PlayerProfile? _profile;
  PlayerProfile? get profile => _profile;
  bool get isAuthenticated => _profile != null;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;

  AuthProvider() {
    try {
      _supabase = Supabase.instance.client;
    } catch (_) {
      _supabase = null;
    }
    _listenToAuth();
  }

  void _listenToAuth() {
    if (_supabase == null) {
      debugPrint('AuthProvider: Supabase not available, auth state changes disabled');
      return;
    }
    _authSubscription = _supabase!.auth.onAuthStateChange.listen(
      (AuthState state) async {
        if (state.event == AuthChangeEvent.signedIn &&
            state.session != null) {
          await loadProfile();
        } else if (state.event == AuthChangeEvent.signedOut) {
          _profile = null;
          notifyListeners();
        }
      },
    );
  }

  Future<void> loadProfile() async {
    if (_supabase == null) {
      _errorMessage = 'Сервер недоступен. Проверьте интернет-соединение.';
      notifyListeners();
      return;
    }
    final userId = _supabase!.auth.currentUser?.id;
    if (userId == null) {
      _profile = null;
      notifyListeners();
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase!
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        // Inject email from auth.users (profiles table has no email column)
        final email = _supabase!.auth.currentUser?.email ?? '';
        response['email'] = email;
        _profile = PlayerProfile.fromJson(response);
      } else {
        // Create default profile if none exists
        final email = _supabase!.auth.currentUser?.email ?? '';
        final newProfile = {
          'id': userId,
          'company_name': 'Новая компания',
          'money': 500000,
          'reputation': 50,
          'level': 1,
          'xp': 0,
        };
        await _supabase!.from('profiles').insert(newProfile);
        // email lives in auth.users, NOT in profiles table — do NOT update it here
        newProfile['email'] = email;
        _profile = PlayerProfile.fromJson(newProfile);
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Ошибка загрузки профиля: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    if (_supabase == null) {
      _errorMessage = 'Сервер недоступен. Проверьте интернет-соединение.';
      notifyListeners();
      return false;
    }
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _supabase!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        _errorMessage = 'Неверный email или пароль';
      } else if (e.message.contains('Email not confirmed')) {
        _errorMessage = 'Email не подтверждён. Проверьте почту.';
      } else {
        _errorMessage = 'Ошибка входа: ${e.message}';
      }
      return false;
    } catch (e) {
      _errorMessage = 'Ошибка подключения к серверу';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(
      String email, String password, String companyName) async {
    if (_supabase == null) {
      _errorMessage = 'Сервер недоступен. Проверьте интернет-соединение.';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _errorMessage = 'Пароль должен содержать минимум 6 символов';
      notifyListeners();
      return false;
    }
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _supabase!.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'company_name': companyName.trim()},
      );

      if (response.user != null) {
        final userId = response.user!.id;
        final newProfile = {
          'id': userId,
          'company_name': companyName.trim(),
          'money': 500000,
          'reputation': 50,
          'level': 1,
          'xp': 0,
        };
        await _supabase!.from('profiles').insert(newProfile);
        // email lives in auth.users, NOT in profiles table — do NOT update it here
        newProfile['email'] = email.trim();
        _profile = PlayerProfile.fromJson(newProfile);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        _errorMessage = 'Пользователь с таким email уже существует';
      } else {
        _errorMessage = 'Ошибка регистрации: ${e.message}';
      }
      return false;
    } catch (e) {
      _errorMessage = 'Ошибка подключения к серверу';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _supabase?.auth.signOut();
    _profile = null;
    notifyListeners();
  }

  Future<bool> updateCompanyName(String newName) async {
    if (newName.trim().isEmpty) {
      _errorMessage = 'Название компании не может быть пустым';
      notifyListeners();
      return false;
    }
    if (_supabase == null) {
      _errorMessage = 'Сервер недоступен';
      notifyListeners();
      return false;
    }
    try {
      final userId = _supabase!.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase!
          .from('profiles')
          .update({'company_name': newName.trim()}).eq('id', userId);

      if (_profile != null) {
        _profile = _profile!.copyWith(companyName: newName.trim());
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Ошибка обновления названия';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
