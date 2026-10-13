import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/url_repository.dart';
import '../../repositories/user_repository.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/url/url_bloc.dart';
import '../router/app_router.dart';

final sl = GetIt.instance; // sl stands for Service Locator

Future<void> initDependencies() async {
  // -------------------------------------------------------------
  // 1. External & Core
  // -------------------------------------------------------------
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ApiClient depends on SharedPreferences
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl<SharedPreferences>()));

  // -------------------------------------------------------------
  // 2. Repositories
  // -------------------------------------------------------------
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(apiClient: sl<ApiClient>(), prefs: sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<UrlRepository>(
    () => UrlRepository(apiClient: sl<ApiClient>()),
  );

  // Admin-only user management
  sl.registerLazySingleton<UserRepository>(
    () => UserRepository(apiClient: sl<ApiClient>()),
  );

  // -------------------------------------------------------------
  // 3. BLoCs (Factory or Singleton depending on app lifecycle)
  // -------------------------------------------------------------
  // AuthBloc is a Singleton because the app session lasts the entire runtime
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );

  // UrlBloc can be a Factory (creates a fresh instance when requested) or Singleton
  sl.registerFactory<UrlBloc>(
    () => UrlBloc(urlRepository: sl<UrlRepository>()),
  );

  // -------------------------------------------------------------
  // 4. Router (Depends on AuthBloc for session redirect guards)
  // -------------------------------------------------------------
  sl.registerLazySingleton<AppRouter>(
    () => AppRouter(authBloc: sl<AuthBloc>()),
  );
}