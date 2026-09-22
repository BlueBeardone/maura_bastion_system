// lib/data/default_data/events/war_march_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

List<ChartEvent> warMarchEvents() {
  return const [
    ChartEvent(
      id: 'wrm_wolf_pack',
      name: 'Wolf Pack',
      chart: EventChart.warMarch,
      tier: ChartTier.basic,
      description:
          'A pack of dire wolves has been shadowing your supply carts. Drive them off and take the pelts.',
      dispatch: DispatchSpec(prompt: 'Drive off the wolf pack', maxUnits: 2, dc: 12),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
      ),
    ),
    ChartEvent(
      id: 'wrm_scavenger_band',
      name: 'Scavenger Band',
      chart: EventChart.warMarch,
      tier: ChartTier.basic,
      description:
          'Deserters turned scavengers have been raiding the fields. Run them off and reclaim what they stole.',
      dispatch: DispatchSpec(prompt: 'Rout the scavengers', maxUnits: 2, dc: 12),
      reward: RewardSpec(
        note: 'Your defenders reclaim the stolen goods for the bastion',
        failureNote: 'The scavengers slip away with their loot',
      ),
    ),
    ChartEvent(
      id: 'wrm_lost_patrol',
      name: 'Lost Patrol',
      chart: EventChart.warMarch,
      tier: ChartTier.basic,
      description:
          'Two soldiers from a broken company stagger up to your gates. They fought well; they are yours if you will have them.',
      reward: RewardSpec(
        kind: RewardKind.recruitDefender,
        note: 'Stragglers from a broken company ask to stay',
      ),
    ),
    ChartEvent(
      id: 'wrm_lookout_duty',
      name: 'Lookout Duty',
      chart: EventChart.warMarch,
      tier: ChartTier.basic,
      description:
          'A quiet turn on the walls. The watch counts stars, and nothing stirs.',
      reward: RewardSpec(
        note: 'Nothing stirs tonight',
      ),
    ),
    ChartEvent(
      id: 'wrm_bandit_camp',
      name: 'Bandit Camp',
      chart: EventChart.warMarch,
      tier: ChartTier.skilled,
      description:
          'Your outriders found the bandit camp that has been bleeding the roads. Take it, and everything in it.',
      dispatch: DispatchSpec(prompt: 'Storm the bandit camp', maxUnits: 3, dc: 14),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
        note: 'Everything in the camp is yours to carry off',
        failureNote: 'The bandits scatter into the hills with their plunder',
      ),
    ),
    ChartEvent(
      id: 'wrm_duel',
      name: 'The Duel',
      chart: EventChart.warMarch,
      tier: ChartTier.skilled,
      description:
          'A wandering knight rides up to your gates and demands single combat with your champion. Beat him, and his sword is yours.',
      dispatch: DispatchSpec(
        prompt: 'Send your champion',
        maxUnits: 1,
        dc: 4,
      ),
      reward: RewardSpec(
        kind: RewardKind.recruitDefender,
        note: 'The wandering knight joins if defeated',
      ),
    ),
    ChartEvent(
      id: 'wrm_raider_raid',
      name: 'Raid the Raiders',
      chart: EventChart.warMarch,
      tier: ChartTier.skilled,
      description:
          'The raiders who burned the east fields are camped, drunk, and unaware. Return the favor.',
      dispatch: DispatchSpec(prompt: 'Raid the raiders\' camp', maxUnits: 4, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
        note: 'Your defenders haul back the raiders\' loot and war-beast remains',
        failureNote: 'The raiders wake, and your raiding party slips away empty-handed',
      ),
    ),
    ChartEvent(
      id: 'wrm_siege_scare',
      name: 'Siege Scare',
      chart: EventChart.warMarch,
      tier: ChartTier.skilled,
      description:
          'Raiders prowl your walls all night looking for a way in. A stubborn watch sends them looking for easier pickings.',
      dispatch: DispatchSpec(prompt: 'Hold the walls through the night', maxUnits: 4, dc: 15),
      reward: RewardSpec(
        note: 'The raiders withdraw before dawn; the watch toasts its stubbornness',
        failureNote: 'The raiders find their way in — the morning tells the cost',
      ),
    ),
    ChartEvent(
      id: 'wrm_champion_challenge',
      name: 'Champion\'s Challenge',
      chart: EventChart.warMarch,
      tier: ChartTier.master,
      description:
          'A warlord of Maura sends a formal challenge: her champion against yours, winner takes the field and the warlord\'s purse.',
      dispatch: DispatchSpec(prompt: 'Answer the challenge', maxUnits: 2, dc: 18),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 2),
        note: 'The warlord\'s purse funds a victory feast for the whole bastion',
        failureNote: 'Your champion falls, and the field is the warlord\'s',
      ),
    ),
    ChartEvent(
      id: 'wrm_lieutenant_offer',
      name: 'The Lieutenant\'s Offer',
      chart: EventChart.warMarch,
      tier: ChartTier.master,
      description:
          'A veteran lieutenant, unattached since her lord fell, offers you her banner and her blade. She does not offer twice.',
      reward: RewardSpec(
        kind: RewardKind.recruitDefender,
        note: 'A veteran lieutenant offers her banner',
      ),
    ),
    ChartEvent(
      id: 'wrm_enemy_forge',
      name: 'The Enemy Forge',
      chart: EventChart.warMarch,
      tier: ChartTier.master,
      description:
          'The war-camp arming Maura\'s enemies has a forge that never cools. Break it, and carry off whatever they were stockpiling.',
      dispatch: DispatchSpec(prompt: 'Break the enemy forge', maxUnits: 4, dc: 17),
      reward: RewardSpec(
        note: 'Your defenders break the forge and carry off the stockpile',
        failureNote: 'The forge burns on, arming Maura\'s enemies',
      ),
    ),
    ChartEvent(
      id: 'wrm_the_black_banner',
      name: 'The Black Banner',
      chart: EventChart.warMarch,
      tier: ChartTier.legend,
      description:
          'The Black Banner — the war-band that has never lost a siege — marches on Maura, and yours stands in its road. Beat it, and the legend is yours.',
      dispatch: DispatchSpec(prompt: 'Face the Black Banner', maxUnits: 4, dc: 20),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.creaturePart],
        unitDice: UnitDice(1, 1),
        note: 'The Black Banner breaks, and its legend passes to your bastion',
        failureNote: 'The Black Banner marches on',
      ),
    ),
  ];
}
