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

  ChartTurnRoll rollTurn({required Map<EventChart, int> points, Random? rng}) {
    final random = rng ?? Random();
    final events = catalog();
    if (points.values.every((p) => p <= 0)) {
      return ChartTurnRoll(
        slice: null,
        event: _uneventfulEvents[random.nextInt(_uneventfulEvents.length)],
        tier: ChartTier.basic,
      );
    }
    final slices = computeChartSlices(points);
    final roll = random.nextInt(100) + 1;
    final slice = slices.firstWhere((s) => s.contains(roll));
    final tier = ChartTier.forPoints(slice.points)!;
    final pool = events
        .where((e) =>
            !e.isArchetype && e.chart == slice.chart && e.tier == tier)
        .toList();
    return ChartTurnRoll(
      slice: slice,
      event: pool[random.nextInt(pool.length)],
      tier: tier,
    );
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
