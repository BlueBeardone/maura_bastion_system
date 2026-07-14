import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';

class Bastion {
  final String id;
  final String name;
  final String description;
  final String? imgUrl;
  final List<Facility> facilities;
  final List<Defender> defenders;
  final List<Hireling> hirelings;

  Bastion({
    required this.id,
    required this.name,
    required this.description,
    this.imgUrl,
    required this.facilities,
    this.defenders = const [],
    this.hirelings = const [],
  });

  List<Hireling> getFacilityHirelings(String facilityId) =>
      hirelings.where((h) => h.facilityId == facilityId).toList();

  List<Hireling> get unassignedHirelings =>
      hirelings.where((h) => h.facilityId == null).toList();

  int facilityHirelingCount(String facilityId) =>
      hirelings.where((h) => h.facilityId == facilityId).length;

  factory Bastion.fromJson(Map<String, dynamic> json) {
    return Bastion(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imgUrl: json['imgUrl'] as String?,
      facilities: (json['facilities'] as List? ?? [])
          .map((facility) => Facility.fromJson(facility as Map<String, dynamic>))
          .toList(),
      defenders: (json['defenders'] as List? ?? [])
          .map((defender) => Defender.fromJson(defender as Map<String, dynamic>))
          .toList(),
      hirelings: (json['hirelings'] as List? ?? [])
          .map((h) => Hireling.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imgUrl': imgUrl,
      'facilities': facilities.map((facility) => facility.toJson()).toList(),
      'defenders': defenders.map((defender) => defender.toJson()).toList(),
      'hirelings': hirelings.map((h) => h.toJson()).toList(),
    };
  }
}
