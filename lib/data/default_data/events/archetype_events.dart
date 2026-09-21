// lib/data/default_data/events/archetype_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

List<ChartEvent> archetypeEvents() {
  return const [
    ChartEvent(
      id: 'cvr_alchemists_commission',
      name: "The Alchemist's Commission",
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'An alchemist of the Arcane court posts a commission: planar-touched game, taken alive or fresh. The hunters who can read the marks will eat well this winter.',
      dispatch: DispatchSpec(prompt: 'Hunt planar-touched game', maxUnits: 3, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb],
        unitDice: UnitDice(1, 2),
      ),
      relatedCharts: {EventChart.wilds, EventChart.arcane},
      minPointsPerChart: 4,
    ),
    ChartEvent(
      id: 'cvr_caravan_ore',
      name: 'Caravan of Ore',
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          'A Trade Road caravan arrived heavier than it left — and its manifest has learned some interesting new words. The ore is good; the price is quiet.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.metal],
        unitDice: UnitDice(1, 1),
        goldDice: UnitDice(2, 100),
      ),
      relatedCharts: {EventChart.deeps, EventChart.tradeRoad},
      minPointsPerChart: 4,
    ),
    ChartEvent(
      id: 'cvr_hunters_feast',
      name: "The Hunters' Feast",
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description:
          'The bastion holds its feast day and the hunting has been generous. A wandering hand asks to stay and help with the smoking racks.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.meat],
        unitDice: UnitDice(1, 2),
        note: 'A feast-hand asks to stay',
      ),
      relatedCharts: {EventChart.wilds, EventChart.hearth},
      minPointsPerChart: 4,
    ),
    ChartEvent(
      id: 'cvr_miners_fair',
      name: "The Miners' Fair",
      chart: EventChart.deeps,
      tier: ChartTier.basic,
      description:
          'The deeps send up a wagon of show-stone for the fair, and the fair sends down coin and cheer. Everyone profits; a few even profit honestly.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.stone],
        unitDice: UnitDice(1, 2),
        goldDice: UnitDice(2, 100),
      ),
      relatedCharts: {EventChart.deeps, EventChart.tradeRoad, EventChart.hearth},
      minPointsPerChart: 4,
    ),
    ChartEvent(
      id: 'cvr_beast_broker',
      name: 'The Beast Broker',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'A broker arrives with papers, cages, and an eye for your banners: he trades in war-beasts, and today he is selling.',
      reward: RewardSpec(
        kind: RewardKind.recruitDefender,
        note: 'A tamed war-beast arrives with papers',
      ),
      relatedCharts: {EventChart.wilds, EventChart.tradeRoad, EventChart.warMarch},
      minPointsPerChart: 4,
    ),
    ChartEvent(
      id: 'cvr_guild_charter',
      name: 'The Guild Charter',
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'A guild scribe arrives with a charter, a wax seal, and a proposal: your bastion as the charter-house for three trades at once.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(3, 100),
        note: 'Charter-sealing fees and goodwill',
      ),
      relatedCharts: {EventChart.tradeRoad, EventChart.hearth, EventChart.arcane},
      minPointsPerChart: 4,
    ),
    ChartEvent(
      id: 'rvl_green_vs_deep',
      name: 'Green Against Deep',
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description:
          'The same ridge promised to the foresters is wanted by the mine. Both crews are yours, and only one survey can be filed this turn.',
      dispatch: DispatchSpec(prompt: 'File the survey — forest or mine?', maxUnits: 3, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.herb, RewardCategory.stone],
        unitDice: UnitDice(1, 2),
        note: "Charter favor: the forest's find or the mine's",
      ),
      relatedCharts: {EventChart.wilds, EventChart.deeps},
      minPointsPerChart: 8,
    ),
    ChartEvent(
      id: 'rvl_coin_vs_steel',
      name: 'Coin Against Steel',
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'The roads are dangerous and the pay for guards is high — but your own walls are hungry for hands. Escort the shipment, or garrison the bastion?',
      dispatch: DispatchSpec(prompt: 'Escort fee or the wall?', maxUnits: 3, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(4, 100),
        note: 'Escort pay — hard coin for a hard road',
      ),
      relatedCharts: {EventChart.tradeRoad, EventChart.warMarch},
      minPointsPerChart: 8,
    ),
  ];
}
