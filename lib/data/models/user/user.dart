class User {
  final String id;
  final String displayName;
  final String? bastionId;

  User({
    required this.id,
    required this.displayName,
    this.bastionId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      bastionId: json['bastionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'bastionId': bastionId,
    };
  }
}