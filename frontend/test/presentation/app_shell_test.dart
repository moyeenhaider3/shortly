import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_shortener_client/bloc/auth/auth_bloc.dart';
import 'package:url_shortener_client/bloc/url/url_bloc.dart';
import 'package:url_shortener_client/core/network/api_client.dart';
import 'package:url_shortener_client/presentation/layout/app_shell.dart';
import 'package:url_shortener_client/presentation/theme/app_theme.dart';
import 'package:url_shortener_client/presentation/theme/theme_mode_cubit.dart';
import 'package:url_shortener_client/repositories/auth_repository.dart';
import 'package:url_shortener_client/repositories/url_repository.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final api = ApiClient(prefs);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(
              authRepository: AuthRepository(apiClient: api, prefs: prefs),
            ),
          ),
          BlocProvider(
            create: (_) => UrlBloc(urlRepository: UrlRepository(apiClient: api)),
          ),
          BlocProvider(create: (_) => ThemeModeCubit(prefs)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AppShell(
            location: '/links',
            child: Center(child: Text('page content')),
          ),
        ),
      ),
    );
  }

  testWidgets('desktop (1440×900) shows the full sidebar', (tester) async {
    await pumpShell(tester, const Size(1440, 900));
    expect(find.text('Search links'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Links'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('page content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet (900×800) shows the icon rail with tooltips', (tester) async {
    await pumpShell(tester, const Size(900, 800));
    expect(find.text('Search links'), findsNothing);
    expect(find.byTooltip('Analytics'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone (390×844) shows a bottom navigation bar', (tester) async {
    await pumpShell(tester, const Size(390, 844));
    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.selectedIndex, 1); // /links
    expect(find.text('Search links'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
