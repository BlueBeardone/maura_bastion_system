import 'package:maura_bastion_system/enums/facility_rank.dart';
import 'package:maura_bastion_system/enums/facility_size.dart';
import 'package:maura_bastion_system/models/bastion/prerequisite.dart';
import 'package:maura_bastion_system/models/bastion/table.dart';

class Facility {
  final String name;
  final FacilityRank rank;
  final Prerequisite? prerequisite;
  final FacilitySize space;
  final int hirelingAmount;
  final String description;
  final List<String> boonNames;
  final List<String> boonDescriptions;
  final FacilityTable? table;

  Facility({
    required this.name,
    required this.rank, 
    this.prerequisite, 
    required this.space, 
    required this.hirelingAmount, 
    required this.description, 
    required this.boonNames, 
    required this.boonDescriptions, 
    this.table
  });

  factory Facility.fromJson(Map<String, dynamic> json) {

    return Facility(
      name: json['name'], 
      rank: json['rank'],
      space: json['space'], 
      hirelingAmount: json['hirelingAmount'], 
      description: json['description'], 
      boonNames: json['boonNames'], 
      boonDescriptions: json['boonDescriptions'],
      prerequisite: json['prerequisite'],
      table: json['table'],
    );
  }

  // // Method to convert a User to JSON
  // Map<String, dynamic> toJson() {
  //   return {
  //     'id': id,
  //     'name': name,
  //     'email': email,
  //   };
  // }
}