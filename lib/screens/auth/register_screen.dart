import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _RegisterForm(),
      )),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
      const SizedBox(height: 12),
      TextField(controller: _passCtrl, obscureText: _obscure, decoration: InputDecoration(
        labelText: 'Пароль (мин. 6 симв.)', prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
      )),
      const SizedBox(height: 12),
      TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Название компании', prefixIcon: Icon(Icons.business_outlined))),
      const SizedBox(height: 20),

      if (auth.error != null) Container(
        padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: AppTheme.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.red.withOpacity(0.3))),
        child: Text(auth.error!, style: AppTheme.bodySm.copyWith(color: AppTheme.red), textAlign: TextAlign.center),
      ),

      ElevatedButton.icon(
        onPressed: auth.isLoading ? null : () async {
          final ok = await auth.register(_emailCtrl.text, _passCtrl.text, _nameCtrl.text);
          if (ok && context.mounted) context.go('/');
        },
        icon: auth.isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.business_center),
        label: Text(auth.isLoading ? 'Создание...' : 'Создать компанию'),
      ),
      const SizedBox(height: 12),
      TextButton(onPressed: () => context.go('/login'), child: const Text('Уже есть аккаунт? Войти')),
    ]);
  }
}
