class Hireling {
  final String id;
  final String name;
  final String? role;
  final String? description;
  final String? imgUrl;
  final String bastionId;
  final String? facilityId;

  Hireling({
    required this.id,
    required this.name,
    this.role,
    this.description,
    this.imgUrl,
    required this.bastionId,
    this.facilityId,
  });

  static const _ignored = Object();

  Hireling copyWith({Object? facilityId = _ignored}) => Hireling(
    id: id,
    name: name,
    role: role,
    description: description,
    imgUrl: imgUrl,
    bastionId: bastionId,
    facilityId: identical(facilityId, _ignored) ? this.facilityId : facilityId as String?,
  );

  factory Hireling.fromJson(Map<String, dynamic> json) {
    return Hireling(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String?,
      description: json['description'] as String?,
      imgUrl: json['imgUrl'] as String?,
      bastionId: json['bastionId'] as String,
      facilityId: json['facilityId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'description': description,
      'imgUrl': imgUrl,
      'bastionId': bastionId,
      'facilityId': facilityId,
    };
  }
}