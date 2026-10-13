import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/injection_container.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/auth/auth_state.dart';
import 'bloc/url/url_bloc.dart';
import 'bloc/url/url_event.dart';
import 'core/router/app_router.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/theme/theme_mode_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean path URLs (no '#').
  usePathUrlStrategy();

  await initDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Built once; ThemeData construction isn't free.
  static final _light = AppTheme.light();
  static final _dark = AppTheme.dark();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()..add(AppStarted())),
        BlocProvider<UrlBloc>(create: (_) => sl<UrlBloc>()),
        BlocProvider<ThemeModeCubit>(create: (_) => ThemeModeCubit(sl<SharedPreferences>())),
      ],
      // Load links when a session starts; drop them when it ends so the next
      // user on this browser never sees the previous user's links.
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            (prev.status == AuthStatus.authenticated) != (curr.status == AuthStatus.authenticated),
        listener: (context, state) {
          final urls = context.read<UrlBloc>();
          urls.add(state.status == AuthStatus.authenticated ? FetchUrls() : UrlsCleared());
        },
        child: BlocBuilder<ThemeModeCubit, ThemeMode>(
          builder: (context, mode) => MaterialApp.router(
            title: 'Shortly',
            debugShowCheckedModeBanner: false,
            theme: _light,
            darkTheme: _dark,
            themeMode: mode,
            routerConfig: sl<AppRouter>().router,
          ),
        ),
      ),
    );
  }
}
