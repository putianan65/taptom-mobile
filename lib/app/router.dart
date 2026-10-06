import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/message_model.dart';
import '../data/models/ticket_model.dart';
import '../data/models/user_model.dart';
import '../features/admin/screens/admin_message_compose_screen.dart';
import '../features/admin/screens/admin_messages_screen.dart';
import '../features/admin/screens/admin_plots_map_screen.dart';
import '../features/admin/screens/create_plot_for_user_screen.dart';
import '../features/admin/screens/message_detail_screen.dart';
import '../features/admin/screens/user_management_screen.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/pin_entry_screen.dart';
import '../features/auth/screens/set_pin_screen.dart';
import '../features/auth/screens/sign_up_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/home/screens/admin_dashboard_screen.dart';
import '../features/home/screens/dashboard_screen.dart';
import '../features/home/screens/splash_screen.dart';
import '../features/notifications/screens/notification_screen.dart';
import '../features/support/screens/support_tickets_screen.dart';
import '../features/support/screens/ticket_detail_screen.dart';
import '../features/super_admin/screens/admin_detail_screen.dart';
import '../features/super_admin/screens/admin_management_screen.dart';
import '../features/super_admin/screens/create_admin_screen.dart';
import '../features/super_admin/screens/super_admin_dashboard_screen.dart';
import '../features/admin/screens/audit_log_screen.dart';
import '../features/traceability/screens/qr_scanner_screen.dart';
import '../features/traceability/screens/traceability_report_screen.dart';
import 'routes.dart';

/// Builds the router with role-based access control.
///
/// The guard runs on every navigation and whenever [AuthProvider] notifies:
/// * public pages (splash, sign-in, sign-up, traceability) are always open;
/// * the PIN steps are only reachable mid sign-in, with a temporary token;
/// * everything else needs a session, and role-scoped sections
///   (`/admin`, `/super-admin`, the farmer home) bounce other roles back to
///   their own home instead of showing a screen that would fail on 403.
GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: auth,
    debugLogDiagnostics: false,
    redirect: (context, state) => _guard(auth, state.uri),
    errorBuilder: (context, state) => const _NotFoundScreen(),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, __) => const SignUpScreen()),
      GoRoute(path: Routes.pin, builder: (_, __) => const PinEntryScreen()),
      GoRoute(path: Routes.setPin, builder: (_, __) => const SetPinScreen()),

      // Traceability is public so buyers can scan without an account.
      GoRoute(
        path: Routes.traceabilityScan,
        builder: (_, __) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/traceability/:lotNumber',
        builder: (_, state) => TraceabilityReportScreen(
          lotNumber: state.pathParameters['lotNumber'] ?? '',
        ),
      ),

      // Shared, signed-in
      GoRoute(
        path: Routes.notifications,
        builder: (_, __) => const NotificationScreen(),
      ),
      GoRoute(path: Routes.chat, builder: (_, __) => const ChatScreen()),
      GoRoute(
        path: Routes.supportTickets,
        builder: (_, __) => const SupportTicketsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => TicketDetailScreen(
              id: state.pathParameters['id'] ?? '',
              ticket: state.extra is Ticket ? state.extra as Ticket : null,
            ),
          ),
        ],
      ),

      // Farmer
      GoRoute(
        path: Routes.farmerHome,
        builder: (_, __) => const DashboardScreen(),
      ),

      // Admin
      GoRoute(
        path: Routes.adminHome,
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: Routes.adminMap,
        builder: (_, __) => const AdminPlotsMapScreen(),
      ),
      GoRoute(
        path: Routes.adminCreatePlot,
        builder: (_, __) => const CreatePlotForUserScreen(),
      ),
      GoRoute(
        path: Routes.adminMessages,
        builder: (_, __) => const AdminMessagesScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, state) => AdminMessageComposeScreen(
              initialRecipientId: state.uri.queryParameters['recipientId'],
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) => MessageDetailScreen(
              id: state.pathParameters['id'] ?? '',
              message: state.extra is Message ? state.extra as Message : null,
              partner: state.extra is UserModel ? state.extra as UserModel : null,
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.adminSupport,
        builder: (_, __) => const SupportTicketsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => TicketDetailScreen(
              id: state.pathParameters['id'] ?? '',
              ticket: state.extra is Ticket ? state.extra as Ticket : null,
            ),
          ),
        ],
      ),

      // Super admin
      GoRoute(
        path: Routes.superHome,
        builder: (_, __) => const SuperAdminDashboardScreen(),
      ),
      GoRoute(
        path: Routes.superAdmins,
        builder: (_, __) => const AdminManagementScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, __) => const CreateAdminScreen(),
          ),
          GoRoute(
            path: 'detail',
            redirect: (_, state) =>
                state.extra is Map<String, dynamic> ? null : Routes.superAdmins,
            builder: (_, state) => AdminDetailScreen(
              admin: state.extra! as Map<String, dynamic>,
            ),
          ),
        ],
      ),
      GoRoute(
        path: Routes.superLogs,
        builder: (_, __) => const AuditLogScreen(),
      ),
      GoRoute(
        path: Routes.superUsers,
        builder: (_, __) => const UserManagementScreen(),
      ),
      GoRoute(
        path: Routes.superPlots,
        builder: (_, __) => const AdminPlotsMapScreen(),
      ),
    ],
  );
}

String? _guard(AuthProvider auth, Uri uri) {
  final path = uri.path;

  // Traceability and the splash decide for themselves.
  if (path.startsWith('/traceability') || path == Routes.splash) return null;

  final user = auth.currentUser;
  if (user == null) {
    if (Routes.isPinStep(path)) {
      return auth.tempToken != null ? null : Routes.login;
    }
    if (Routes.isPublic(path)) return null;
    return Routes.login;
  }

  final home = Routes.homeFor(user.role);
  if (Routes.isPublic(path) || Routes.isPinStep(path)) return home;

  final allowed = Routes.rolesFor(path);
  if (allowed != null && !allowed.contains(user.role)) return home;
  return null;
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ไม่พบหน้าที่ต้องการ',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(Routes.splash),
                child: const Text('กลับหน้าหลัก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
