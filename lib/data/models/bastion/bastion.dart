import 'package:maura_bastion_system/data/models/bastion/facility.dart';

class Bastion {
  final String id;
  final String name;
  final String description;
  final String? imgUrl;
  final List<Facility> facilities;

  Bastion({
    required this.id,
    required this.name,
    required this.description,
    this.imgUrl,
    required this.facilities,
  });

  factory Bastion.fromJson(Map<String, dynamic> json) {
    return Bastion(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imgUrl: json['imgUrl'] as String?,
      facilities: (json['facilities'] as List? ?? [])
          .map((facility) => Facility.fromJson(facility as Map<String, dynamic>))
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
    };
  }
}