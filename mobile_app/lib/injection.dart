import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_bloc.dart';
import 'features/notifications/data/notification_import_repository.dart';
import 'features/notifications/presentation/notification_import_bloc.dart';

final getIt = GetIt.instance;

/// 初始化依赖注入容器
Future<void> setupDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Core
  getIt.registerSingleton<ApiClient>(ApiClient(getIt<SharedPreferences>()));

  // Auth
  getIt.registerSingleton<AuthRepository>(
    AuthRepository(getIt<ApiClient>()),
  );
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(getIt<AuthRepository>(), getIt<ApiClient>()),
  );

  // Notifications
  getIt.registerSingleton<NotificationImportRepository>(
    NotificationImportRepository(getIt<ApiClient>()),
  );
  getIt.registerFactory<NotificationImportBloc>(
    () => NotificationImportBloc(getIt<NotificationImportRepository>()),
  );
}
