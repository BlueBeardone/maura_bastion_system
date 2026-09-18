// lib/data/default_data/events/trade_road_events.dart
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/dispatch.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

List<ChartEvent> tradeRoadEvents() {
  return const [
    ChartEvent(
      id: 'trd_peddlers_cart',
      name: "Peddlers' Cart",
      chart: EventChart.tradeRoad,
      tier: ChartTier.basic,
      description:
          'A peddler\'s cart creaks up to your gates, full of things nobody needs and everybody wants.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(2, 10),
        note: 'Trinkets and pin-money',
      ),
    ),
    ChartEvent(
      id: 'trd_market_day',
      name: 'Market Day',
      chart: EventChart.tradeRoad,
      tier: ChartTier.basic,
      description:
          'Tolls, stall rents, and a small cut of everything sold. Market day is a good day.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(3, 10),
      ),
    ),
    ChartEvent(
      id: 'trd_letter_of_credit',
      name: 'Letter of Credit',
      chart: EventChart.tradeRoad,
      tier: ChartTier.basic,
      description:
          'A merchant house settles an old debt with a letter of credit. It is worth the ink it is written in — this time.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(2, 12),
      ),
    ),
    ChartEvent(
      id: 'trd_debt_collector',
      name: 'The Debt Collector',
      chart: EventChart.tradeRoad,
      tier: ChartTier.basic,
      description:
          'A collector arrives with a ledger and no sense of humor. One of your hirelings owes money to dangerous people.',
      reward: RewardSpec(
        note: 'Pay 50 GP or lose one hireling this turn (choice at resolution)',
      ),
    ),
    ChartEvent(
      id: 'trd_the_fair',
      name: 'The Fair Comes to Maura',
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'A traveling fair sets up beneath your walls. A rented stall and a generous purse of prizes draw the crowds — and their coin.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(4, 10),
        note: 'After 25 GP of stall fees',
      ),
    ),
    ChartEvent(
      id: 'trd_silk_shipment',
      name: 'Silk Shipment',
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'A shipment of exotic weave needs an armed escort over the ford. Honest pay for honest work.',
      dispatch: DispatchSpec(prompt: 'Escort the silk shipment', maxUnits: 2, dc: 14),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 2),
      ),
    ),
    ChartEvent(
      id: 'trd_exotic_market',
      name: 'Exotic Market',
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'A caravanserai of strange goods pitches camp for a night. You could take coin, or take something rarer.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 2),
        note: 'Or take 150 GP instead (choice at resolution)',
      ),
    ),
    ChartEvent(
      id: 'trd_guest_sanctuary',
      name: 'Seeking Sanctuary',
      chart: EventChart.tradeRoad,
      tier: ChartTier.skilled,
      description:
          'A Notable arrives at your gates asking only for shelter and silence for a turn. Gratitude like that pays well.',
      reward: RewardSpec(
        kind: RewardKind.recruitHireling,
        note: 'A notable seeking sanctuary repays kindness with a gift on leaving',
      ),
    ),
    ChartEvent(
      id: 'trd_diamond_rough',
      name: 'Diamond in the Rough',
      chart: EventChart.tradeRoad,
      tier: ChartTier.master,
      description:
          'A desperate traveler sells you a battered case of oddities for pocket change. Appraising it takes a careful eye — and a willingness to be wrong.',
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(6, 10),
        note: 'Buy low, sell high — or keep it',
      ),
    ),
    ChartEvent(
      id: 'trd_caravan_contract',
      name: 'Caravan Contract',
      chart: EventChart.tradeRoad,
      tier: ChartTier.master,
      description:
          'A great caravan offers a standing contract: guard it across the wild country and share in the profits.',
      dispatch: DispatchSpec(prompt: 'Guard the caravan', maxUnits: 4, dc: 16),
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 2),
        goldDice: UnitDice(3, 10),
      ),
    ),
    ChartEvent(
      id: 'trd_merchant_rival',
      name: 'The Merchant Rival',
      chart: EventChart.tradeRoad,
      tier: ChartTier.master,
      description:
          'A rival house has been undercutting your trade routes for a season. Sit them down at the table and out-haggle them.',
      dispatch: DispatchSpec(prompt: 'Out-negotiate the rival house', maxUnits: 2, dc: 15),
      reward: RewardSpec(
        kind: RewardKind.gold,
        goldDice: UnitDice(4, 10),
        note: 'The rival signs favorable terms',
      ),
    ),
    ChartEvent(
      id: 'trd_merchant_prince',
      name: 'The Merchant Prince',
      chart: EventChart.tradeRoad,
      tier: ChartTier.legend,
      description:
          'The Merchant Prince of Maura invites you to dine, and leaves the port side of the table empty — a sign of respect. His contracts are worth a fortune.',
      reward: RewardSpec(
        kind: RewardKind.material,
        categories: [RewardCategory.weave],
        unitDice: UnitDice(1, 2),
        note: 'Exclusive contract: +50 GP to every future Trade Road reward (permanent)',
      ),
    ),
  ];
}
