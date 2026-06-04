import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'data/models/user_model.dart';
import 'core/themes/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/plot_service.dart';
import 'core/services/admin_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/certificate_pdf_service.dart';
import 'core/services/gap_service.dart';
import 'features/settings/settings_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/sign_up_screen.dart';
import 'features/home/screens/splash_screen.dart';
import 'features/home/screens/dashboard_screen.dart';
import 'features/home/screens/admin_dashboard_screen.dart';
import 'features/approval/screens/approval_detail_screen.dart';
import 'features/auth/screens/pin_entry_screen.dart';
import 'features/auth/screens/set_pin_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/admin/screens/admin_list_screen.dart';
import 'features/admin/screens/create_admin_screen.dart';
import 'features/admin/screens/admin_plots_map_screen.dart';
import 'features/admin/providers/admin_state_provider.dart';
import 'features/admin/screens/create_plot_for_user_screen.dart'; // NEW
import 'features/admin/screens/admin_messages_screen.dart'; // NEW
import 'features/admin/screens/admin_message_compose_screen.dart'; // NEW
import 'features/admin/screens/message_detail_screen.dart'; // NEW
import 'features/shared/screens/support_tickets_screen.dart'; // NEW (Plan called it tickets, file name matches)
import 'features/shared/screens/ticket_detail_screen.dart'; // NEW
import 'features/admin/screens/pdpa_logs_screen.dart'; // NEW
import 'data/models/message_model.dart';
import 'data/models/ticket_model.dart';
import 'locator.dart'; // NEW

// ✅ NEW: Super Admin Imports
import 'core/services/super_admin_service.dart';
import 'features/super_admin/screens/super_admin_dashboard_screen.dart';
import 'features/super_admin/screens/admin_management_screen.dart';
import 'features/super_admin/screens/admin_detail_screen.dart';
import 'features/super_admin/screens/create_admin_screen.dart' as super_admin_create;
import 'features/super_admin/screens/system_logs_screen.dart';
import 'features/admin/screens/user_management_screen.dart';

import 'features/notifications/screens/notification_screen.dart'; // NEW
import 'features/notifications/providers/notification_provider.dart'; // NEW
import 'features/admin/providers/message_provider.dart'; // NEW

// Traceability (Public)
import 'features/traceability/screens/qr_scanner_screen.dart';
import 'features/traceability/screens/traceability_report_screen.dart';

class TaptomApp extends StatelessWidget {
  const TaptomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => ApiAuthService()),
        Provider<PlotService>(create: (_) => PlotService()),
        Provider<AdminService>(create: (_) => AdminService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<CertificatePdfService>(create: (_) => CertificatePdfService()),
        Provider<GapService>(create: (_) => GapService()),
        ChangeNotifierProvider<SettingsProvider>(
          // New Provider
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>.value(
          value: locator<AuthProvider>(),
        ),
        ChangeNotifierProvider<AdminStateProvider>(
          create: (context) => AdminStateProvider(context.read<AdminService>()),
        ),
        // ✅ NEW: Super Admin Service
        Provider<SuperAdminService>(create: (_) => SuperAdminService()),
        // ✅ NEW: Notification Provider
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
        // ✅ NEW: Message Provider
        ChangeNotifierProvider<MessageProvider>(
          create: (context) => MessageProvider(
            context.read<AdminService>(),
            context.read<SuperAdminService>(),
            context.read<AuthProvider>(),
          ),
        ),
      ],
      child: const TaptomAppRouter(),
    );
  }
}

class TaptomAppRouter extends StatefulWidget {
  const TaptomAppRouter({super.key});

  @override
  State<TaptomAppRouter> createState() => _TaptomAppRouterState();
}

class _TaptomAppRouterState extends State<TaptomAppRouter> {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    // Defer GoRouter initialization to avoid context.read() during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeRouter();
    });
  }

  void _initializeRouter() {
    final authProvider = context.read<AuthProvider>();
    setState(() {
      _router = GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/pin',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final isAdmin = extra?['isAdmin'] as bool? ?? true;
            final isSuperAdmin = extra?['isSuperAdmin'] as bool? ?? false;
            return PinEntryScreen(isAdmin: isAdmin, isSuperAdmin: isSuperAdmin);
          },
        ),
        GoRoute(
          path: '/set-pin',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final isSuperAdmin = extra?['isSuperAdmin'] as bool? ?? false;
            return SetPinScreen(isSuperAdmin: isSuperAdmin);
          },
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        // ✅ NEW: Super Admin Routes
        GoRoute(
          path: '/super-admin/dashboard',
          builder: (context, state) => const SuperAdminDashboardScreen(),
        ),
        GoRoute(
          path: '/super-admin/admins',
          builder: (context, state) => const AdminManagementScreen(),
          routes: [
             GoRoute(
               path: 'create',
               builder: (context, state) => const super_admin_create.CreateAdminScreen(),
             ),
             GoRoute(
               path: 'detail',
               builder: (context, state) {
                 final admin = state.extra as Map<String, dynamic>;
                 return AdminDetailScreen(admin: admin);
               },
             ),
          ],
        ),
        GoRoute(
          path: '/super-admin/logs',
          builder: (context, state) => const SystemLogsScreen(),
        ),
        // ✅ NEW: Super Admin Users & Plots
        GoRoute(
          path: '/super-admin/users',
          builder: (context, state) => UserManagementScreen(),
        ),
        GoRoute(
          path: '/super-admin/plots',
          builder: (context, state) => const AdminPlotsMapScreen(), // Reusing Map for global view
        ),
        GoRoute(
          path: '/admin/approval/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? 'Unknown';
            return ApprovalDetailScreen(id: id);
          },
        ),
        GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
        GoRoute(
          path: '/admin/list',
          builder: (context, state) => const AdminListScreen(),
        ),
        GoRoute(
          path: '/admin/create',
          builder: (context, state) => const CreateAdminScreen(),
        ),
        GoRoute(
          path: '/admin/map',
          builder: (context, state) => const AdminPlotsMapScreen(),
        ),
        GoRoute(
          path: '/admin/map',
          builder: (context, state) => const AdminPlotsMapScreen(),
        ),
        // ✅ NEW: Admin Profiles & Plot Assist
        GoRoute(
          path: '/admin/create-plot-for-user',
          builder: (context, state) => const CreatePlotForUserScreen(),
        ),
        
        // ✅ NEW: Messaging System
        GoRoute(
          path: '/admin/messages',
          builder: (context, state) => const AdminMessagesScreen(),
          routes: [
             GoRoute(
              path: 'new',
              builder: (context, state) {
                // Check if we passed a specific recipient ID via extra or query params?
                // Let's support query param ?recipientId=...
                final recipientId = state.uri.queryParameters['recipientId'];
                return AdminMessageComposeScreen(initialRecipientId: recipientId);
              },
            ),
             GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                final message = state.extra is Message ? state.extra as Message : null;
                return MessageDetailScreen(id: id, message: message);
              },
            ),
          ],
        ),

        // ✅ NEW: Support Tickets (Shared logic or admin view)
        GoRoute(
          path: '/admin/support-tickets',
          builder: (context, state) => const SupportTicketsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                final ticket = state.extra as Ticket?;
                return TicketDetailScreen(id: id, ticket: ticket);
              },
            )
          ]
        ),
        
         // General Route for User Support (if needed in future, currently bundling under admin path per task focus, 
         // but plan implies generic. Let's add generic /support-tickets as well if users access it)
         GoRoute(
          path: '/support-tickets',
          builder: (context, state) => const SupportTicketsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id'] ?? '';
                final ticket = state.extra as Ticket?;
                return TicketDetailScreen(id: id, ticket: ticket);
              },
            )
          ]
        ),

        // ✅ NEW: Notifications
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationScreen(),
        ),

        // ✅ NEW: Traceability (Public — No Auth Required)
        GoRoute(
          path: '/traceability/scan',
          builder: (context, state) => const QrScannerScreen(),
        ),
        GoRoute(
          path: '/traceability/:lotNumber',
          builder: (context, state) {
            final lotNumber = state.pathParameters['lotNumber'] ?? '';
            return TraceabilityReportScreen(lotNumber: lotNumber);
          },
        ),

      ],
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final path = state.uri.path;

        // Define public routes that don't require auth
        final isPublic =
            path == '/' ||
            path == '/login' ||
            path == '/register' ||
            path == '/pin' ||
            path == '/set-pin' ||
            path.startsWith('/traceability');

        // Traceability routes are open to EVERYONE (auth + non-auth)
        // They should NEVER redirect, regardless of auth state
        final isTraceability = path.startsWith('/traceability');

        // Case 0: Traceability routes — always allow, never redirect
        if (isTraceability) {
          return null;
        }

        // Case 1: Not authenticated and trying to access private route
        if (!isAuthenticated && !isPublic) {
          return '/login';
        }

          // Case 2: Authenticated and trying to access public route
        if (isAuthenticated && isPublic) {
          final user = authProvider.currentUser;
          if (user?.role == UserRole.superAdmin) {
            return '/super-admin/dashboard';
          } else if (user?.role == UserRole.admin) {
            return '/admin/dashboard';
          }
          return '/dashboard';
        }

        return null;
      },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // Show loading until router is initialized
    if (_router == null) {
      return MaterialApp(
        title: 'GAP Management',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settings.themeMode,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'GAP Management',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
      locale: settings.locale,
    );
  }
}
