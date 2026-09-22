import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/chart_event.dart';
import 'package:maura_bastion_system/data/models/events/chart_tier.dart';
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
      reward.recruit != RewardKind.none ||
      event.tier == ChartTier.legend ||
      bonusArchetype != null;
  if (!notable) return null;

  final content =
      '${event.description}\n\nRewards: ${rewardSummaryText(reward)}.'
      '${bonusArchetype != null ? '\n\nElsewhere in Maura: ${bonusArchetype.description}' : ''}';

  return NewspaperArticle(
    title: '${event.name.toUpperCase()} AT ${bastion.name.toUpperCase()}',
    content: content,
    imageUrl: null,
    author: 'Bastion Correspondent',
  );
}
