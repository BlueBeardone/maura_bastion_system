import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';

void main() {
  group('DefenderType', () {
    group('fromString', () {
      test('returns knight for "knight"', () {
        expect(DefenderType.fromString('knight'), DefenderType.knight);
      });

      test('returns bastionDefender for "bastion_defender"', () {
        expect(DefenderType.fromString('bastion_defender'), DefenderType.bastionDefender);
      });

      test('returns beast for "beast"', () {
        expect(DefenderType.fromString('beast'), DefenderType.beast);
      });

      test('returns bastionDefender for "bastion defender" (with space)', () {
        expect(DefenderType.fromString('bastion defender'), DefenderType.bastionDefender);
      });

      test('is case-insensitive', () {
        expect(DefenderType.fromString('KNIGHT'), DefenderType.knight);
        expect(DefenderType.fromString('Knight'), DefenderType.knight);
        expect(DefenderType.fromString('BEAST'), DefenderType.beast);
      });

      test('throws ArgumentError for unknown value', () {
        expect(
          () => DefenderType.fromString('dragon'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('title extension', () {
      test('returns display string for each type', () {
        expect(DefenderType.knight.title, 'Knight');
        expect(DefenderType.bastionDefender.title, 'Bastion Defender');
        expect(DefenderType.beast.title, 'Beast');
      });
    });
  });
}
