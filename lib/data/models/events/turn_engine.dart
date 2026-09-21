// lib/data/models/events/turn_engine.dart
import 'dart:math';

import 'package:maura_bastion_system/data/default_data/events/chart_events_catalog.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_slices.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

class ChartTurnRoll {
  final ChartSlice? slice;
  final ChartEvent event;
  final ChartTier tier;

  const ChartTurnRoll({required this.slice, required this.event, required this.tier});
}

class ChartTurnEngine {
  final List<ChartEvent> Function() catalog;

  const ChartTurnEngine({this.catalog = getChartEvents});

  ChartTurnRoll rollTurn({
    required Map<EventChart, int> points,
    int? earnedPoints,
    Random? rng,
  }) {
    final random = rng ?? Random();
    final events = catalog();
    final assigned =
        points.values.fold(0, (sum, p) => sum + (p > 0 ? p : 0));
    final budget = earnedPoints ?? assigned;
    if (budget <= 0) {
      return ChartTurnRoll(
        slice: null,
        event: _uneventfulEvents[random.nextInt(_uneventfulEvents.length)],
        tier: ChartTier.basic,
      );
    }
    final quiet = (budget - assigned).clamp(0, budget);
    final quietShare = quiet * 100 ~/ budget;
    final roll = random.nextInt(100) + 1;
    if (roll <= quietShare) {
      return ChartTurnRoll(
        slice: null,
        event: _uneventfulEvents[random.nextInt(_uneventfulEvents.length)],
        tier: ChartTier.basic,
      );
    }
    final scaledRoll =
        1 + ((roll - quietShare) * 100 - 1) ~/ (100 - quietShare);
    final slices = computeChartSlices(points);
    final slice = slices.firstWhere((s) => s.contains(scaledRoll));
    final tier = ChartTier.forPoints(slice.points)!;
    final pool = events
        .where((e) => !e.isArchetype && e.chart == slice.chart && e.tier == tier)
        .toList();
    if (pool.isEmpty) {
      throw ArgumentError('No events for chart ${slice.chart} at tier $tier');
    }
    return ChartTurnRoll(
      slice: slice,
      event: pool[random.nextInt(pool.length)],
      tier: tier,
    );
  }

  ChartEvent? maybeRollArchetype({
    required Map<EventChart, int> points,
    Random? rng,
    double chance = 0.25,
  }) {
    final random = rng ?? Random();
    if (random.nextDouble() >= chance) return null;
    final eligible = catalog()
        .where((e) =>
            e.isArchetype &&
            e.relatedCharts
                .every((c) => (points[c] ?? 0) >= e.minPointsPerChart))
        .toList();
    if (eligible.isEmpty) return null;
    return eligible[random.nextInt(eligible.length)];
  }
}

const List<ChartEvent> _uneventfulEvents = [
  ChartEvent(
    id: 'unt_quiet_week',
    name: 'Quiet Week',
    chart: null,
    tier: ChartTier.basic,
    description: 'Nothing happens this turn. The walls stand; the stores hold.',
    reward: RewardSpec(note: 'Allocate points to your charts to shape your turns'),
  ),
  ChartEvent(
    id: 'unt_rain',
    name: 'A Week of Rain',
    chart: null,
    tier: ChartTier.basic,
    description: 'The ditches run full and the walls drip. Nothing happens.',
    reward: RewardSpec(note: 'Allocate points to your charts to shape your turns'),
  ),
  ChartEvent(
    id: 'unt_drills',
    name: 'Drill and Repair',
    chart: null,
    tier: ChartTier.basic,
    description:
        'The defenders drill in the yard and the carpenter patches the battlements. Nothing happens.',
    reward: RewardSpec(note: 'Allocate points to your charts to shape your turns'),
  ),
  ChartEvent(
    id: 'unt_market_chatter',
    name: 'Market Chatter',
    chart: null,
    tier: ChartTier.basic,
    description: 'Gossip, prices, and small news drift up from the town. Nothing happens.',
    reward: RewardSpec(note: 'Allocate points to your charts to shape your turns'),
  ),
];
