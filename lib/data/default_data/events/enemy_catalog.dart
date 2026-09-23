// lib/data/default_data/events/enemy_catalog.dart
import 'dart:math';

import 'package:maura_bastion_system/data/models/events/bastion_attack.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';

List<BastionEnemy> getEnemyCatalog() {
  return const [
    BastionEnemy(
      id: 'enm_bandit_cutthroats',
      name: 'Bandit Cutthroats',
      tier: ChartTier.basic,
      description:
          'A ragged band of road bandits, more knife than soldier, testing the fences for a weakness.',
    ),
    BastionEnemy(
      id: 'enm_starving_wolf_pack',
      name: 'Starving Wolf Pack',
      tier: ChartTier.basic,
      description:
          'Lean wolves driven by a hard winter to press against the bastion walls.',
    ),
    BastionEnemy(
      id: 'enm_cult_of_the_ember',
      name: 'Cult of the Ember',
      tier: ChartTier.skilled,
      description:
          'Hooded zealots who chant as they burn their way toward the gate.',
    ),
    BastionEnemy(
      id: 'enm_marsh_reavers',
      name: 'Marsh Reavers',
      tier: ChartTier.skilled,
      description:
          'Mud-caked raiders out of the fens, patient and well armed.',
    ),
    BastionEnemy(
      id: 'enm_feral_manticore',
      name: 'Feral Manticore',
      tier: ChartTier.master,
      description:
          'A wounded manticore and its brood, hunting the smell of meat.',
    ),
    BastionEnemy(
      id: 'enm_ashbound_warpriests',
      name: 'Ashbound Warpriests',
      tier: ChartTier.master,
      description:
          'Armored priests of a burned god, marching behind a wall of shields.',
    ),
    BastionEnemy(
      id: 'enm_the_warlords_horde',
      name: "The Warlord's Horde",
      tier: ChartTier.legend,
      description:
          'A disciplined war-band with siege ladders and no intention of turning back.',
    ),
    BastionEnemy(
      id: 'enm_the_tyrant_beast',
      name: 'The Tyrant Beast',
      tier: ChartTier.legend,
      description:
          'A titanic monster that has broken stronger walls than these.',
    ),
    BastionEnemy(
      id: 'enm_skeletors_crew',
      name: "Skeletor's Crew",
      tier: ChartTier.basic,
      description:
          "Skeletor's skeletons arrive to sack the bastion and are immediately persuaded to negotiate a fair wage first. They are, by every measure, excellent employers.",
    ),
    BastionEnemy(
      id: 'enm_skeletors_crew_rested',
      name: "Skeletor's Crew, Fully Rested",
      tier: ChartTier.skilled,
      description:
          "The Crew returns, unionised, well-fed, and terrifyingly well-rested. Skeletor's opening demand is a shorter working week.",
    ),
    BastionEnemy(
      id: 'enm_the_twinsters',
      name: 'The Twinsters',
      tier: ChartTier.skilled,
      description:
          "Two of the family's enforcers, identical in silhouette, walk the road looking for anyone foolish enough to be visible.",
    ),
    BastionEnemy(
      id: 'enm_twinsters_reckoning',
      name: "The Twinsters' Reckoning",
      tier: ChartTier.master,
      description:
          'Half the family arrives to settle a debt nobody can remember incurring, and they brought the paperwork.',
    ),
    BastionEnemy(
      id: 'enm_twinsters_family',
      name: 'The Whole Family',
      tier: ChartTier.legend,
      description:
          'Every Twinsters who ever was, walking in step. The road goes quiet behind them and stays quiet for a week.',
    ),
  ];
}

BastionEnemy randomEnemyForTier(ChartTier tier, {Random? rng}) {
  final random = rng ?? Random();
  final pool = getEnemyCatalog().where((e) => e.tier == tier).toList();
  if (pool.isEmpty) return getEnemyCatalog().first;
  return pool[random.nextInt(pool.length)];
}
