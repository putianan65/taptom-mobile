import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/design/design.dart';
import '../core/services/admin_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/certificate_pdf_service.dart';
import '../core/services/gap_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/plot_service.dart';
import '../core/services/super_admin_service.dart';
import '../features/admin/providers/admin_state_provider.dart';
import '../features/admin/providers/message_provider.dart';
import '../features/auth/auth_provider.dart';
import '../features/notifications/providers/notification_provider.dart';
import '../features/settings/settings_provider.dart';
import 'locator.dart';
import 'router.dart';

/// Root widget: dependency graph, theme and router.
class TaptomApp extends StatelessWidget {
  const TaptomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => locator<AuthService>()),
        Provider<PlotService>(create: (_) => PlotService()),
        Provider<AdminService>(create: (_) => AdminService()),
        Provider<SuperAdminService>(create: (_) => SuperAdminService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<CertificatePdfService>(create: (_) => CertificatePdfService()),
        Provider<GapService>(create: (_) => GapService()),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>.value(
          value: locator<AuthProvider>(),
        ),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: locator<NotificationProvider>(),
        ),
        ChangeNotifierProvider<AdminStateProvider>(
          create: (context) => AdminStateProvider(context.read<AdminService>()),
        ),
        ChangeNotifierProvider<MessageProvider>(
          create: (context) => MessageProvider(
            context.read<AdminService>(),
            context.read<SuperAdminService>(),
            context.read<AuthProvider>(),
          ),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router = buildRouter(context.read<AuthProvider>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsProvider, ThemeMode>(
      (s) => s.themeMode,
    );
    final textScale = context.select<SettingsProvider, double>(
      (s) => s.textScale,
    );
    return MaterialApp.router(
      title: 'TAPTOM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      themeAnimationDuration: Motion.base,
      routerConfig: _router,
      locale: const Locale('th', 'TH'),
      supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Honour the system text size, then apply the in-app preference on
        // top, clamped so layouts stay intact.
        final media = MediaQuery.of(context);
        final system = media.textScaler.scale(1);
        final scale = (system * textScale).clamp(0.9, 1.6);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
