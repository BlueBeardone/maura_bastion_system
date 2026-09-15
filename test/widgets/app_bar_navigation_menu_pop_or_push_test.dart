import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/discord_api.dart';
import 'package:maura_bastion_system/api/dto/login_request.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/data/enums/main_navigation_enum.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/user/user.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_main_screen.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';
import 'package:maura_bastion_system/widgets/standard_scaffold/app_bar_navigation_menu.dart';

class _FakeSessionStore extends AuthSessionStore {
  @override
  Future<void> save(String token) async {}
  @override
  Future<String?> load() async => null;
  @override
  Future<void> clear() async {}
}

class _StubIdentityApi extends IdentityApi {
  _StubIdentityApi(ApiClient client)
      : super(client: client, sessionStore: _FakeSessionStore());

  @override
  Future<User> login(LoginRequest request) async {
    return User(id: '1', displayName: 'Admin');
  }
}

class _StubBastionApi extends BastionApi {
  _StubBastionApi()
      : super(
          client: ApiClient(
            baseUrl: 'http://example.test',
            client: MockClient((_) async => http.Response('not found', 404)),
          ),
        );

  @override
  Future<List<Bastion>> getAll() async => const <Bastion>[];
}

ApiClient _stubClient() => ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((_) async => http.Response('not found', 404)),
    );

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GetIt.I.reset();
    AppBarNavigationMenu.activeRouteNames.clear();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Future<void> pumpHost(WidgetTester tester) async {
    GetIt.I.registerSingleton<BastionApi>(_StubBastionApi());
    GetIt.I.registerSingleton<FacilityApi>(FacilityApi(client: _stubClient()));
    GetIt.I.registerSingleton<HirelingApi>(HirelingApi(client: _stubClient()));
    GetIt.I.registerSingleton<DiscordAnnouncer>(
      DiscordAnnouncer(discordApi: DiscordApi(client: _stubClient())),
    );
    final authCubit = AuthCubit(
      identityApi: _StubIdentityApi(_stubClient()),
      apiClient: _stubClient(),
      sessionStore: _FakeSessionStore(),
    );
    GetIt.I.registerSingleton<AuthCubit>(authCubit);
    await authCubit.login('admin', 'secret');

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: Scaffold(
            appBar: AppBar(
              title: AppBarNavigationMenu(
                navigationItems: const [
                  MainNavigation.newspaper,
                  MainNavigation.bastions,
                ],
              ),
            ),
            body: const Center(child: Text('root')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping Bastions twice pushes only one BastionMainScreen',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('Bastions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bastions').last);
    await tester.pumpAndSettle();

    expect(
      find.byType(BastionMainScreen, skipOffstage: false),
      findsOneWidget,
      reason: 'pressing Bastions on the Bastions page must not stack '
          'a duplicate',
    );
  });

  testWidgets('tapping Newspaper from a pushed page pops back to root',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('Bastions').last);
    await tester.pumpAndSettle();
    expect(find.byType(BastionMainScreen, skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('Newspaper').last);
    await tester.pumpAndSettle();

    expect(find.byType(BastionMainScreen, skipOffstage: false), findsNothing);
    expect(find.text('root'), findsOneWidget);
  });

  testWidgets('tapping Newspaper at the root is a no-op', (tester) async {
    await pumpHost(tester);

    await tester.tap(find.text('Newspaper').last);
    await tester.pumpAndSettle();

    expect(find.text('root'), findsOneWidget);
  });
}
