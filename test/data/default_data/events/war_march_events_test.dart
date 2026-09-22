// test/data/default_data/events/war_march_events_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/events/war_march_events.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';

import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

void main() {
  final events = warMarchEvents();

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

  test('material categories are creaturePart-only', () {
    for (final e in events) {
      expect(e.chart, EventChart.warMarch);
      expect(e.isArchetype, isFalse);
      for (final category in e.reward.categories) {
        expect(category, RewardCategory.creaturePart, reason: e.id);
      }
    }
  });

  test('dispatch events are well-formed and never exceed 4 units', () {
    for (final e in events) {
      if (e.dispatch == null) continue;
      expect(e.dispatch!.maxUnits, inInclusiveRange(1, 4), reason: e.id);
      expect(e.dispatch!.dc, greaterThanOrEqualTo(1), reason: e.id);
      expect(e.dispatch!.prompt, isNotEmpty, reason: e.id);
    }
    expect(events.where((e) => e.dispatch != null).length, greaterThanOrEqualTo(7));
  });

  test('the duel is a single-knight affair on the knight\'s default dice', () {
    final duel = events.singleWhere((e) => e.id == 'wrm_duel');
    expect(duel.dispatch!.maxUnits, 1);
    expect(duel.dispatch!.diceOverride, isNull);
    expect(duel.dispatch!.dc, 4);
  });

  test('legend event is The Black Banner', () {
    final legend = events.singleWhere((e) => e.tier == ChartTier.legend);
    expect(legend.id, 'wrm_the_black_banner');
    expect(legend.name, 'The Black Banner');
  });
}
