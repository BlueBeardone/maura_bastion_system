import 'package:maura_bastion_system/data/enums/defender_type.dart';

class Defender {
  final String id;
  final String? name;
  final String? description;
  final String? imgUrl;
  final DefenderType type;
  final String bastionId;
  final String? acquisitionStory;

  Defender({
    required this.id,
    this.name,
    this.description,
    this.imgUrl,
    required this.type,
    required this.bastionId,
    this.acquisitionStory,
  });

  Defender copyWith({
    String? id,
    String? name,
    String? description,
    String? imgUrl,
    DefenderType? type,
    String? bastionId,
    String? acquisitionStory,
  }) {
    return Defender(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imgUrl: imgUrl ?? this.imgUrl,
      type: type ?? this.type,
      bastionId: bastionId ?? this.bastionId,
      acquisitionStory: acquisitionStory ?? this.acquisitionStory,
    );
  }

  factory Defender.fromJson(Map<String, dynamic> json) {
    return Defender(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      imgUrl: json['imgUrl'] as String?,
      type: DefenderType.fromString(json['type'] as String),
      bastionId: json['bastionId'] as String,
      acquisitionStory: json['acquisitionStory'] as String?,
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
      'acquisitionStory': acquisitionStory,
    };
  }
}
