import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/core/juice/juice_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults to unmuted and persists mute across restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = JuiceSettings(prefs: prefs);
    expect(settings.state.muted, isFalse);

    settings.setMuted(true);
    expect(settings.state.muted, isTrue);

    final restored = JuiceSettings(prefs: prefs);
    expect(restored.state.muted, isTrue);
  });

  test('toggle flips the current state', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = JuiceSettings(prefs: await SharedPreferences.getInstance());
    settings.toggle();
    expect(settings.state.muted, isTrue);
    settings.toggle();
    expect(settings.state.muted, isFalse);
  });
}
