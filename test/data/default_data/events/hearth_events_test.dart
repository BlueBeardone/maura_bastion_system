// test/data/default_data/events/hearth_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/hearth_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

void main() {
  final events = hearthEvents();

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

  test('no material categories — hearth rewards are recruits or notes', () {
    for (final e in events) {
      expect(e.chart, EventChart.hearth);
      expect(e.isArchetype, isFalse);
      expect(e.reward.categories, isEmpty, reason: e.id);
      expect(
        e.reward.kind,
        isNot(RewardKind.material),
        reason: e.id,
      );
    }
  });

  test('at least two recruit events and every event carries a flavor note', () {
    expect(
      events.where((e) => e.reward.kind == RewardKind.recruitHireling).length,
      greaterThanOrEqualTo(2),
    );
    for (final e in events) {
      expect(e.reward.note, isNotNull, reason: e.id);
    }
  });

  test('legend event is Heart of the Bastion', () {
    final legend = events.singleWhere((e) => e.tier == ChartTier.legend);
    expect(legend.id, 'hrt_heart_of_the_bastion');
    expect(legend.name, 'Heart of the Bastion');
  });
}
