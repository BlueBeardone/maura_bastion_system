import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/hireling_api.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/facility_page.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GetIt.I.reset();
  });

  Facility barracks({int constructed = 2, int total = 2, Rank rank = Rank.D}) =>
      Facility(
        id: 'cat_barracks',
        name: 'Barracks',
        rank: rank,
        description: 'Houses the guard.',
        constructionTurns: total,
        constructedTurns: constructed,
        cost: 600,
      );

  MockClient hirelingMock() {
    return MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path == '/maura/v1/hirelings') {
        return http.Response(
          jsonEncode({'success': true, 'message': 'ok', 'data': <Object>[]}),
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

  Future<void> pumpFacilityPage(
    WidgetTester tester, {
    required Facility facility,
    required List<Facility> bastionFacilities,
    required bool isUserBastion,
    VoidCallback? onUpgrade,
  }) async {
    final apiClient =
        ApiClient(baseUrl: 'http://example.test', client: hirelingMock());
    GetIt.I.registerSingleton<HirelingApi>(HirelingApi(client: apiClient));
    final authCubit = AuthCubit(identityApi: IdentityApi(client: apiClient));
    GetIt.I.registerSingleton<AuthCubit>(authCubit);

    final bastion = Bastion(
      id: 'bastion_1',
      name: 'Test Bastion',
      description: 'desc',
      facilities: bastionFacilities,
    );

    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => authCubit,
        child: MaterialApp(
          home: FacilityPage(
            facility: facility,
            bastion: bastion,
            isUserBastion: isUserBastion,
            onUpgrade: onUpgrade,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'shows Upgrade button for an owned, built, upgradeable facility with no busy facilities',
      (tester) async {
    await pumpFacilityPage(
      tester,
      facility: barracks(),
      bastionFacilities: [barracks()],
      isUserBastion: true,
      onUpgrade: () {},
    );

    expect(find.text('Upgrade to Rank C — 900 GP'), findsOneWidget);
  });

  testWidgets('hides Upgrade button while another facility is under construction',
      (tester) async {
    final kitchen = Facility(
      id: 'cat_kitchen',
      name: 'Kitchen',
      rank: Rank.D,
      description: 'Flavor.',
      constructionTurns: 2,
      constructedTurns: 0,
    );

    await pumpFacilityPage(
      tester,
      facility: barracks(),
      bastionFacilities: [barracks(), kitchen],
      isUserBastion: true,
      onUpgrade: () {},
    );

    expect(find.text('Upgrade to Rank C — 900 GP'), findsNothing);
  });

  testWidgets('hides Upgrade button while the facility itself is under construction',
      (tester) async {
    await pumpFacilityPage(
      tester,
      facility: barracks(constructed: 0, total: 2),
      bastionFacilities: [barracks(constructed: 0, total: 2)],
      isUserBastion: true,
      onUpgrade: () {},
    );

    expect(find.text('Upgrade to Rank C — 900 GP'), findsNothing);
  });

  testWidgets('hides Upgrade button for a non-user bastion', (tester) async {
    await pumpFacilityPage(
      tester,
      facility: barracks(),
      bastionFacilities: [barracks()],
      isUserBastion: false,
    );

    expect(find.text('Upgrade to Rank C — 900 GP'), findsNothing);
  });

  testWidgets('hides Upgrade button for a non-upgradeable facility id',
      (tester) async {
    final armory = Facility(
      id: 'cat_armory',
      name: 'Armory',
      rank: Rank.C,
      description: 'An armory.',
      constructionTurns: 4,
      constructedTurns: 4,
    );

    await pumpFacilityPage(
      tester,
      facility: armory,
      bastionFacilities: [armory],
      isUserBastion: true,
      onUpgrade: () {},
    );

    expect(find.text('Upgrade to Rank C — 900 GP'), findsNothing);
  });

  testWidgets('hides Upgrade button for an S-rank facility', (tester) async {
    await pumpFacilityPage(
      tester,
      facility: barracks(rank: Rank.S),
      bastionFacilities: [barracks(rank: Rank.S)],
      isUserBastion: true,
      onUpgrade: () {},
    );

    expect(find.textContaining('Upgrade to Rank'), findsNothing);
  });

  testWidgets('tapping Upgrade invokes the onUpgrade callback', (tester) async {
    var called = false;
    await pumpFacilityPage(
      tester,
      facility: barracks(),
      bastionFacilities: [barracks()],
      isUserBastion: true,
      onUpgrade: () {
        called = true;
      },
    );

    await tester.ensureVisible(find.text('Upgrade to Rank C — 900 GP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upgrade to Rank C — 900 GP'));
    expect(called, isTrue);
  });
}