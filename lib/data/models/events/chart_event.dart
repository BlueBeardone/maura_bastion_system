// lib/data/models/events/chart_event.dart
import 'dart:math';

import 'package:maura_bastion_system/data/models/bastion/table.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

class ChartEvent {
  final String id;
  final String name;

  /// Null only for the uneventful pseudo-events (no points allocated).
  final EventChart? chart;
  final ChartTier tier;
  final String description;
  final DispatchSpec? dispatch;
  final RewardSpec reward;

  /// The catalog facility this event knocks offline when its dispatch fails.
  /// Null for events that do not affect a facility.
  final String? facilityId;

  /// Archetype gating: the charts this convergence/rivalry event involves.
  final Set<EventChart> relatedCharts;
  final int minPointsPerChart;
  final FacilityTable? table;

  const ChartEvent({
    required this.id,
    required this.name,
    required this.chart,
    required this.tier,
    required this.description,
    this.dispatch,
    this.reward = const RewardSpec(),
    this.facilityId,
    this.relatedCharts = const {},
    this.minPointsPerChart = 0,
    this.table,
  });

  bool get isArchetype => relatedCharts.isNotEmpty;
}

TurnReward rollTurnReward({
  required ChartEvent event,
  required bool success,
  Random? rng,
}) {
  final spec = event.reward;
  final tier = event.tier;
  if (!success) {
    return TurnReward(
      materials: const [],
      recruit: RewardKind.none,
      note: spec.failureNote ?? spec.note,
    );
  }
  if (spec.kind == RewardKind.none) {
    return TurnReward(
      materials: const [],
      recruit: RewardKind.none,
      note: spec.note,
    );
  }
  final materials = spec.categories.isEmpty
      ? const <RewardGrant>[]
      : rollMaterialRewards(
          categories: spec.categories,
          picks: spec.picks,
          cap: tier.rewardRankCap,
          unitDice: spec.unitDice,
          rng: rng,
        );
  final recruit = spec.kind == RewardKind.recruitDefender ||
          spec.kind == RewardKind.recruitHireling
      ? spec.kind
      : RewardKind.none;
  return TurnReward(
    materials: materials,
    recruit: recruit,
    note: spec.note,
  );
}
