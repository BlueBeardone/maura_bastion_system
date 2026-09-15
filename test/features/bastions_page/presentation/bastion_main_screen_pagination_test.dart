import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/discord_api.dart';
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_main_screen.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';

class _FakeSessionStore extends AuthSessionStore {
  @override
  Future<void> save(String token) async {}
  @override
  Future<String?> load() async => null;
  @override
  Future<void> clear() async {}
}

Map<String, dynamic> _bastionJson(String id, String name) => {
      'id': id,
      'userId': 'user_$id',
      'name': name,
      'description': 'A bastion for $name.',
      'facilities': [],
    };

Map<String, dynamic> _browsePageJson({
  required List<Map<String, dynamic>> bastions,
  required int page,
  required bool hasMore,
  int total = 2,
}) =>
    {
      'success': true,
      'message': 'ok',
      'data': {
        'bastions': bastions,
        'page': page,
        'limit': 20,
        'total': total,
        'hasMore': hasMore,
      },
    };

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GetIt.I.reset();
  });

  tearDown(() {
    GetIt.I.reset();
  });

  testWidgets(
    'scrolling to the bottom loads page 2 without throwing',
    (tester) async {
      tester.view.physicalSize = const Size(2000, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final browseRequests = <Uri>[];
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions/browse') {
          browseRequests.add(request.url);
          final page = int.parse(request.url.queryParameters['page'] ?? '1');
          if (page == 1) {
            return http.Response(
              jsonEncode(_browsePageJson(
                bastions: [_bastionJson('bastion_p1', 'Bastion One')],
                page: 1,
                hasMore: true,
              )),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (page == 2) {
            return http.Response(
              jsonEncode(_browsePageJson(
                bastions: [_bastionJson('bastion_p2', 'Bastion Two')],
                page: 2,
                hasMore: false,
              )),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode(_browsePageJson(
              bastions: [],
              page: page,
              hasMore: false,
            )),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' && request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': false, 'message': 'not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        baseUrl: 'http://example.test',
        client: mockClient,
      );
      GetIt.I.registerSingleton<BastionApi>(BastionApi(client: apiClient));
      GetIt.I.registerSingleton<FacilityApi>(FacilityApi(client: apiClient));
      GetIt.I.registerSingleton<HirelingApi>(HirelingApi(client: apiClient));
      GetIt.I.registerSingleton<DiscordAnnouncer>(
        DiscordAnnouncer(discordApi: DiscordApi(client: apiClient)),
      );

      final sessionStore = _FakeSessionStore();
      final authCubit = AuthCubit(
        identityApi: IdentityApi(client: apiClient, sessionStore: sessionStore),
        apiClient: apiClient,
        sessionStore: sessionStore,
      );
      GetIt.I.registerSingleton<AuthCubit>(authCubit);

      await tester.pumpWidget(const MaterialApp(home: BastionMainScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Bastion One'), findsOneWidget);

      // Scroll to the bottom repeatedly until page 2 has been fetched and
      // appended (bounded so a regression cannot hang the test).
      for (var i = 0;
          i < 5 && browseRequests.every((u) => u.queryParameters['page'] != '2');
          i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pump();
        await tester.pumpAndSettle();
      }

      // (a) no exception was thrown (the test framework fails on any
      // uncaught FlutterError, e.g. ProviderNotFoundException from a scroll
      // listener using an ancestor context) and (b) page 2 was fetched and
      // appended, so its bastion is visible.
      expect(
        browseRequests.any((u) => u.queryParameters['page'] == '2'),
        isTrue,
        reason: 'scrolling should have triggered browse(page: 2)',
      );
      expect(find.text('Bastion Two'), findsOneWidget);
    },
  );
}
