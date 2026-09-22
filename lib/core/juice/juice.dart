import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:maura_bastion_system/core/juice/juice_haptics.dart';
import 'package:maura_bastion_system/core/juice/juice_settings.dart';
import 'package:maura_bastion_system/core/juice/juice_sfx.dart';
import 'package:maura_bastion_system/core/juice/reveal_widgets.dart';

/// Static facade the UI calls for juice. Safe everywhere: any missing DI
/// registration is swallowed, so widgets and tests need no setup.
class Juice {
  Juice._();

  static void sfx(SfxClip clip) {
    try {
      unawaited(GetIt.I<Sfx>().play(clip));
    } catch (_) {}
  }

  static void tap() => _haptic(Haptics.light);
  static void heavy() => _haptic(Haptics.heavy);

  static void _haptic(Future<void> Function() impact) {
    try {
      if (GetIt.I<JuiceSettings>().state.muted) return;
      unawaited(impact());
    } catch (_) {}
  }

  /// One-shot reward moment: gold burst at screen center + coin clink + pulse.
  static void reward(BuildContext context) {
    heavy();
    sfx(SfxClip.coin);
    SparkleBurst.show(context);
  }
}