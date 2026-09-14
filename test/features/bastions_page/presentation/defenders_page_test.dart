import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/defender_api.dart';
import 'package:maura_bastion_system/api/discord_api.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defenders_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/defenders_page.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/bulk_recruit_form.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/widgets/defender_detail_sheet.dart';

Defender testDefender() => Defender(
      id: 'd1',
      name: 'Sir Cadogan',
      type: DefenderType.knight,
      description: 'A brave but reckless knight.',
      bastionId: 'bastion-1',
      acquisitionStory: 'Won at a card game.',
    );

Future<void> pumpSheet(WidgetTester tester, {bool canRemove = true}) async {
  await tester.pumpWidget(
    BlocProvider<DefendersCubit>(
      create: (_) => DefendersCubit(
        bastionId: 'bastion-1',
        defenderApi: GetIt.I<DefenderApi>(),
      ),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (sheetContext) => Center(
              child: TextButton(
                onPressed: () => showModalBottomSheet(
                  context: sheetContext,
                  builder: (_) => DefenderDetailSheet(
                    defender: testDefender(),
                    canRemove: canRemove,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  http.Request? deleteRequest;
  var deleteSucceeds = true;

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await GetIt.I.reset();
    deleteRequest = null;
    deleteSucceeds = true;
    final apiClient = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/defenders') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                {
                  'id': 'd1',
                  'name': 'Sir Cadogan',
                  'type': 'knight',
                  'description': 'A brave but reckless knight.',
                  'bastionId': 'bastion-1',
                  'acquisitionStory': 'Won at a card game.',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'DELETE' &&
            request.url.path == '/maura/v1/defenders/d1') {
          deleteRequest = request;
          if (!deleteSucceeds) {
            return http.Response(
              jsonEncode({'success': false, 'message': 'boom'}),
              500,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': null}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'success': false, 'message': 'unexpected'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    GetIt.I.registerSingleton<DefenderApi>(DefenderApi(client: apiClient));
    GetIt.I.registerSingleton<DiscordAnnouncer>(
      DiscordAnnouncer(discordApi: DiscordApi(client: apiClient)),
    );
  });

  Future<void> pumpDefendersPage(
    WidgetTester tester, {
    bool canManage = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefendersPage(
          bastionId: 'bastion-1',
          bastionName: 'Test Bastion',
          canManage: canManage,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('detail sheet shows defender name, type, description and story',
      (tester) async {
    await pumpSheet(tester);

    expect(find.text('Sir Cadogan'), findsOneWidget);
    expect(find.text('Knight'), findsOneWidget);
    expect(find.text('A brave but reckless knight.'), findsOneWidget);
    expect(find.text('Won at a card game.'), findsOneWidget);
    expect(find.text('Remove from Bastion'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation keeps the sheet open',
      (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Remove from Bastion'));
    await tester.pumpAndSettle();

    expect(find.text('Remove Sir Cadogan?'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Dialog is gone, sheet is still open with the defender info.
    expect(find.text('Remove Sir Cadogan?'), findsNothing);
    expect(find.text('Sir Cadogan'), findsOneWidget);
    expect(find.text('Remove from Bastion'), findsOneWidget);
  });

  testWidgets(
      'confirming remove DELETEs the defender, closes the sheet and shows a snackbar',
      (tester) async {
    await pumpDefendersPage(tester);
    expect(find.text('Sir Cadogan'), findsOneWidget);

    await tester.tap(find.text('Sir Cadogan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove from Bastion'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(deleteRequest, isNotNull);
    expect(deleteRequest!.method, 'DELETE');
    expect(deleteRequest!.url.path, '/maura/v1/defenders/d1');
    expect(find.text('Sir Cadogan'), findsNothing);
    expect(find.text('Defender removed'), findsOneWidget);
  });

  testWidgets('failed removal shows an error snackbar and keeps the defender',
      (tester) async {
    deleteSucceeds = false;

    await pumpDefendersPage(tester);

    await tester.tap(find.text('Sir Cadogan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove from Bastion'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong — please try again'),
        findsOneWidget);
    // The name appears on both the card and the still-open sheet.
    expect(find.text('Sir Cadogan'), findsWidgets);
    expect(find.text('Remove from Bastion'), findsOneWidget);
  });

  testWidgets(
      'read-only page (another player\'s bastion) hides add FAB, '
      'add drawer and remove button', (tester) async {
    await pumpDefendersPage(tester, canManage: false);
    expect(find.text('Sir Cadogan'), findsOneWidget);

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Enlist a New Defender'), findsNothing);

    await tester.tap(find.text('Sir Cadogan'));
    await tester.pumpAndSettle();

    expect(find.text('Remove from Bastion'), findsNothing);
  });

  testWidgets('read-only detail sheet offers no remove control',
      (tester) async {
    await pumpSheet(tester, canRemove: false);

    expect(find.text('Sir Cadogan'), findsOneWidget);
    expect(find.text('Remove from Bastion'), findsNothing);
  });

  testWidgets('end drawer shows Enlist One and Bulk Recruit tabs and the '
      'bulk form enlists the requested defenders', (tester) async {
    final defenderPosts = <http.Request>[];
    final discordPosts = <http.Request>[];
    await GetIt.I.reset();
    final apiClient = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/maura/v1/discord/defender-acquired') {
          discordPosts.add(request);
          return http.Response(
            jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST' &&
            request.url.path == '/maura/v1/defenders') {
          defenderPosts.add(request);
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
        if (request.method == 'GET' &&
            request.url.path == '/maura/v1/defenders') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'ok',
              'data': [
                {
                  'id': 'd1',
                  'name': 'Sir Cadogan',
                  'type': 'knight',
                  'description': 'A brave but reckless knight.',
                  'bastionId': 'bastion-1',
                  'acquisitionStory': 'Won at a card game.',
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
      }),
    );
    GetIt.I.registerSingleton<DefenderApi>(DefenderApi(client: apiClient));
    GetIt.I.registerSingleton<DiscordAnnouncer>(
      DiscordAnnouncer(discordApi: DiscordApi(client: apiClient)),
    );

    await pumpDefendersPage(tester);
    // The FlutterTest font uses fixed-advance glyphs, which overflow the
    // 360-wide drawer's dropdowns; scale text down to mimic device metrics.
    tester.platformDispatcher.textScaleFactorTestValue = 0.8;
    await tester.pump();
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Enlist One'), findsOneWidget);
    expect(find.text('Bulk Recruit'), findsOneWidget);

    await tester.tap(find.text('Bulk Recruit'));
    await tester.pumpAndSettle();

    expect(find.text('Bulk Recruit Defenders'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BulkRecruitForm),
        matching: find.byType(DropdownButtonFormField<DefenderType>),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Knight').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enlist 1 Defender'));
    await tester.pumpAndSettle();

    expect(discordPosts, hasLength(1));
    expect(defenderPosts, hasLength(1));
    final body = jsonDecode(defenderPosts.first.body) as Map<String, dynamic>;
    expect(body['type'], 'knight');
    expect(find.text('1 defender enlisted!'), findsOneWidget);
  });
}
