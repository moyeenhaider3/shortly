import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_shortener_client/core/network/api_client.dart';
import 'package:url_shortener_client/presentation/features/dashboard/cubit/alias_check_cubit.dart';
import 'package:url_shortener_client/presentation/features/dashboard/widgets/alias_field.dart';
import 'package:url_shortener_client/presentation/theme/app_theme.dart';
import 'package:url_shortener_client/repositories/url_repository.dart';

/// Answers from a map; each call can be delayed to simulate slow responses.
class FakeUrlRepository extends UrlRepository {
  final Map<String, ({bool available, String? reason})> answers;
  final Map<String, Duration> delays;
  final List<String> calls = [];

  FakeUrlRepository(SharedPreferences prefs, this.answers, {this.delays = const {}})
    : super(apiClient: ApiClient(prefs));

  @override
  Future<({bool available, String? reason})> checkAliasAvailability(String alias) async {
    calls.add(alias);
    await Future<void>.delayed(delays[alias] ?? Duration.zero);
    final answer = answers[alias];
    if (answer == null) throw Exception('network down');
    return answer;
  }
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('AliasCheckCubit', () {
    test('invalid input is rejected instantly without a request', () {
      final repo = FakeUrlRepository(prefs, {});
      final cubit = AliasCheckCubit(repo, debounce: const Duration(milliseconds: 10));
      cubit.onChanged('ab');
      expect(cubit.state.status, AliasStatus.invalid);
      cubit.onChanged('login');
      expect(cubit.state.message, contains('reserved'));
      expect(repo.calls, isEmpty);
      cubit.close();
    });

    test('debounces typing into one request', () async {
      final repo = FakeUrlRepository(prefs, {'promo': (available: true, reason: null)});
      final cubit = AliasCheckCubit(repo, debounce: const Duration(milliseconds: 20));
      for (final s in ['pro', 'prom', 'promo']) {
        cubit.onChanged(s);
      }
      expect(cubit.state.status, AliasStatus.checking);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(repo.calls, ['promo']);
      expect(cubit.state.status, AliasStatus.available);
      await cubit.close();
    });

    test('a slow stale response never overwrites a newer one', () async {
      final repo = FakeUrlRepository(
        prefs,
        {'first': (available: true, reason: null), 'second': (available: false, reason: 'Alias is already taken')},
        delays: {'first': const Duration(milliseconds: 80)},
      );
      final cubit = AliasCheckCubit(repo, debounce: Duration.zero);
      cubit.onChanged('first');
      await Future<void>.delayed(const Duration(milliseconds: 5)); // "first" request in flight
      cubit.onChanged('second');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(repo.calls, ['first', 'second']);
      expect(cubit.state.status, AliasStatus.taken);
      expect(cubit.state.message, 'Alias is already taken');
      expect(cubit.state.blocksSubmit, isTrue);
      await cubit.close();
    });

    test('a failed check is "unknown", which does not block submit', () async {
      final cubit = AliasCheckCubit(FakeUrlRepository(prefs, {}), debounce: Duration.zero);
      cubit.onChanged('offline');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cubit.state.status, AliasStatus.unknown);
      expect(cubit.state.blocksSubmit, isFalse);
      await cubit.close();
    });
  });

  testWidgets('AliasField shows the server reason after the debounce', (tester) async {
    final repo = FakeUrlRepository(prefs, {'taken-one': (available: false, reason: 'Alias is already taken')});
    final cubit = AliasCheckCubit(repo, debounce: const Duration(milliseconds: 400));
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: AliasField(controller: controller, domainPrefix: 'localhost:5000/'),
          ),
        ),
      ),
    );

    expect(find.text('localhost:5000/'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'taken-one');
    await tester.pump();
    expect(find.text('Checking availability…'), findsOneWidget);

    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 450)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Alias is already taken'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);

    await cubit.close();
  });
}
