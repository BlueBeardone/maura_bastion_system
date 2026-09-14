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
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_page.dart';
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

Map<String, dynamic> _facilityJson(String id, String name) => {
      'id': id,
      'name': name,
      'rank': 'd',
      'description': 'desc',
      'constructionTurns': 0,
      'constructedTurns': 0,
      'minimumRequiredHirelings': 0,
      'cost': 0,
    };

MockClient _mockClient() => MockClient((request) async {
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
                'facilities': [
                  _facilityJson('f0', 'Keep'),
                  _facilityJson('f1', 'Barracks'),
                ],
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

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GetIt.I.reset();
  });

  Future<void> pump(WidgetTester tester) async {
    final apiClient = ApiClient(baseUrl: 'http://example.test', client: _mockClient());
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
        child: const MaterialApp(
          home: BastionPage(bastionId: 'bastion_1', isUserBastion: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('FAB clears bottom view padding on a narrow viewport',
      (tester) async {
    const double dpr = 1.0;
    const double bottomInset = 34.0;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = dpr;
    tester.view.viewPadding = const FakeViewPadding(
      bottom: bottomInset * dpr,
      top: 0,
      left: 0,
      right: 0,
    );
    tester.view.padding = const FakeViewPadding(
      bottom: bottomInset * dpr,
      top: 0,
      left: 0,
      right: 0,
    );
    addTearDown(tester.view.reset);

    await pump(tester);

    final fabRect = tester.getRect(find.byType(FloatingActionButton));
    // The FAB must sit above the bottom safe area, not at the raw canvas
    // bottom where mobile browser chrome overlaps it.
    expect(fabRect.bottom,
        lessThanOrEqualTo(800 - bottomInset + kFloatingActionButtonMargin));
  });
}
