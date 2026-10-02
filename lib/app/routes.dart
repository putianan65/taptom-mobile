import '../data/models/user_model.dart';

/// Route paths in one place, so navigation calls and guards cannot drift
/// apart.
abstract final class Routes {
  // Public
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const pin = '/pin';
  static const setPin = '/set-pin';
  static const traceabilityScan = '/traceability/scan';
  static String traceability(String lot) =>
      '/traceability/${Uri.encodeComponent(lot)}';

  // Any signed-in role
  static const notifications = '/notifications';
  static const supportTickets = '/support-tickets';
  static String supportTicket(String id) => '/support-tickets/$id';
  static const chat = '/chat';

  // Farmer
  static const farmerHome = '/dashboard';

  // Admin (also open to super admin)
  static const adminHome = '/admin/dashboard';
  static const adminMap = '/admin/map';
  static const adminMessages = '/admin/messages';
  static const adminMessageNew = '/admin/messages/new';
  static String adminMessage(String id) => '/admin/messages/$id';
  static const adminSupport = '/admin/support-tickets';
  static const adminCreatePlot = '/admin/create-plot-for-user';

  // Super admin
  static const superHome = '/super-admin/dashboard';
  static const superAdmins = '/super-admin/admins';
  static const superAdminCreate = '/super-admin/admins/create';
  static const superAdminDetail = '/super-admin/admins/detail';
  static const superLogs = '/super-admin/logs';
  static const superUsers = '/super-admin/users';
  static const superPlots = '/super-admin/plots';

  /// Landing page for a role after sign-in.
  static String homeFor(UserRole? role) => switch (role) {
        UserRole.superAdmin => superHome,
        UserRole.admin => adminHome,
        _ => farmerHome,
      };

  /// Roles allowed to open [path], or null when any signed-in user may.
  static Set<UserRole>? rolesFor(String path) {
    if (path.startsWith('/super-admin')) return {UserRole.superAdmin};
    if (path.startsWith('/admin')) {
      return {UserRole.admin, UserRole.superAdmin};
    }
    if (path == farmerHome) return {UserRole.farmer};
    return null;
  }

  static bool isPublic(String path) =>
      path == splash ||
      path == login ||
      path == register ||
      path.startsWith('/traceability');

  static bool isPinStep(String path) => path == pin || path == setPin;
}
