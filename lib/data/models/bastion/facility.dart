import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';

class Facility {
  final String id;
  final String name;
  final Rank rank;
  final int minimumRequiredHirelings;
  final int constructionTurns;
  final int cost;
  final String description;
  final String? imgUrl;
  final FacilityTable? table;
  final int constructedTurns;

  Facility({
    required this.id,
    required this.name,
    required this.rank,
    required this.description,
    this.imgUrl,
    this.table,
    this.minimumRequiredHirelings = 0,
    this.constructionTurns = 0,
    this.cost = 0,
    this.constructedTurns = 0,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'] as String,
      name: json['name'] as String,
      rank: Rank.fromString((json['rank'] as String).toLowerCase().trim()),
      description: json['description'] as String,
      imgUrl: json['imgUrl'] as String?,
      table: json['table'] == null
          ? null
          : FacilityTable.fromJson(json['table'] as Map<String, dynamic>),
      minimumRequiredHirelings: json['minimumRequiredHirelings'] as int? ?? 0,
      constructionTurns: json['constructionTurns'] as int? ?? 0,
      cost: json['cost'] as int? ?? 0,
      constructedTurns: json['constructedTurns'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rank': rank.title.toLowerCase(),
      'description': description,
      'imgUrl': imgUrl,
      'table': table?.toJson(),
      'minimumRequiredHirelings': minimumRequiredHirelings,
      'constructionTurns': constructionTurns,
      'cost': cost,
      'constructedTurns': constructedTurns,
    };
  }
}
