import 'dart:convert';

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
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_points_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_edit_page.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_page.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/chart_web_panel.dart';
import 'package:maura_bastion_system/features/login/data/auth_session_store.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSessionStore extends AuthSessionStore {
  @override
  Future<void> save(String token) async {}
  @override
  Future<String?> load() async => null;
  @override
  Future<void> clear() async {}
}

/// Wraps a handler so `GET /maura/v1/bastions/browse` returns an empty page
/// with hasMore: false. The cubit's loadBastions now fetches getMine() +
/// browse(page: 1); browse serves nothing extra here, so the page still
/// renders exactly the bastion these mocks return from `/maura/v1/bastions`.
MockClient _withEmptyBrowsePage(
  Future<http.Response> Function(http.Request request) handler,
) {
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
    return handler(request);
  });
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GetIt.I.reset();
  });

  testWidgets(
    'empty bastion still shows Construct Facility, Hirelings and Defenders containers',
    (tester) async {
      final mockClient = _withEmptyBrowsePage((request) async {
        if (request.url.path == '/maura/v1/bastions' &&
            request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                {
                  'id': 'bastion_empty',
                  'userId': 'user_1',
                  'name': 'Empty Bastion',
                  'description': 'An empty stronghold awaiting its lord.',
                  'facilities': [],
                },
              ],
            }),
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

      await tester.pumpWidget(
        BlocProvider<AuthCubit>(
          create: (_) => authCubit,
          child: const MaterialApp(
            home: BastionPage(bastionId: 'bastion_empty', isUserBastion: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Construct Facility'), findsOneWidget);
      expect(find.text('Hirelings of Empty Bastion'), findsOneWidget);
      expect(find.text('Defenders of Empty Bastion'), findsOneWidget);
      expect(find.text('No hirelings recruited yet'), findsOneWidget);
      expect(
        find.text('No defenders stationed at this bastion'),
        findsOneWidget,
      );
    },
  );

  Map<String, dynamic> turnFacilityJson({
    required String id,
    required String name,
    String rank = 'd',
    String description = 'desc',
    int constructed = 0,
    int total = 0,
    int requiredHirelings = 0,
    Map<String, dynamic>? table,
  }) =>
      {
        'id': id,
        'name': name,
        'rank': rank,
        'description': description,
        'constructionTurns': total,
        'constructedTurns': constructed,
        'minimumRequiredHirelings': requiredHirelings,
        'cost': 0,
        'table': ?table,
      };

  MockClient bastionTurnMockClient(List<Map<String, dynamic>> facilities,
      {List<Map<String, dynamic>> hirelings = const [],
      List<http.Request>? capturedPuts,
      bool discordTurnSucceeds = true}) {
    return _withEmptyBrowsePage((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/bastions') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': [
              {
                'id': 'bastion_1',
                'userId': 'user_1',
                'name': 'Test Bastion',
                'description': 'A test stronghold.',
                'facilities': facilities,
                'hirelings': hirelings,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'PUT' &&
          request.url.path.startsWith('/maura/v1/facilities/')) {
        capturedPuts?.add(request);
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': jsonDecode(request.body),
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'POST' &&
          request.url.path ==
              '/maura/v1/discord/individual-bastion-turn') {
        if (!discordTurnSucceeds) {
          return http.Response(
            jsonEncode({'success': false, 'message': 'webhook unreachable'}),
            500,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
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
  }

  Future<void> pumpBastionPage(WidgetTester tester,
      {required bool isUserBastion, required MockClient mockClient}) async {
    final apiClient = ApiClient(baseUrl: 'http://example.test', client: mockClient);
    GetIt.I.registerSingleton<BastionApi>(BastionApi(client: apiClient));
    GetIt.I.registerSingleton<FacilityApi>(FacilityApi(client: apiClient));
    GetIt.I.registerSingleton<HirelingApi>(HirelingApi(client: apiClient));
    GetIt.I.registerSingleton<DiscordApi>(DiscordApi(client: apiClient));
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

    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => authCubit,
        child: MaterialApp(
          home: BastionPage(bastionId: 'bastion_1', isUserBastion: isUserBastion),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('FAB is hidden for non-user bastions', (tester) async {
    await pumpBastionPage(
      tester,
      isUserBastion: false,
      mockClient: bastionTurnMockClient([
        turnFacilityJson(id: 'keep', name: 'Keep'),
      ]),
    );

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('FAB takes a turn: advances construction and opens the flow dialog',
      (tester) async {
    final puts = <http.Request>[];
    await pumpBastionPage(
      tester,
      isUserBastion: true,
      mockClient: bastionTurnMockClient(
        [
          turnFacilityJson(
            id: 'keep',
            name: 'Keep',
            description: 'A sturdy keep.',
            table: {
              'table': [
                ['d4', 'Effect'],
                ['1', 'Bonus gold'],
              ],
            },
          ),
          turnFacilityJson(
              id: 'barracks', name: 'Barracks', constructed: 0, total: 2),
          turnFacilityJson(
              id: 'kitchen',
              name: 'Kitchen',
              rank: 'c',
              requiredHirelings: 2),
        ],
        hirelings: [
          {
            'id': 'h1',
            'name': 'Anna',
            'bastionId': 'bastion_1',
            'facilityId': 'kitchen',
          },
        ],
        capturedPuts: puts,
      ),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Quest gate appears first, asking for the quest text.
    expect(find.text('Quest:'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Cleared the crypt');
    // Flush the rebuild so Confirm (enabled by onChanged setState) is tappable.
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // The chart web flow dialog is up (either phase).
    expect(find.text('Bastion Turn'), findsOneWidget);
    expect(find.text('Individual Event'), findsOneWidget);

    // Resolution now happens BEFORE the advance — the PUT only fires once
    // the turn is resolved and the dialog is dismissed with Done.
    if (find.text('Resolve').evaluate().isNotEmpty) {
      await tester.tap(find.text('Resolve'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // The Discord gate passed and the under-construction facility advanced.
    expect(puts, hasLength(1));
    expect(find.text('Bastion Turn'), findsNothing);
  });

  testWidgets('bastion turn uses the chart web flow dialog', (tester) async {
    await pumpBastionPage(
      tester,
      isUserBastion: true,
      mockClient: bastionTurnMockClient(
        [
          turnFacilityJson(
            id: 'keep',
            name: 'Keep',
            description: 'A sturdy keep.',
          ),
          turnFacilityJson(
              id: 'barracks', name: 'Barracks', constructed: 0, total: 2),
        ],
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'quest');
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // The new flow dialog is up (either phase) — old dialog content is gone.
    expect(find.text('Bastion Turn'), findsOneWidget);
    expect(find.text('Individual Event'), findsOneWidget);
    expect(find.textContaining('Construction advanced'), findsNothing);
    expect(find.text('No facilities ready to grant buffs this turn.'),
        findsNothing);
  });

  testWidgets(
      'FAB turn with a failing Discord log shows the error snackbar and does not open the dialog',
      (tester) async {
    final puts = <http.Request>[];
    await pumpBastionPage(
      tester,
      isUserBastion: true,
      mockClient: bastionTurnMockClient(
        [
          turnFacilityJson(
              id: 'barracks', name: 'Barracks', constructed: 0, total: 2),
        ],
        capturedPuts: puts,
        discordTurnSucceeds: false,
      ),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Quest:'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Cleared the crypt');
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    // The flow dialog is resolved BEFORE the advance, so it opens even when
    // the Discord log later fails.
    expect(find.text('Bastion Turn'), findsOneWidget);
    if (find.text('Resolve').evaluate().isNotEmpty) {
      await tester.tap(find.text('Resolve'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(
      find.text('Turn could not be advanced'),
      findsOneWidget,
    );
    expect(find.text('Bastion Turn'), findsNothing);
    expect(
      find.textContaining('Construction advanced'),
      findsNothing,
    );
    expect(puts, isEmpty);
  });

  testWidgets('FAB turn is aborted when the quest dialog is cancelled',
      (tester) async {
    await pumpBastionPage(
      tester,
      isUserBastion: true,
      mockClient: bastionTurnMockClient([
        turnFacilityJson(
            id: 'barracks', name: 'Barracks', constructed: 0, total: 2),
      ]),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Quest:'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Bastion Turn'), findsNothing);
  });

  testWidgets(
      'upgrading a facility from its page POPTS it back at the next rank',
      (tester) async {
    var puts = 0;
    var firstBastionGet = true;
    final mockClient = _withEmptyBrowsePage((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/bastions') {
        final rankField = firstBastionGet ? 'd' : 'c';
        firstBastionGet = false;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': [
              {
                'id': 'bastion_1',
                'userId': 'user_1',
                'name': 'Test Bastion',
                'description': 'A test stronghold.',
                'facilities': [
                  turnFacilityJson(
                    id: 'cat_barracks',
                    name: 'Barracks',
                    rank: rankField,
                    constructed: rankField == 'd' ? 2 : 0,
                    total: rankField == 'd' ? 2 : 2,
                  ),
                ],
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/hirelings') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': <Object>[],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'PUT' &&
          request.url.path == '/maura/v1/facilities/cat_barracks') {
        puts++;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': jsonDecode(request.body),
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'POST' &&
          request.url.path == '/maura/v1/discord/facility-rank-up') {
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
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

    final apiClient =
        ApiClient(baseUrl: 'http://example.test', client: mockClient);
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

    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => authCubit,
        child: const MaterialApp(
          home: BastionPage(bastionId: 'bastion_1', isUserBastion: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Barracks'));
    await tester.pumpAndSettle();

    expect(find.text('Upgrade to Rank C — 900 GP'), findsOneWidget);

    await tester.ensureVisible(find.text('Upgrade to Rank C — 900 GP'));
    await tester.tap(find.text('Upgrade to Rank C — 900 GP'));
    await tester.pumpAndSettle();

    expect(puts, 1);
    expect(find.text('Upgrade to Rank C — 900 GP'), findsNothing);
    expect(find.text('Barracks'), findsWidgets);
  });

  testWidgets('shows an edit action for the user bastion and opens the edit page',
      (tester) async {
    final mockClient = _withEmptyBrowsePage((request) async {
      if (request.url.path == '/maura/v1/bastions' &&
          request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': [
              {
                'id': 'bastion_empty',
                'userId': 'user_1',
                'name': 'Empty Bastion',
                'description': 'An empty stronghold awaiting its lord.',
                'facilities': [],
              },
            ],
          }),
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

    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => authCubit,
        child: const MaterialApp(
          home: BastionPage(bastionId: 'bastion_empty', isUserBastion: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Edit Bastion'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit Bastion'));
    await tester.pumpAndSettle();

    expect(find.byType(BastionEditPage), findsOneWidget);
    expect(find.text('Empty Bastion'), findsOneWidget);
  });

  testWidgets('Chart Web button opens the allocation panel', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpBastionPage(
      tester,
      isUserBastion: true,
      mockClient: bastionTurnMockClient([
        turnFacilityJson(id: 'keep', name: 'Keep'),
      ]),
    );

    await tester.tap(find.text('Chart Web'));
    await tester.pumpAndSettle();

    expect(find.text('The Chart Web'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);
  });

  testWidgets('reopening Chart Web preserves allocations', (tester) async {
    await pumpBastionPage(
      tester,
      isUserBastion: true,
      mockClient: bastionTurnMockClient([
        turnFacilityJson(id: 'f1', name: 'Keep'),
        turnFacilityJson(id: 'f2', name: 'Barracks'),
        turnFacilityJson(id: 'f3', name: 'Kitchen'),
        turnFacilityJson(id: 'f4', name: 'Library'),
        turnFacilityJson(id: 'f5', name: 'Garden'),
        turnFacilityJson(id: 'f6', name: 'Forge'),
      ]),
    );

    await tester.tap(find.text('Chart Web'));
    await tester.pumpAndSettle();

    final pointsCubit =
        tester.element(find.byType(ChartWebPanel)).read<ChartPointsCubit>();
    pointsCubit.assign(EventChart.wilds, 2);
    await tester.pumpAndSettle();
    expect(find.text('4 of 6 points unassigned'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chart Web'));
    await tester.pumpAndSettle();

    expect(find.text('The Chart Web'), findsOneWidget);
    expect(find.text('4 of 6 points unassigned'), findsOneWidget);
  });

  testWidgets('hides the edit action for other players bastions',
      (tester) async {
    final mockClient = _withEmptyBrowsePage((request) async {
      if (request.url.path == '/maura/v1/bastions' &&
          request.method == 'GET') {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'ok',
            'data': [
              {
                'id': 'bastion_other',
                'userId': 'user_2',
                'name': 'Foreign Bastion',
                'description': 'Not yours.',
                'facilities': [],
              },
            ],
          }),
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

    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => authCubit,
        child: const MaterialApp(
          home: BastionPage(bastionId: 'bastion_other', isUserBastion: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Edit Bastion'), findsNothing);
  });
}
