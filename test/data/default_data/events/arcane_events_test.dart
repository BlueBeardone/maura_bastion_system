// test/data/default_data/events/arcane_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/arcane_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

void main() {
  final events = arcaneEvents();

  test('has 12 unique events', () {
    expect(events.length, 12);
    expect(events.map((e) => e.id).toSet().length, 12);
  });

  test('tier distribution is 4 basic / 4 skilled / 3 master / 1 legend', () {
    final counts = <ChartTier, int>{};
    for (final e in events) {
      counts[e.tier] = (counts[e.tier] ?? 0) + 1;
    }
    expect(counts[ChartTier.basic], 4);
    expect(counts[ChartTier.skilled], 4);
    expect(counts[ChartTier.master], 3);
    expect(counts[ChartTier.legend], 1);
  });

  test('material categories are herb and weave only', () {
    final allowed = EventChart.arcane.rewardCategories.toSet();
    for (final e in events) {
      expect(e.chart, EventChart.arcane);
      expect(e.isArchetype, isFalse);
      for (final category in e.reward.categories) {
        expect(allowed.contains(category), isTrue, reason: e.id);
      }
    }
  });

  test('legend event is The Door in the Hill', () {
    final legend = events.singleWhere((e) => e.tier == ChartTier.legend);
    expect(legend.id, 'arc_door_in_hill');
    expect(legend.name, 'The Door in the Hill');
  });
}
