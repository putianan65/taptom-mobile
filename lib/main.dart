import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // GAP-BUG-015
import 'core/config/env.dart';
import 'core/services/permission_service.dart';
import 'app.dart';
import 'locator.dart'; // NEW
import 'features/auth/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.init();

  // GAP-BUG-015: Initialize Thai date formatting
  await initializeDateFormatting('th', null);

  setupLocator(); // ✅ Setup DI
  
  // ✅ Load tokens on startup
  final authProvider = locator<AuthProvider>();
  await authProvider.loadTokensFromStorage();

  // ✅ Request notification permission (Android 13+ / iOS)
  try {
    await PermissionService.requestNotificationPermission();
  } catch (e) {
    debugPrint('⚠️ Notification permission request failed: $e');
  }

  runApp(const ProviderScope(child: TaptomApp()));
}
