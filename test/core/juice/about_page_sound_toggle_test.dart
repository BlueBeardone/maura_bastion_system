import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/core/juice/juice_settings.dart';
import 'package:maura_bastion_system/features/about_page/about_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('About page shows and toggles the sound switch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = JuiceSettings(prefs: await SharedPreferences.getInstance());
    GetIt.I.registerSingleton<JuiceSettings>(settings);
    addTearDown(GetIt.I.reset);

    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    await tester.pumpAndSettle();

    expect(find.text('Sound effects'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(settings.state.muted, isTrue);
  });
}
