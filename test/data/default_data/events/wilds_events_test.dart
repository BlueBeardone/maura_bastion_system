// test/data/default_data/events/wilds_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/wilds_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

void main() {
  final events = wildsEvents();

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

  test('every event belongs to the wilds chart and uses only wilds categories', () {
    final allowed = EventChart.wilds.rewardCategories.toSet();
    for (final e in events) {
      expect(e.chart, EventChart.wilds);
      expect(e.isArchetype, isFalse);
      for (final category in e.reward.categories) {
        expect(allowed.contains(category), isTrue, reason: e.id);
      }
    }
  });

  test('dispatch events are well-formed', () {
    for (final e in events) {
      if (e.dispatch == null) continue;
      expect(e.dispatch!.maxUnits, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.dc, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.prompt, isNotEmpty, reason: e.id);
    }
    expect(events.where((e) => e.dispatch != null).length, greaterThanOrEqualTo(8));
  });

  test('material rewards all have kind material', () {
    for (final e in events) {
      expect(e.reward.kind, RewardKind.material, reason: e.id);
      expect(e.reward.categories, isNotEmpty, reason: e.id);
    }
  });

  test('legend event is the Beast of Maura', () {
    final legend = events.singleWhere((e) => e.tier == ChartTier.legend);
    expect(legend.id, 'wld_beast_of_maura');
    expect(legend.name, 'The Beast of Maura');
  });
}
