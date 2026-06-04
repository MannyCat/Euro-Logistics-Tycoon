import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isPirate = context.watch<ThemeProvider>().isPirate;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo area
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isPirate ? Icons.sailing : Icons.directions_boat,
                        size: 48,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'SHIPPING\nMANAGER',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isPirate
                        ? 'Покорите моря, собирайте золото'
                        : 'Морские перевозки — ваша стратегия',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyTextSmall,
                  ),
                  const SizedBox(height: 40),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(
                        isPirate ? Icons.email_outlined : Icons.email_outlined,
                        color: AppTheme.accent,
                      ),
                      hintText: 'company@example.com',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите email';
                      }
                      if (!value.contains('@')) {
                        return 'Некорректный email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: Icon(
                        isPirate ? Icons.lock_outline : Icons.lock_outline,
                        color: AppTheme.accent,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  const SizedBox(height: 8),

                  // Error message
                  if (auth.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.lossRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.lossRed.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          auth.errorMessage!,
                          style: AppTheme.bodyTextSmall.copyWith(
                            color: AppTheme.lossRed,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Login button
                  ElevatedButton.icon(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    icon: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(isPirate ? Icons.sailing : Icons.login,
                            color: isPirate
                                ? const Color(0xFF1A0F0A)
                                : Colors.white),
                    label: Text(
                      auth.isLoading
                          ? 'Вход...'
                          : (isPirate ? 'Отдать швартовы' : 'Войти в систему'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Register link
                  TextButton.icon(
                    onPressed: () => context.go('/register'),
                    icon: Icon(
                      isPirate ? Icons.anchor : Icons.add_business_outlined,
                      size: 18,
                    ),
                    label: const Text('Создать новую компанию'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
