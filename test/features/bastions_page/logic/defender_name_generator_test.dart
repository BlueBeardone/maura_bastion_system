import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/defender_name_generator.dart';

void main() {
  group('DefenderNameGenerator.generate', () {
    test('returns the requested number of names', () {
      final names = DefenderNameGenerator().generate(20);
      expect(names, hasLength(20));
    });

    test('names are unique within a batch', () {
      final names = DefenderNameGenerator().generate(50);
      expect(names.toSet(), hasLength(50));
    });

    test('names are two words (first + surname)', () {
      final names = DefenderNameGenerator().generate(20);
      for (final name in names) {
        expect(name.split(' '), hasLength(2));
        expect(name.trim(), isNotEmpty);
      }
    });

    test('is deterministic with a seeded Random', () {
      final a = DefenderNameGenerator(random: Random(42)).generate(5);
      final b = DefenderNameGenerator(random: Random(42)).generate(5);
      expect(a, b);
    });
  });
}