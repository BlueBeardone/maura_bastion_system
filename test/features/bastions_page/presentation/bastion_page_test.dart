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
import 'package:maura_bastion_system/api/facility_api.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_page.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bastion_turn_dialog.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GetIt.I.reset();
  });

  testWidgets(
    'empty bastion still shows Construct Facility, Hirelings and Defenders containers',
    (tester) async {
      final mockClient = MockClient((request) async {
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

      final authCubit = AuthCubit(identityApi: IdentityApi(client: apiClient));
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
      {List<Map<String, dynamic>> hirelings = const []}) {
    return MockClient((request) async {
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
    final authCubit = AuthCubit(identityApi: IdentityApi(client: apiClient));
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

  testWidgets('FAB takes a turn: advances construction and shows eligible facilities',
      (tester) async {
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
      ),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Dialog is open, construction advanced for the first under-construction facility.
    expect(find.text('Bastion Turn'), findsOneWidget);
    expect(
      find.textContaining('Construction advanced: Barracks (1/2 turns)'),
      findsOneWidget,
    );

    // Only eligible (built + staffed) facilities are listed in the dialog.
    final dialogFinder = find.byType(BastionTurnDialog);
    expect(find.descendant(of: dialogFinder, matching: find.text('Keep')),
        findsOneWidget);
    expect(find.descendant(of: dialogFinder, matching: find.text('Barracks')),
        findsNothing);
    expect(find.descendant(of: dialogFinder, matching: find.text('Kitchen')),
        findsNothing);

    // Expanding reveals the description and the table.
    await tester.tap(find.descendant(of: dialogFinder, matching: find.text('Keep')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: dialogFinder, matching: find.text('A sturdy keep.')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialogFinder, matching: find.text('Facility Table')),
      findsOneWidget,
    );
  });
}
