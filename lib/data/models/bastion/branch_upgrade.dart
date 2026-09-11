import 'package:maura_bastion_system/data/enums/rank.dart';

enum BranchUpgradeKind { oneTime, perTurn, perUse }

class BranchUpgrade {
  final String id;
  final String facilityId;
  final String name;
  final int? cost;
  final Map<Rank, int>? costByRank;
  final String description;
  final BranchUpgradeKind kind;
  final int? hirelingCapacity;

  const BranchUpgrade({
    required this.id,
    required this.facilityId,
    required this.name,
    this.cost,
    this.costByRank,
    required this.description,
    required this.kind,
    this.hirelingCapacity,
  });

  int costFor(Rank rank) => costByRank?[rank] ?? cost ?? 0;
}
