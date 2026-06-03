import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'app.dart';

/// Global flag: true if Supabase was initialized successfully.
bool supabaseReady = false;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Error handling for Flutter framework
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrintStack(stackTrace: details.stack);
    };

    // Initialize Supabase with a 5-second timeout (non-fatal)
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
      ).timeout(const Duration(seconds: 5));
      supabaseReady = true;
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      supabaseReady = false;
      debugPrint('Supabase initialization failed (non-fatal): $e');
    }

    // ALWAYS start the UI regardless of Supabase status
    runApp(const ShippingManagerApp());
  }, (error, stack) {
    debugPrint('Uncaught Error: $error');
    debugPrintStack(stackTrace: stack);
  });
}
