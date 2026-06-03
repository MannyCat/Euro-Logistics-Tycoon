import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'app.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Error handling for Flutter framework
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrintStack(stackTrace: details.stack);
    };

    // Initialize Supabase (non-fatal — app still runs if it fails)
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization failed (non-fatal): $e');
      // App will continue to run, features requiring Supabase will show errors
    }

    runApp(const ShippingManagerApp());
  }, (error, stack) {
    debugPrint('Uncaught Error: $error');
    debugPrintStack(stackTrace: stack);
  });
}
