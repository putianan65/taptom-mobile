import 'package:get_it/get_it.dart';

import '../core/services/auth_service.dart';
import '../core/services/notification_trigger_service.dart';
import '../features/auth/auth_provider.dart';
import '../features/notifications/providers/notification_provider.dart';

/// Global service locator. Holds objects that must be reachable outside the
/// widget tree, such as [AuthProvider] for the HTTP interceptor.
final locator = GetIt.instance;

void setupLocator() {
  if (locator.isRegistered<AuthService>()) return;

  locator
    ..registerLazySingleton<AuthService>(ApiAuthService.new)
    ..registerLazySingleton<NotificationTriggerService>(
      NotificationTriggerService.new,
    )
    ..registerLazySingleton<NotificationProvider>(NotificationProvider.new)
    ..registerLazySingleton<AuthProvider>(
      () => AuthProvider(
        locator<AuthService>(),
        onSignedOut: () => locator<NotificationProvider>().reset(),
      ),
    );
}
