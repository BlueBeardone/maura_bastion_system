// test/data/default_data/events/archetype_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/archetype_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';

void main() {
  final events = archetypeEvents();

  test('has 8 unique archetype events: 6 convergence + 2 rivalry', () {
    expect(events.length, 8);
    expect(events.map((e) => e.id).toSet().length, 8);
    expect(events.where((e) => e.minPointsPerChart == 4).length, 6);
    expect(events.where((e) => e.minPointsPerChart == 8).length, 2);
  });

  test('all are archetypes with tiered charts and related charts', () {
    for (final e in events) {
      expect(e.isArchetype, isTrue, reason: e.id);
      expect(e.relatedCharts.length, inInclusiveRange(2, 3), reason: e.id);
      expect(e.chart, isIn(e.relatedCharts), reason: e.id);
      expect(e.tier, isNot(ChartTier.legend), reason: e.id);
    }
  });

  test('rivalry events involve exactly two related charts', () {
    final rivalries = events.where((e) => e.minPointsPerChart == 8).toList();
    expect(rivalries.map((e) => e.id).toSet(),
        {'rvl_green_vs_deep', 'rvl_coin_vs_steel'});
    for (final e in rivalries) {
      expect(e.relatedCharts.length, 2);
    }
  });
}
