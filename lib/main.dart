import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/supabase_config.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Global error handler — prevents silent crashes
    FlutterError.onError = (details) {
      debugPrint('FLUTTER ERROR: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    };

    // Initialize Supabase — catch errors so app never crashes on startup
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      debugPrint('Supabase OK');
    } catch (e) {
      debugPrint('Supabase init error (non-fatal): $e');
    }

    // Always run the app, even if Supabase failed
    runApp(const CyberHackApp());
  }, (error, stack) {
    debugPrint('UNCAUGHT ERROR: $error');
    debugPrint('Stack: $stack');
  });
}
