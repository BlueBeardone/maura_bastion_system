// test/data/default_data/events/trade_road_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/trade_road_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

void main() {
  final events = tradeRoadEvents();

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

  test('material categories are weave-only', () {
    for (final e in events) {
      expect(e.chart, EventChart.tradeRoad);
      expect(e.isArchetype, isFalse);
      for (final category in e.reward.categories) {
        expect(category, RewardCategory.weave, reason: e.id);
      }
    }
  });

  test('gold-heavy events roll gold dice', () {
    final goldEvents =
        events.where((e) => e.reward.kind == RewardKind.gold).toList();
    expect(goldEvents.length, greaterThanOrEqualTo(5));
    for (final e in goldEvents) {
      expect(e.reward.goldDice, isNotNull, reason: e.id);
    }
  });

  test('dispatch events are well-formed', () {
    for (final e in events) {
      if (e.dispatch == null) continue;
      expect(e.dispatch!.maxUnits, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.dc, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.prompt, isNotEmpty, reason: e.id);
    }
    expect(events.where((e) => e.dispatch != null).length, greaterThanOrEqualTo(3));
  });

  test('legend event is The Merchant Prince', () {
    final legend = events.singleWhere((e) => e.tier == ChartTier.legend);
    expect(legend.id, 'trd_merchant_prince');
    expect(legend.name, 'The Merchant Prince');
  });
}
