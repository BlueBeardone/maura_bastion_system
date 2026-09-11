import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/dto/login_request.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/data/models/user/user.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';
import 'package:maura_bastion_system/features/login/logic/auth_state.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/standard_scaffold.dart';

class _FakeSessionStore extends AuthSessionStore {
  @override
  Future<void> save(String token) async {}
  @override
  Future<String?> load() async => null;
  @override
  Future<void> clear() async {}
}

class _StubIdentityApi extends IdentityApi {
  _StubIdentityApi(ApiClient client) : super(client: client, sessionStore: _FakeSessionStore());

  @override
  Future<User> login(LoginRequest request) async {
    return User(id: '1', displayName: 'Admin');
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticatedState) {
          return TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _PushedBody()),
              );
            },
            child: const Text('open page'),
          );
        }

        if (state is AuthLoadingState) {
          return const SizedBox();
        }

        return const Text('login page');
      },
    );
  }
}

class _PushedBody extends StatelessWidget {
  const _PushedBody();

  @override
  Widget build(BuildContext context) {
    return const StandardScaffold(body: Text('pushed page body'));
  }
}

void main() {
  late AuthCubit cubit;
  late _StubIdentityApi api;

  setUp(() {
    api = _StubIdentityApi(ApiClient());
    cubit = AuthCubit(
      identityApi: api,
      apiClient: ApiClient(),
      sessionStore: _FakeSessionStore(),
    );
    GetIt.I.registerSingleton<AuthCubit>(cubit);
  });

  tearDown(() async {
    await GetIt.I.reset();
    await cubit.close();
  });

  Future<void> pumpAppWithPushedScaffold(WidgetTester tester) async {
    // Mirrors main.dart: the AuthCubit provider only scopes the home route.
    await cubit.login('admin', 'secret');
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const _HomeBody(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open page'));
    await tester.pumpAndSettle();
  }

  testWidgets('logout button logs out from a pushed route', (tester) async {
    await pumpAppWithPushedScaffold(tester);

    expect(find.text('pushed page body'), findsOneWidget);
    expect(cubit.state, isA<AuthAuthenticatedState>());

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(cubit.state, isA<AuthUnauthenticatedState>());
  });

  testWidgets('logout button returns to the first route', (tester) async {
    await pumpAppWithPushedScaffold(tester);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('pushed page body'), findsNothing);
    expect(find.text('login page'), findsOneWidget);
  });
}
