import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_icons.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _LoginForm(),
      )),
    );
  }
}

class _LoginForm extends StatefulWidget {
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 40),
      // Logo
      Center(child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent.withOpacity(0.12), border: Border.all(color: AppTheme.accent.withOpacity(0.3), width: 2)),
        child: const Icon(AppIcons.truck, size: 36, color: AppTheme.accent))),
      const SizedBox(height: 16),
      Center(child: Text('EURO LOGISTICS\nTYCOON', textAlign: TextAlign.center, style: AppTheme.h1.copyWith(letterSpacing: 3, fontSize: 24))),
      const SizedBox(height: 4),
      Center(child: Text('Постройте логистическую империю', style: AppTheme.bodySm)),
      const SizedBox(height: 32),

      // Error
      if (auth.error != null) Container(
        padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: AppTheme.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.red.withOpacity(0.3))),
        child: Text(auth.error!, style: AppTheme.bodySm.copyWith(color: AppTheme.red), textAlign: TextAlign.center),
      ),

      TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(AppIcons.person))),
      const SizedBox(height: 12),
      TextField(controller: _passCtrl, obscureText: _obscure, decoration: InputDecoration(
        labelText: 'Пароль', prefixIcon: const Icon(AppIcons.locked),
        suffixIcon: IconButton(icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye), onPressed: () => setState(() => _obscure = !_obscure)),
      )),
      const SizedBox(height: 20),

      ElevatedButton.icon(
        onPressed: auth.isLoading ? null : () async {
          final ok = await auth.login(_emailCtrl.text, _passCtrl.text);
          if (ok && context.mounted) context.go('/');
        },
        icon: auth.isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(AppIcons.arrowRight),
        label: Text(auth.isLoading ? 'Вход...' : 'Войти'),
      ),
      const SizedBox(height: 12),
      TextButton.icon(onPressed: () => context.go('/register'), icon: const Icon(AppIcons.addBusiness, size: 18), label: const Text('Создать компанию')),
      const SizedBox(height: 40),
    ]);
  }
}
