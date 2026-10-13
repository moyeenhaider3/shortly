import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_shortener_client/bloc/auth/auth_bloc.dart';
import 'package:url_shortener_client/bloc/auth/auth_state.dart';
import 'package:url_shortener_client/bloc/url/url_bloc.dart';
import 'package:url_shortener_client/core/network/api_client.dart';
import 'package:url_shortener_client/models/user_model.dart';
import 'package:url_shortener_client/presentation/features/users/cubit/users_cubit.dart';
import 'package:url_shortener_client/presentation/features/users/widgets/add_user_dialog.dart';
import 'package:url_shortener_client/presentation/layout/app_shell.dart';
import 'package:url_shortener_client/presentation/theme/app_theme.dart';
import 'package:url_shortener_client/presentation/theme/theme_mode_cubit.dart';
import 'package:url_shortener_client/repositories/auth_repository.dart';
import 'package:url_shortener_client/repositories/url_repository.dart';
import 'package:url_shortener_client/repositories/user_repository.dart';

class FakeUserRepository extends UserRepository {
  final List<Map<String, String>> created = [];
  String? failWith;

  FakeUserRepository(SharedPreferences prefs) : super(apiClient: ApiClient(prefs));

  @override
  Future<List<UserModel>> getUsers() async => const [];

  @override
  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (failWith != null) throw Exception(failWith);
    created.add({'name': name, 'email': email, 'password': password, 'role': role});
    return UserModel(id: 'new-id', name: name, email: email, role: role);
  }
}

/// AuthBloc pinned to a given signed-in user, without touching the network.
class FixedAuthBloc extends AuthBloc {
  FixedAuthBloc(SharedPreferences prefs, UserModel user)
    : super(
        authRepository: AuthRepository(apiClient: ApiClient(prefs), prefs: prefs),
      ) {
    emit(AuthState.authenticated(user));
  }
}

const admin = UserModel(id: 'a1', name: 'Ada Admin', email: 'ada@x.com', role: UserModel.roleAdmin);
const normal = UserModel(id: 'n1', name: 'Nia Normal', email: 'nia@x.com', role: UserModel.roleNormal);

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('Users nav entry', () {
    Future<void> pumpShellAs(WidgetTester tester, UserModel user) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(create: (_) => FixedAuthBloc(prefs, user)),
            BlocProvider(
              create: (_) => UrlBloc(urlRepository: UrlRepository(apiClient: ApiClient(prefs))),
            ),
            BlocProvider(create: (_) => ThemeModeCubit(prefs)),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const AppShell(location: '/users', child: SizedBox()),
          ),
        ),
      );
    }

    testWidgets('is shown to admins and selected on /users', (tester) async {
      await pumpShellAs(tester, admin);
      expect(find.text('Users'), findsOneWidget);
      final selected = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.label == 'Users' && s.properties.selected == true);
      expect(selected, isNotEmpty);
    });

    testWidgets('is hidden from normal users', (tester) async {
      await pumpShellAs(tester, normal);
      expect(find.text('Users'), findsNothing);
      expect(find.text('Links'), findsOneWidget);
    });
  });

  group('Add user dialog', () {
    late FakeUserRepository repo;
    late UsersCubit cubit;
    UserModel? result;

    Future<void> openDialog(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repo = FakeUserRepository(prefs);
      cubit = UsersCubit(repo);
      result = null;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showAddUserDialog(context, cubit),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<void> fill(
      WidgetTester tester, {
      String name = 'Grace Hopper',
      String email = 'grace@x.com',
      String pw = 'secret1',
    }) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), name);
      await tester.enterText(fields.at(1), email);
      await tester.enterText(fields.at(2), pw);
    }

    testWidgets('validates before calling the API', (tester) async {
      await openDialog(tester);
      await fill(tester, name: 'G', email: 'not-an-email', pw: '123');
      await tester.ensureVisible(find.text('Create user'));
      await tester.tap(find.text('Create user'));
      await tester.pumpAndSettle();
      expect(find.text('Enter at least 2 characters'), findsOneWidget);
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Use at least 6 characters'), findsOneWidget);
      expect(repo.created, isEmpty);
    });

    testWidgets('creates an admin when Admin is picked', (tester) async {
      await openDialog(tester);
      await fill(tester);
      await tester.ensureVisible(find.text('Admin'));
      await tester.tap(find.text('Admin'));
      await tester.pump();
      expect(find.text('Create admin'), findsOneWidget);
      await tester.ensureVisible(find.text('Create admin'));
      await tester.tap(find.text('Create admin'));
      await tester.pumpAndSettle();

      expect(repo.created.single, {
        'name': 'Grace Hopper',
        'email': 'grace@x.com',
        'password': 'secret1',
        'role': 'ADMIN',
      });
      expect(result?.isAdmin, isTrue);
      expect(find.byType(Dialog), findsNothing);
      expect(cubit.state.users.single.email, 'grace@x.com');
    });

    testWidgets('defaults to a normal user', (tester) async {
      await openDialog(tester);
      await fill(tester);
      await tester.ensureVisible(find.text('Create user'));
      await tester.tap(find.text('Create user'));
      await tester.pumpAndSettle();
      expect(repo.created.single['role'], 'NORMAL');
    });

    testWidgets('shows a server error inline and keeps the form', (tester) async {
      await openDialog(tester);
      repo.failWith = 'Email is already registered';
      await fill(tester);
      await tester.ensureVisible(find.text('Create user'));
      await tester.tap(find.text('Create user'));
      await tester.pumpAndSettle();

      expect(find.text('Email is already registered'), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('grace@x.com'), findsOneWidget);
      expect(result, isNull);
    });
  });
}
