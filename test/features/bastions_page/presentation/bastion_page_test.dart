import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/bastion_api.dart';
import 'package:maura_bastion_system/api/identity_api.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/bastion_cubit.dart';
import 'package:maura_bastion_system/features/bastions_page/presentation/bastion_page.dart';
import 'package:maura_bastion_system/features/login/logic/auth_cubit.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    GetIt.I.reset();
  });

  testWidgets(
    'empty bastion still shows Construct Facility, Hirelings and Defenders containers',
    (tester) async {
      final bastion = Bastion(
        id: 'bastion_empty',
        name: 'Empty Bastion',
        description: 'An empty stronghold awaiting its lord.',
        facilities: const [],
      );

      final apiClient = ApiClient(baseUrl: 'http://localhost:1');
      final bastionCubit = BastionCubit(
        bastionApi: BastionApi(client: apiClient),
      );
      bastionCubit.emit(BastionLoadedState(bastions: [bastion]));
      GetIt.I.registerSingleton<BastionCubit>(bastionCubit);

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
}
