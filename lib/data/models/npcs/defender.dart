import 'package:maura_bastion_system/data/enums/defender_type.dart';

class Defender {
  final String id;
  final String? name;
  final String? description;
  final String? imgUrl;
  final DefenderType type;
  final String bastionId;

  Defender({
    required this.id,
    this.name,
    this.description,
    this.imgUrl,
    required this.type,
    required this.bastionId,
  });

  factory Defender.fromJson(Map<String, dynamic> json) {
    return Defender(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      imgUrl: json['imgUrl'] as String?,
      type: DefenderType.fromString(json['type'] as String),
      bastionId: json['bastionId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imgUrl': imgUrl,
      'type': type.title.toLowerCase(),
      'bastionId': bastionId,
    };
  }
}
