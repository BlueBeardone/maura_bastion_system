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

  group('DispatchSpec', () {
    test('diceFor prefers the override', () {
      const spec = DispatchSpec(
        prompt: 'Send hunters',
        maxUnits: 3,
        dc: 12,
        diceOverride: {DispatchUnitType.knight: UnitDice(2, 6)},
      );
      expect(spec.diceFor(DispatchUnitType.knight), const UnitDice(2, 6));
      expect(spec.diceFor(DispatchUnitType.beast), const UnitDice(2, 6));
      expect(spec.diceFor(DispatchUnitType.hireling), const UnitDice(1, 6));
    });

    test('diceFor falls back to defaults without override', () {
      const spec = DispatchSpec(prompt: 'Send anyone', maxUnits: 4, dc: 10);
      expect(spec.diceFor(DispatchUnitType.bastionDefender), const UnitDice(1, 6));
    });
  });

  group('resolveDispatch', () {
    const spec = DispatchSpec(prompt: 'Send a party', maxUnits: 2, dc: 10);

    test('throws when more units than maxUnits', () {
      const units = [
        DispatchUnit(id: 'a', name: 'A', type: DispatchUnitType.bastionDefender),
        DispatchUnit(id: 'b', name: 'B', type: DispatchUnitType.bastionDefender),
        DispatchUnit(id: 'c', name: 'C', type: DispatchUnitType.bastionDefender),
      ];
      expect(
        () => resolveDispatch(spec: spec, units: units, rng: Random(1)),
        throwsArgumentError,
      );
    });

    test('rolls per-unit dice and tallies with bonus', () {
      final result = resolveDispatch(
        spec: spec,
        units: const [
          DispatchUnit(id: 'a', name: 'Aldric', type: DispatchUnitType.knight),
          DispatchUnit(id: 'b', name: 'Rex', type: DispatchUnitType.beast),
        ],
        rng: Random(7),
        bonus: 2,
      );
      expect(result.unitRolls.length, 2);
      expect(result.unitRolls[0].rolls.length, 1); // knight 1d8
      expect(result.unitRolls[0].unit.name, 'Aldric');
      expect(result.unitRolls[1].rolls.length, 2); // beast 2d6
      final expectedTotal = result.unitRolls.fold<int>(0, (s, r) => s + r.subtotal) + 2;
      expect(result.total, expectedTotal);
      expect(result.success, expectedTotal >= 10);
    });

    test('deterministic rng gives deterministic rolls', () {
      final a = resolveDispatch(
        spec: spec,
        units: const [DispatchUnit(id: 'a', name: 'A', type: DispatchUnitType.bastionDefender)],
        rng: Random(99),
      );
      final b = resolveDispatch(
        spec: spec,
        units: const [DispatchUnit(id: 'a', name: 'A', type: DispatchUnitType.bastionDefender)],
        rng: Random(99),
      );
      expect(a.unitRolls.single.subtotal, b.unitRolls.single.subtotal);
    });

    test('success boundary is meets-it-beats-it', () {
      final result = DispatchResult(
        unitRolls: const [],
        bonus: 10,
        dc: 10,
      );
      expect(result.total, 10);
      expect(result.success, isTrue);
    });
  });
}
