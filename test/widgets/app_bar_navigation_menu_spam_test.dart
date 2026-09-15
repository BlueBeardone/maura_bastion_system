import 'dart:async';

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
import 'package:maura_bastion_system/data/models/bastion/bastion_page.dart'
    as bastion_page;
import 'package:maura_bastion_system/data/models/user/user.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_page.dart';
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

/// getMine() stays pending until [completeWith] is called, so the test can tap
/// the menu item repeatedly while the fetch is still in flight. loadBastions
/// now fetches getMine() + browse(page: 1); browse serves an empty page so
/// only the caller's own bastion is present.
class _GatedBastionApi extends BastionApi {
  _GatedBastionApi()
      : super(
          client: ApiClient(
            baseUrl: 'http://example.test',
            client: MockClient((_) async => http.Response('not found', 404)),
          ),
        );

  int getMineCalls = 0;
  final Completer<List<Bastion>> _gate = Completer();

  void completeWith(List<Bastion> bastions) => _gate.complete(bastions);

  @override
  Future<List<Bastion>> getMine() {
    getMineCalls++;
    return _gate.future;
  }

  @override
  Future<bastion_page.BastionPage> browse({int page = 1, int limit = 20}) async =>
      const bastion_page.BastionPage(
        bastions: [],
        page: 1,
        limit: 20,
        total: 0,
        hasMore: false,
      );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'tapping Overview repeatedly while loading pushes only one BastionPage',
    (tester) async {
      final bastionApi = _GatedBastionApi();
      GetIt.I.registerSingleton<BastionApi>(bastionApi);
      GetIt.I.registerSingleton<FacilityApi>(
        FacilityApi(
          client: ApiClient(
            baseUrl: 'http://example.test',
            client: MockClient((_) async => http.Response('not found', 404)),
          ),
        ),
      );
      GetIt.I.registerSingleton<HirelingApi>(
        HirelingApi(
          client: ApiClient(
            baseUrl: 'http://example.test',
            client: MockClient((_) async => http.Response('not found', 404)),
          ),
        ),
      );
      GetIt.I.registerSingleton<DiscordAnnouncer>(
        DiscordAnnouncer(
          discordApi: DiscordApi(
            client: ApiClient(
              baseUrl: 'http://example.test',
              client: MockClient((_) async => http.Response('not found', 404)),
            ),
          ),
        ),
      );

      final authCubit = AuthCubit(
        identityApi: _StubIdentityApi(
          ApiClient(
            baseUrl: 'http://example.test',
            client: MockClient((_) async => http.Response('not found', 404)),
          ),
        ),
        apiClient: ApiClient(
          baseUrl: 'http://example.test',
          client: MockClient((_) async => http.Response('not found', 404)),
        ),
        sessionStore: _FakeSessionStore(),
      );
      GetIt.I.registerSingleton<AuthCubit>(authCubit);
      await authCubit.login('admin', 'secret');

      // The test fonts render every glyph as a fontSize-wide square, making
      // the app bar menu wider than in production; use a desktop-sized surface
      // so the menu items are not clipped.
      tester.view.physicalSize = const Size(1600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: Scaffold(
              appBar: AppBar(
                title: AppBarNavigationMenu(
                  navigationItems: const [MainNavigation.facility],
                ),
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The Overview item is only visible once bastions have loaded and the
      // user owns one (see 15f633c), so complete the gated fetch first.
      bastionApi.completeWith([
        Bastion(
          id: 'bastion_1',
          userId: '1',
          name: 'Test Bastion',
          description: 'A test bastion.',
          facilities: const [],
        ),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Overview'));
      await tester.tap(find.text('Overview'));
      await tester.tap(find.text('Overview'));

      await tester.pumpAndSettle();

      expect(bastionApi.getMineCalls, 3,
          reason:
              'one initial fetch + one menu reload after navigation + one from '
              'the pushed BastionPage itself; spamming the menu item must not '
              'trigger repeated navigation fetches');
      expect(
        find.byType(BastionPage, skipOffstage: false),
        findsOneWidget,
        reason: 'spamming the menu item must not stack duplicate pages',
      );
    },
  );
}
