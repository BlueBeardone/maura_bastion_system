import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/core/juice/juice.dart';
import 'package:maura_bastion_system/core/juice/juice_settings.dart';
import 'package:maura_bastion_system/core/juice/juice_sfx.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Juice facade is a silent no-op with nothing registered',
      (tester) async {
    GetIt.I.reset();
    await tester.pumpWidget(const SizedBox.shrink());
    Juice.sfx(SfxClip.dice);
    Juice.tap();
    Juice.heavy();
  });

  test('Sfx.play swallows missing-asset errors and respects mute', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = JuiceSettings(prefs: prefs);
    final sfx = Sfx(settings: settings);

    await sfx.play(SfxClip.dice); // no assets bundled in test env — swallowed
    settings.setMuted(true);
    await sfx.play(SfxClip.coin); // muted — no crash
  });
}