import 'package:maura_bastion_system/data/enums/rank.dart';

enum RewardCategory {
  creaturePart,
  meat,
  blood,
  metal,
  stone,
  wood,
  weave,
  herb;
}

class Reward {
  final String id;
  final String name;
  final RewardCategory category;

  /// The rank/rarity of the material. Null for materials whose rank is
  /// determined when they are harvested (equal to the adventure's rank) —
  /// e.g. creature parts, metals, stones, woods, weaves, meat and blood.
  final Rank? rank;

  /// Market value in GP per unit. Null when [rank] is null — such materials
  /// use `mainChartValueByRank` (meat/blood use `mainChartMeatBloodValueByRank`).
  final int? marketValue;

  /// Weight of one unit in pounds.
  final double weightPerUnit;

  /// Description from the crafting guide, including the material's element
  /// tag, e.g. '[Fire] unearthed from the calderas of volcanos...'.
  final String description;

  const Reward({
    required this.id,
    required this.name,
    required this.category,
    this.rank,
    this.marketValue,
    required this.weightPerUnit,
    required this.description,
  });
}
