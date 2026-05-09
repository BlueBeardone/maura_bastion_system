import 'package:maura_bastion_system/data/enums/facility_rank.dart';
import 'package:maura_bastion_system/data/models/bastion/table.dart';

class Facility {
  final String name;
  final FacilityRank rank;
  final int hirelingAmount;
  final String description;
  final FacilityTable? table;

  Facility({
    required this.name,
    required this.rank, 
    required this.hirelingAmount, 
    required this.description,
    this.table
  });

  factory Facility.fromJson(Map<String, dynamic> json) {

    return Facility(
      name: json['name'] as String, 
      rank: FacilityRank.fromString((json['rank'] as String).toLowerCase().trim()),
      hirelingAmount: json['hirelingAmount'] as int, 
      description: json['description'] as String,
      table: json['table'] == null ? null : FacilityTable.fromJson(json['table'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rank': rank.title.toLowerCase(),
      'hirelingAmount': hirelingAmount,
      'description': description,
      'table': table?.toJson(),
    };
  }
}