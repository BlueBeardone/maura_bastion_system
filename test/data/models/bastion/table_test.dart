import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';

void main() {
  group('rollTableResult', () {
    test('rolls single-number column (d4 style)', () {
      final table = FacilityTable(table: [
        ['d4', 'Guest', 'Description'],
        ['1', 'Renowned Builder', 'Helps construction'],
        ['2', 'Seeking Sanctuary', 'Stays a turn'],
        ['3', 'Mercenary Guest', 'Extra defender'],
        ['4', 'Friendly Monster', 'Repels attack'],
      ]);
      // _FixedRandom(1).nextInt(4) == 1 -> roll 2 -> row '2'
      expect(
        rollTableResult(table, rng: _FixedRandom(1)),
        '2 | Seeking Sanctuary | Stays a turn',
      );
    });

    test('rolls range column (1d100 style) including leading zeros', () {
      final table = FacilityTable(table: [
        ['1d100', 'Treasure'],
        ['01 - 40', '25 GP'],
        ['41 - 63', '125 GP'],
        ['99 - 00', '250 GP per rank'],
      ]);
      // die size = highest upper bound = 100; _FixedRandom(62).nextInt(100) == 62 -> roll 63 -> range 41-63
      expect(rollTableResult(table, rng: _FixedRandom(62)), '41 - 63 | 125 GP');
    });

    test('roll above last covered value clamps to last row (gap handling)', () {
      final table = FacilityTable(table: [
        ['1d100', 'Treasure'],
        ['01 - 40', '25 GP'],
        ['41 - 63', '125 GP'],
        ['64 - 73', '150 GP'],
        ['76 - 90', '150 GP per rank'], // 74-75 gap
        ['99 - 00', '250 GP per rank'],
      ]);
      // die size = 100; _FixedRandom(73).nextInt(100) == 73 -> roll 74 -> gap -> clamp to first max >= 74 (76-90)
      expect(
        rollTableResult(table, rng: _FixedRandom(73)),
        '76 - 90 | 150 GP per rank',
      );
    });

    test('skips rows with unparseable first cells', () {
      final table = FacilityTable(table: [
        ['d6', 'Event'],
        ['banana', 'should be skipped'],
        ['3', 'valid row'],
      ]);
      // _FixedRandom(2).nextInt(3) == 2 -> roll 3 -> matches row '3'
      expect(rollTableResult(table, rng: _FixedRandom(2)), '3 | valid row');
    });

    test('returns null for empty or header-only table', () {
      expect(rollTableResult(FacilityTable(table: [])), isNull);
      expect(
        rollTableResult(FacilityTable(table: [['d6', 'Event']])),
        isNull,
      );
    });

    test('roll 100 matches the 99 - 00 row (0 upper bound maps to 100)', () {
      final table = FacilityTable(table: [
        ['1d100', 'Treasure'],
        ['01 - 40', '25 GP'],
        ['41 - 63', '125 GP'],
        ['99 - 00', '250 GP per rank'],
      ]);
      // _FixedRandom(99).nextInt(100) == 99 -> roll 100 -> '99 - 00' row
      expect(rollTableResult(table, rng: _FixedRandom(99)), '99 - 00 | 250 GP per rank');
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
