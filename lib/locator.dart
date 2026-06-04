import 'package:get_it/get_it.dart';
import 'features/auth/auth_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_trigger_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Services
  locator.registerLazySingleton<AuthService>(() => ApiAuthService());
  locator.registerLazySingleton<NotificationTriggerService>(() => NotificationTriggerService());

  // Providers
  locator.registerLazySingleton<AuthProvider>(() => AuthProvider(locator<AuthService>()));
}
