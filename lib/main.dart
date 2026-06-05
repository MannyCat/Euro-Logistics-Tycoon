import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'app.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) { debugPrint('Flutter: ${details.exception}'); };

    try {
      await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey, debug: kDebugMode);
      debugPrint('Supabase initialized');
    } catch (e) {
      debugPrint('Supabase init failed: $e');
    }

    runApp(const ELTApp());
  }, (error, stack) { debugPrint('Uncaught: $error'); });
}
