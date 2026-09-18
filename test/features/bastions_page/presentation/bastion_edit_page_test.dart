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
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_edit_page.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';

// Every mock intercepts `GET /maura/v1/bastions/browse` and returns an empty
// page with hasMore: false. The cubit's loadBastions fetches getMine() +
// browse(page: 1); getMine() hits the same `/maura/v1/bastions` endpoint the
// handlers below already serve.
MockClient _mock(void Function(http.Request) onRequest,
    Future<http.Response> Function(http.Request) handler) {
  return MockClient((request) async {
    if (request.method == 'GET' &&
        request.url.path == '/maura/v1/bastions/browse') {
      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'ok',
          'data': {
            'bastions': [],
            'page': 1,
            'limit': 20,
            'total': 0,
            'hasMore': false,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    onRequest(request);
    return handler(request);
  });
}

class _FakeSessionStore extends AuthSessionStore {
  @override
  Future<void> save(String token) async {}
  @override
  Future<String?> load() async => null;
  @override
  Future<void> clear() async {}
}

// StandardScaffold renders an AppBar with AppBarNavigationMenu, which reads
// these from GetIt. Register fakes so the page can be pumped in widget tests.
Future<void> _registerGetItDependencies(ApiClient apiClient) async {
  await GetIt.I.reset();
  GetIt.I.registerSingleton<BastionApi>(BastionApi(client: apiClient));
  GetIt.I.registerSingleton<FacilityApi>(FacilityApi(client: apiClient));
  GetIt.I.registerSingleton<DiscordAnnouncer>(
    DiscordAnnouncer(discordApi: DiscordApi(client: apiClient)),
  );
  final sessionStore = _FakeSessionStore();
  GetIt.I.registerSingleton<AuthCubit>(
    AuthCubit(
      identityApi: IdentityApi(client: apiClient, sessionStore: sessionStore),
      apiClient: apiClient,
      sessionStore: sessionStore,
    ),
  );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  BastionCubit buildCubit(MockClient mock) {
    final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
    return BastionCubit(
      bastionApi: BastionApi(client: apiClient),
      facilityApi: FacilityApi(client: apiClient),
    );
  }

  Future<BastionCubit> makeLoadedCubit(MockClient mock) async {
    final cubit = buildCubit(mock);
    await cubit.loadBastions();
    return cubit;
  }

  testWidgets('pre-fills name, description and image URL', (tester) async {
    final mock = _mock((_) {}, (request) async {
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/bastions') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': [
              {
                'id': 'bastion-1',
                'userId': 'user_1',
                'name': 'Shadowfen Keep',
                'description': 'A misty stronghold.',
                'imgUrl': 'https://example.com/keep.png',
                'facilities': [],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({'success': false, 'message': 'unexpected'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    });
    await _registerGetItDependencies(
        ApiClient(baseUrl: 'http://example.test', client: mock));
    final cubit = await makeLoadedCubit(mock);
    final bastion = (cubit.state as BastionLoadedState).userBastion!;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BastionEditPage(bastion: bastion, bastionCubit: cubit),
      ),
    ));

    expect(find.text('Shadowfen Keep'), findsOneWidget);
    expect(find.text('A misty stronghold.'), findsOneWidget);
    expect(find.text('https://example.com/keep.png'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('blocks save with empty name and makes no API call',
      (tester) async {
    final puts = <http.Request>[];
    final mock = _mock(
      (r) {
        if (r.method == 'PUT') puts.add(r);
      },
      (request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                {
                  'id': 'bastion-1',
                  'userId': 'user_1',
                  'name': 'Shadowfen Keep',
                  'description': 'A misty stronghold.',
                  'facilities': [],
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': false, 'message': 'unexpected'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      },
    );
    await _registerGetItDependencies(
        ApiClient(baseUrl: 'http://example.test', client: mock));
    final cubit = await makeLoadedCubit(mock);
    final bastion = (cubit.state as BastionLoadedState).userBastion!;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BastionEditPage(bastion: bastion, bastionCubit: cubit),
      ),
    ));

    await tester.enterText(find.byType(TextFormField).at(0), '   ');
    await tester.tap(find.text('Save Changes'));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(puts, isEmpty);
    await cubit.close();
  });

  testWidgets('rejects an invalid image URL format without an API call',
      (tester) async {
    final puts = <http.Request>[];
    final mock = _mock(
      (r) {
        if (r.method == 'PUT') puts.add(r);
      },
      (request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                {
                  'id': 'bastion-1',
                  'userId': 'user_1',
                  'name': 'Shadowfen Keep',
                  'description': 'A misty stronghold.',
                  'facilities': [],
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': false, 'message': 'unexpected'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      },
    );
    await _registerGetItDependencies(
        ApiClient(baseUrl: 'http://example.test', client: mock));
    final cubit = await makeLoadedCubit(mock);
    final bastion = (cubit.state as BastionLoadedState).userBastion!;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BastionEditPage(bastion: bastion, bastionCubit: cubit),
      ),
    ));

    await tester.enterText(find.byType(TextFormField).at(2), 'not a url');
    await tester.tap(find.text('Save Changes'));
    await tester.pump();

    expect(find.text('Please enter a valid URL (https://...)'), findsOneWidget);
    expect(puts, isEmpty);
    await cubit.close();
  });

  testWidgets('successful save PUTs the update and pops back', (tester) async {
    final puts = <http.Request>[];
    Map<String, dynamic> bastionJson = {
      'id': 'bastion-1',
      'userId': 'user_1',
      'name': 'Shadowfen Keep',
      'description': 'A misty stronghold.',
      'facilities': [],
    };
    final mock = _mock(
      (r) {
        if (r.method == 'PUT') puts.add(r);
      },
      (request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/bastions') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [bastionJson],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT' &&
            request.url.path == '/maura/v1/bastions/bastion-1') {
          // Already recorded by the onRequest hook above.
          bastionJson = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': bastionJson}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': false, 'message': 'unexpected'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      },
    );
    await _registerGetItDependencies(
        ApiClient(baseUrl: 'http://example.test', client: mock));
    final cubit = await makeLoadedCubit(mock);
    final bastion = (cubit.state as BastionLoadedState).userBastion!;

    await tester.pumpWidget(MaterialApp(
      home: const Scaffold(body: Text('Home')),
      routes: {
        '/edit': (_) => Scaffold(
              body: BastionEditPage(bastion: bastion, bastionCubit: cubit),
            ),
      },
      initialRoute: '/edit',
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Ravencrest');
    await tester.enterText(find.byType(TextFormField).at(1), 'New description');
    // Image URL left untouched and empty → no reachability check, cleared null.
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(puts, hasLength(1));
    final body = jsonDecode(puts.first.body) as Map<String, dynamic>;
    expect(body['name'], 'Ravencrest');
    expect(body['description'], 'New description');
    expect(body['imgUrl'], isNull);
    await cubit.close();
  });

  testWidgets('shows the server error and stays on the form on failure',
      (tester) async {
    final mock = _mock((_) {}, (request) async {
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/bastions') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': [
              {
                'id': 'bastion-1',
                'userId': 'user_1',
                'name': 'Shadowfen Keep',
                'description': 'A misty stronghold.',
                'facilities': [],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'PUT' &&
          request.url.path == '/maura/v1/bastions/bastion-1') {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Not your bastion'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode({'success': false, 'message': 'unexpected'}),
        404,
        headers: {'content-type': 'application/json'},
      );
    });
    await _registerGetItDependencies(
        ApiClient(baseUrl: 'http://example.test', client: mock));
    final cubit = await makeLoadedCubit(mock);
    final bastion = (cubit.state as BastionLoadedState).userBastion!;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BastionEditPage(bastion: bastion, bastionCubit: cubit),
      ),
    ));

    await tester.tap(find.text('Save Changes'));
    await tester.pump();

    expect(find.text('Not your bastion'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    await cubit.close();
  });
}
