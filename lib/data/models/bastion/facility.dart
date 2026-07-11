import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';

class Facility {
  final String id;
  final String name;
  final Rank rank;
  int get hirelingAmount => hirelings.length;
  final String description;
  final String? imgUrl;
  final FacilityTable? table;
  final List<Hireling> hirelings;

  Facility({
    required this.id,
    required this.name,
    required this.rank,
    required this.description,
    this.imgUrl,
    this.table,
    this.hirelings = const [],
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
      hirelings: (json['hirelings'] as List<dynamic>? ?? [])
          .map((h) => Hireling.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rank': rank.title.toLowerCase(),
      'hirelingAmount': hirelingAmount,
      'description': description,
      'imgUrl': imgUrl,
      'table': table?.toJson(),
      'hirelings': hirelings.map((h) => h.toJson()).toList(),
    };
  }
}