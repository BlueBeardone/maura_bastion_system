import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/bastion/individual_bastion_events_catalog.dart';

void main() {
  group('rollIndividualBastionEvent', () {
    test('roll 1 returns Quiet Week', () {
      final event = rollIndividualBastionEvent(rng: _FixedRandom(0));
      expect(event.id, 'ibe_quiet_week');
    });

    test('roll 100 returns Treasure', () {
      final event = rollIndividualBastionEvent(rng: _FixedRandom(99));
      expect(event.id, 'ibe_treasure');
    });

    test('every possible roll maps to an event covering it', () {
      for (var roll = 1; roll <= 100; roll++) {
        final event = rollIndividualBastionEvent(rng: _FixedRandom(roll - 1));
        expect(event.matchesRoll(roll), isTrue,
            reason: 'roll $roll should match ${event.id}');
      }
    });
  });
}

/// Random stub whose nextInt always returns the fixed value.
class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final int value;

  @override
  int nextInt(int max) => value % max;

  @override
  bool nextBool() => value.isEven;

  @override
  double nextDouble() => value / 100;
}