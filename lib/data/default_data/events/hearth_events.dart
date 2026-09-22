// lib/data/default_data/events/hearth_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';

List<ChartEvent> hearthEvents() {
  return const [
    ChartEvent(
      id: 'hrt_quiet_evening',
      name: 'Quiet Evening',
      chart: EventChart.hearth,
      tier: ChartTier.basic,
      description:
          'The fire is lit, the stew is good, and nobody is bleeding. A quiet evening at the bastion.',
      reward: RewardSpec(
        note: 'The bastion is warm and quiet',
      ),
    ),
    ChartEvent(
      id: 'hrt_loose_boardwork',
      name: 'Loose Boardwork',
      chart: EventChart.hearth,
      tier: ChartTier.basic,
      description:
          'A hireling swears the floorboards creak louder than yesterday. The carpenter wants paying either way.',
      reward: RewardSpec(
        note: 'Pay 10 GP or a hireling grumbles (+2 DC on the next Hearth dispatch)',
      ),
    ),
    ChartEvent(
      id: 'hrt_kitchen_fire',
      name: 'Kitchen Fire',
      chart: EventChart.hearth,
      tier: ChartTier.basic,
      description:
          'The kitchen caught alight mid-roast. Save the stores and there may be salvage worth keeping.',
      dispatch: DispatchSpec(prompt: 'Fight the kitchen fire', maxUnits: 2, dc: 6),
      reward: RewardSpec(
        note: 'Your hirelings salvage what the flames spared',
        failureNote: 'The fire wins this round; the kitchen smells of smoke for days',
      ),
    ),
    ChartEvent(
      id: 'hrt_cellar_rats',
      name: 'Cellar Rats',
      chart: EventChart.hearth,
      tier: ChartTier.basic,
      description:
          'The cellar rats have grown fat, bold, and enormous. The village pays a bounty per tail.',
      dispatch: DispatchSpec(prompt: 'Clear the cellar rats', maxUnits: 2, dc: 8),
      reward: RewardSpec(
        note: 'Your hirelings split the rat-catching bounty over drinks',
        failureNote: 'The rats keep the cellar for now',
      ),
    ),
    ChartEvent(
      id: 'hrt_giant_bees',
      name: 'Giant Honeybees',
      chart: EventChart.hearth,
      tier: ChartTier.skilled,
      description:
          'A swarm of giant honeybees has settled in the barn. They can be driven off — or a brave soul might domesticate them.',
      dispatch: DispatchSpec(prompt: 'Deal with the bees', maxUnits: 2, dc: 10),
      reward: RewardSpec(
        note: 'Domesticate for a permanent +1 to herb rewards, or drive them off',
      ),
    ),
    ChartEvent(
      id: 'hrt_criminal_hireling',
      name: 'Criminal Hireling',
      chart: EventChart.hearth,
      tier: ChartTier.skilled,
      description:
          'One of your hirelings has a past, and the past has caught up. A collector waits at the gate with paperwork.',
      reward: RewardSpec(
        note: 'Pay 60 GP or lose one hireling (choice at resolution)',
      ),
    ),
    ChartEvent(
      id: 'hrt_wandering_professional',
      name: 'Wandering Professional',
      chart: EventChart.hearth,
      tier: ChartTier.skilled,
      description:
          'A tinker of rare skill passes through, admires the bastion, and asks to stay. Free, and worth every copper.',
      reward: RewardSpec(
        kind: RewardKind.recruitHireling,
        note: 'A wandering professional asks to join for free',
      ),
    ),
    ChartEvent(
      id: 'hrt_harvest_festival',
      name: 'Harvest Festival',
      chart: EventChart.hearth,
      tier: ChartTier.skilled,
      description:
          'The bastion hosts the season\'s festival. Stall fees, drinking songs, and a remarkably honest dice game.',
      reward: RewardSpec(
        note:
            'Your hirelings come home from the festival with full pockets and loud songs',
      ),
    ),
    ChartEvent(
      id: 'hrt_famed_bard',
      name: 'The Famed Bard',
      chart: EventChart.hearth,
      tier: ChartTier.master,
      description:
          'A bard whose name opens doors in three kingdoms has chosen YOUR common room for a residency. The crowds follow.',
      reward: RewardSpec(
        note: 'Your hirelings bask in a week of a full common room',
      ),
    ),
    ChartEvent(
      id: 'hrt_grievance',
      name: 'The Grievance',
      chart: EventChart.hearth,
      tier: ChartTier.master,
      description:
          'Half the hirelings have signed a complaint about the other half. Settle it fairly and morale soars; fumble it and the work suffers.',
      dispatch: DispatchSpec(prompt: 'Hear the grievance', maxUnits: 2, dc: 12),
      reward: RewardSpec(
        note: 'Settled fairly: +2 to the next Hearth dispatch',
        failureNote: 'The grievance festers, and the work suffers',
      ),
    ),
    ChartEvent(
      id: 'hrt_masterwork_order',
      name: 'Masterwork Order',
      chart: EventChart.hearth,
      tier: ChartTier.master,
      description:
          'A visiting tailor has seen your workshops and wants a commission done to your house\'s standard. Payment is generous; the deadline is not.',
      dispatch: DispatchSpec(prompt: 'Fulfil the masterwork order', maxUnits: 2, dc: 11),
      reward: RewardSpec(
        note: 'Your workshops take on the tailor\'s commission with pride',
        failureNote: 'The tailor takes his commission elsewhere',
      ),
    ),
    ChartEvent(
      id: 'hrt_heart_of_the_bastion',
      name: 'Heart of the Bastion',
      chart: EventChart.hearth,
      tier: ChartTier.legend,
      description:
          'For one golden turn, everything works: the fires burn clean, the ale is sweet, and every hireling remembers why they came. Something like this can last, if you tend it.',
      dispatch: DispatchSpec(prompt: 'Tend the heart of the bastion', maxUnits: 4, dc: 14),
      reward: RewardSpec(
        kind: RewardKind.recruitHireling,
        note: 'Permanent: +1 to all Hearth dispatch totals',
        failureNote: 'The heart of the bastion dims, and the hirelings feel it',
      ),
    ),
  ];
}
