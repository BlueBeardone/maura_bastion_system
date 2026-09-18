import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';

void main() {
  group('UnitDice', () {
    test('roll stays within count*faces bounds', () {
      final dice = const UnitDice(2, 6);
      for (var i = 0; i < 500; i++) {
        final value = dice.roll(Random(42 + i));
        expect(value, inInclusiveRange(2, 12));
      }
    });

    test('single die covers every face', () {
      final seen = <int>{};
      for (var i = 0; i < 200; i++) {
        seen.add(const UnitDice(1, 6).roll(Random(1000 + i)));
      }
      expect(seen, containsAll([1, 2, 3, 4, 5, 6]));
    });
  });

  test('default dice per unit type', () {
    expect(defaultDiceFor(DispatchUnitType.beast), const UnitDice(2, 6));
    expect(defaultDiceFor(DispatchUnitType.knight), const UnitDice(1, 8));
    expect(defaultDiceFor(DispatchUnitType.bastionDefender), const UnitDice(1, 6));
    expect(defaultDiceFor(DispatchUnitType.hireling), const UnitDice(1, 6));
  });
}
