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
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/facility_selection_page.dart';
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

BastionCubit _cubit() {
  final mock = MockClient((request) async {
    return http.Response(
      jsonEncode({'success': false, 'message': 'unexpected'}),
      404,
      headers: {'content-type': 'application/json'},
    );
  });
  final apiClient = ApiClient(baseUrl: 'http://example.test', client: mock);
  return BastionCubit(
    bastionApi: BastionApi(client: apiClient),
    facilityApi: FacilityApi(client: apiClient),
  );
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

  Future<void> pumpSelectionPage(
    WidgetTester tester, {
    required List<Facility> facilities,
  }) async {
    final bastion = Bastion(
      id: 'bastion-1',
      name: 'Test Bastion',
      description: 'desc',
      facilities: facilities,
    );
    final cubit = _cubit();
    final apiClient = ApiClient(
      baseUrl: 'http://example.test',
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'unexpected'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    await _registerGetItDependencies(apiClient);

    // The fallback test font renders wider than the app's real fonts and
    // overflows the fixed-width facility card info rows. Scale text down so
    // layout exceptions don't mask the assertions under test.
    tester.platformDispatcher.textScaleFactorTestValue = 0.7;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: FacilitySelectionPage(bastion: bastion, bastionCubit: cubit),
      ),
    );
    await tester.pump();
    addTearDown(cubit.close);
  }

  testWidgets(
    'construction mode disables S-Rank base cards when the bastion already has one',
    (tester) async {
      await pumpSelectionPage(
        tester,
        facilities: [
          Facility(
            id: 'cat_colosseum',
            name: 'Colosseum',
            rank: Rank.S,
            description: 'desc',
          ),
          Facility(
            id: 'cat_bedroom',
            name: 'Bedroom',
            rank: Rank.D,
            description: 'desc',
          ),
        ],
      );

      expect(find.text('Bastion already has an S-Rank facility'), findsWidgets);
    },
  );

  testWidgets('construction mode keeps S-Rank base cards enabled otherwise', (
    tester,
  ) async {
    await pumpSelectionPage(
      tester,
      facilities: [
        Facility(
          id: 'cat_bedroom',
          name: 'Bedroom',
          rank: Rank.D,
          description: 'desc',
        ),
      ],
    );

    expect(find.text('Bastion already has an S-Rank facility'), findsNothing);
  });

  // Pick mode (bastion == null) renders a plain Scaffold with no
  // AppBarNavigationMenu, so no GetIt dependencies are required. The 0.7
  // text scale is reused from the harness above to prevent layout overflow
  // exceptions masking the assertions under test.
  Future<void> pumpPickModePage(WidgetTester tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 0.7;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      const MaterialApp(home: FacilitySelectionPage(bastion: null)),
    );
    await tester.pump();
  }

  testWidgets('pick mode blocks selecting a second S-Rank base facility',
      (tester) async {
    await pumpPickModePage(tester);

    await tester.ensureVisible(find.text('Colosseum'));
    await tester.tap(find.text('Colosseum'));
    await tester.pump();

    await tester.ensureVisible(find.text('Ivory Tower'));
    await tester.tap(find.text('Ivory Tower'));
    await tester.pump();

    expect(find.text('A bastion can only have one S-Rank facility'),
        findsOneWidget);
    expect(find.text('Done (1)'), findsOneWidget);
  });

  testWidgets('pick mode allows selecting an S-Rank base facility first',
      (tester) async {
    await pumpPickModePage(tester);

    await tester.ensureVisible(find.text('Colosseum'));
    await tester.tap(find.text('Colosseum'));
    await tester.pump();

    expect(find.text('Done (1)'), findsOneWidget);
  });
}
