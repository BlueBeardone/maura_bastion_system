import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/chart_events_catalog.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';

void main() {
  final events = getChartEvents();

  test('has 80 unique events', () {
    expect(events.length, 80);
    expect(events.map((e) => e.id).toSet().length, 80);
  });

  test('every non-archetype chart has 12 events', () {
    for (final chart in EventChart.values) {
      final count =
          events.where((e) => !e.isArchetype && e.chart == chart).length;
      expect(count, 12, reason: chart.name);
    }
  });

  test('every chart has exactly one legend event', () {
    for (final chart in EventChart.values) {
      final legends = events
          .where((e) => e.chart == chart && e.tier == ChartTier.legend)
          .toList();
      expect(legends.length, 1, reason: chart.name);
    }
  });

  test('no event has an empty description or blank name', () {
    for (final e in events) {
      expect(e.name.trim(), isNotEmpty, reason: e.id);
      expect(e.description.trim(), isNotEmpty, reason: e.id);
    }
  });
}
