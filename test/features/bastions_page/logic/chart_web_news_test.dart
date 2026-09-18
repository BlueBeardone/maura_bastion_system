// test/features/bastions_page/logic/chart_web_news_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/default_data/rewards/default_reward_data.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/features/bastions_page/logic/chart_web_news.dart';

Bastion _bastion() => Bastion(id: 'b1', name: 'Highfell', description: '', facilities: const []);

TurnReward _rewardWith(RewardGrant grant) => TurnReward(
      materials: [grant],
      gold: 0,
      recruit: RewardKind.none,
    );

void main() {
  final adamantine = getDefaultRewards().firstWhere((r) => r.id == 'rew_adamantine');

  test('returns null for modest results', () {
    final herb = getDefaultRewards().firstWhere((r) => r.id == 'rew_blue_herb');
    final article = notableResultArticle(
      bastion: _bastion(),
      event: _basicEvent(),
      reward: _rewardWith(RewardGrant(reward: herb, effectiveRank: Rank.E, units: 2)),
    );
    expect(article, isNull);
  });

  test('rank B or better materials are notable', () {
    final article = notableResultArticle(
      bastion: _bastion(),
      event: _basicEvent(),
      reward: _rewardWith(RewardGrant(reward: adamantine, effectiveRank: Rank.B, units: 2)),
    );
    expect(article, isNotNull);
    expect(article!.title, 'WOLF CULL AT HIGHFELL');
    expect(article.author, 'Bastion Correspondent');
    expect(article.content, contains('Adamantine'));
  });

  test('gold of 500 or more is notable', () {
    final article = notableResultArticle(
      bastion: _bastion(),
      event: _basicEvent(),
      reward: const TurnReward(materials: [], gold: 500, recruit: RewardKind.none),
    );
    expect(article, isNotNull);
    expect(article!.content, contains('500 GP'));
  });

  test('recruit and legend and bonus archetype are notable', () {
    expect(
      notableResultArticle(
        bastion: _bastion(),
        event: _basicEvent(),
        reward: const TurnReward(materials: [], gold: 0, recruit: RewardKind.recruitDefender),
      ),
      isNotNull,
    );
    expect(
      notableResultArticle(
        bastion: _bastion(),
        event: _legendEvent(),
        reward: const TurnReward(materials: [], gold: 0, recruit: RewardKind.none),
      ),
      isNotNull,
    );
    expect(
      notableResultArticle(
        bastion: _bastion(),
        event: _basicEvent(),
        reward: const TurnReward(materials: [], gold: 0, recruit: RewardKind.none),
        bonusArchetype: _bonusEvent(),
      ),
      isNotNull,
    );
  });
}

ChartEvent _basicEvent() => const ChartEvent(
      id: 'evt_b',
      name: 'Wolf Cull',
      chart: EventChart.wilds,
      tier: ChartTier.basic,
      description: 'Wolves.',
    );

ChartEvent _legendEvent() => const ChartEvent(
      id: 'evt_l',
      name: 'The Beast of Maura',
      chart: EventChart.wilds,
      tier: ChartTier.legend,
      description: 'The Beast.',
    );

ChartEvent _bonusEvent() => const ChartEvent(
      id: 'evt_x',
      name: "The Alchemist's Commission",
      chart: EventChart.wilds,
      tier: ChartTier.skilled,
      description: 'A commission.',
      relatedCharts: {EventChart.wilds, EventChart.arcane},
      minPointsPerChart: 4,
    );
