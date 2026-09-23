// test/data/default_data/events/enemy_catalog_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/enemy_catalog.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';

void main() {
  test('every tier has at least one enemy', () {
    final catalog = getEnemyCatalog();
    for (final tier in ChartTier.values) {
      expect(
        catalog.where((e) => e.tier == tier),
        isNotEmpty,
        reason: '$tier',
      );
    }
  });

  test('randomEnemyForTier returns an enemy of the requested tier', () {
    for (final tier in ChartTier.values) {
      for (var i = 0; i < 20; i++) {
        expect(randomEnemyForTier(tier, rng: Random(i)).tier, tier);
      }
    }
  });

  test('enemy ids are unique', () {
    final ids = getEnemyCatalog().map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
