import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
import 'package:maura_bastion_system/data/models/events/reward_spec.dart';
import 'package:maura_bastion_system/data/models/events/turn_flow.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';

NewspaperArticle? notableResultArticle({
  required Bastion bastion,
  required ChartEvent event,
  required TurnReward reward,
  ChartEvent? bonusArchetype,
}) {
  final notableMaterial = reward.materials.any(
    (g) => g.effectiveRank.index <= Rank.B.index,
  );
  final notable = notableMaterial ||
      reward.gold >= 500 ||
      reward.recruit != RewardKind.none ||
      event.tier == ChartTier.legend ||
      bonusArchetype != null;
  if (!notable) return null;

  final summaryParts = <String>[
    for (final g in reward.materials)
      '${g.units} \u00d7 ${g.reward.name} (Rank ${g.effectiveRank.title})',
    if (reward.gold > 0) '${reward.gold} GP',
    if (reward.recruit == RewardKind.recruitDefender) 'a new defender',
    if (reward.recruit == RewardKind.recruitHireling) 'a new hireling',
  ];
  final content =
      '${event.description}\n\nRewards: ${summaryParts.isEmpty ? 'none recorded' : summaryParts.join(', ')}.'
      '${bonusArchetype != null ? '\n\nElsewhere in Maura: ${bonusArchetype.description}' : ''}';

  return NewspaperArticle(
    title: '${event.name.toUpperCase()} AT ${bastion.name.toUpperCase()}',
    content: content,
    imageUrl: null,
    author: 'Bastion Correspondent',
  );
}
