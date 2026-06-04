class ApiEndpoints {
  // Auth
  static const String login = '/auth/signin';
  static const String signup = '/auth/signup';
  static const String refreshToken = '/auth/refresh';
  static const String verifyPin = '/auth/verify-pin';
  static const String setPin = '/auth/set-pin';
  static const String changePin = '/auth/change-pin';

  // Users
  static const String userProfile = '/users/me';
  static const String userStats = '/users/statistics';
  static const String users = '/users';
  static String user(String id) => '/users/$id';
  static String userRole(String id) => '/users/$id/role';
  static String userRestore(String id) => '/users/$id/restore';

  // Plots
  static const String plots = '/plots';
  static const String plotSummary = '/plots/summary';
  static String plot(String plotId) => '/plots/$plotId';

  // GAP Forms (หมวด 1.1-1.7)
  static String gap(String plotId) => '/plots/$plotId/gap';
  static String gapAll(String plotId) => '/plots/$plotId/gap/all';
  static String gapSummary(String plotId) => '/plots/$plotId/gap/summary';
  static String gapCompliance(String plotId) => '/plots/$plotId/gap/compliance';
  static String gapMissing(String plotId) => '/plots/$plotId/gap/missing';
  static String gapReset(String plotId) => '/plots/$plotId/gap/reset';

  // GAP Inputs (หมวด 1.2)
  static String inputs(String plotId) => '/plots/$plotId/inputs';
  static String input(String plotId, String id) => '/plots/$plotId/inputs/$id';

  // Field Management (หมวด 1.3)
  static String activities(String plotId) => '/plots/$plotId/field-activities';
  static String activity(String plotId, String id) =>
      '/plots/$plotId/field-activities/$id';

  // Harvest (หมวด 1.4)
  static String harvests(String plotId) => '/plots/$plotId/harvests';
  static String harvest(String plotId, String id) =>
      '/plots/$plotId/harvests/$id';

  // Post-Harvest (หมวด 1.5) - child of Harvest
  static String postHarvest(String harvestId) =>
      '/harvests/$harvestId/post-harvest';
  static String postHarvestItem(String harvestId, String id) =>
      '/harvests/$harvestId/post-harvest/$id';

  // Worker Training (หมวด 1.6)
  static String trainings(String plotId) => '/plots/$plotId/trainings';
  static String training(String plotId, String id) =>
      '/plots/$plotId/trainings/$id';

  // Traceability (หมวด 1.7)
  static String traceability(String id) => '/traceability/$id';
  static String traceabilityLots(String plotId) => '/traceability/plots/$plotId';
  static String createLot(String plotId) =>
      '/traceability/plots/$plotId/create-lot';

  // Locations (ไม่ต้อง Auth)
  static const String regions = '/locations/regions';
  static const String provinces = '/locations/provinces';
  static const String districts = '/locations/districts';
  static const String subdistricts = '/locations/subdistricts';

  // Reports
  static String gapReport(String plotId) => '/reports/plots/$plotId/gap.pdf';

  // Upload
  static const String upload = '/upload';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationRead(String id) => '/notifications/$id/read';
  static String notificationDelete(String id) => '/notifications/$id';

  // Feedback
  static const String rateApp = '/feedback/rate-app';
  static const String myRating = '/feedback/my-rating';
  static const String ratingStats = '/feedback/stats';

  // Admin
  static const String adminPlots = '/admin/plots';
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static const String adminCreate =
      '/admin/create'; // SUPER_ADMIN: Create Admin
  static const String adminList = '/admin'; // SUPER_ADMIN: List all Admins
  static String adminDelete(String id) =>
      '/admin/$id'; // SUPER_ADMIN: Delete Admin
  static String adminPlotDetail(String plotId) => '/admin/plots/$plotId';
  static String adminApprove(String plotId) => '/admin/plots/$plotId/approve';
  static String adminReject(String plotId) => '/admin/plots/$plotId/reject';
  static String adminUserApprove(String userId) =>
      '/admin/users/$userId/approve';
  static String adminUserReject(String userId) => '/admin/users/$userId/reject';
  static String adminAssign(String adminId) => '/admin/admins/$adminId/assign';
  static String adminReassign(String userId) => '/admin/users/$userId/reassign';

  // Super Admin Analytics
  static const String adminGapAnalytics = '/admin/gap-analytics';
  static const String adminTrends = '/admin/statistics/trends';
  static const String adminAuditLogs = '/admin/audit-logs';

  // Messaging (Shared Admin/SuperAdmin)
  static const String adminMessages = '/admin/messages';
  static String adminMessageReply(String id) => '/admin/messages/$id/reply';
  static const String adminConversations = '/admin/messages/conversations'; // NEW
  static const String adminUnreadTotal = '/admin/messages/unread-total'; // NEW
  static const String adminMarkRead = '/admin/messages/mark-read'; // NEW

  // GAP Admin Feedback
  static const String adminGapFeedback = '/admin/gap-feedback';
  static String adminPlotGeometry(String plotId) =>
      '/admin/plots/$plotId/geometry';
}
