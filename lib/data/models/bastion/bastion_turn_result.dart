class BastionTurnResult {
  final String bastionId;
  final String bastionName;
  final String quest;
  final BastionTurnAdvancedFacility? advancedFacility;
  final BastionTurnEventResult? event;

  const BastionTurnResult({
    required this.bastionId,
    required this.bastionName,
    required this.quest,
    this.advancedFacility,
    this.event,
  });

  factory BastionTurnResult.fromJson(Map<String, dynamic> json) {
    return BastionTurnResult(
      bastionId: json['bastionId'] as String,
      bastionName: json['bastionName'] as String,
      quest: json['quest'] as String,
      advancedFacility: json['advancedFacility'] == null
          ? null
          : BastionTurnAdvancedFacility.fromJson(
              json['advancedFacility'] as Map<String, dynamic>),
      event: json['event'] == null
          ? null
          : BastionTurnEventResult.fromJson(json['event'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bastionId': bastionId,
      'bastionName': bastionName,
      'quest': quest,
      'advancedFacility': advancedFacility?.toJson(),
      'event': event?.toJson(),
    };
  }
}

class BastionTurnAdvancedFacility {
  final String name;
  final String rankTitle;
  final int constructedTurns;
  final int constructionTurns;

  const BastionTurnAdvancedFacility({
    required this.name,
    required this.rankTitle,
    required this.constructedTurns,
    required this.constructionTurns,
  });

  factory BastionTurnAdvancedFacility.fromJson(Map<String, dynamic> json) {
    return BastionTurnAdvancedFacility(
      name: json['name'] as String,
      rankTitle: json['rankTitle'] as String,
      constructedTurns: json['constructedTurns'] as int,
      constructionTurns: json['constructionTurns'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rankTitle': rankTitle,
      'constructedTurns': constructedTurns,
      'constructionTurns': constructionTurns,
    };
  }
}

class BastionTurnEventResult {
  final String name;
  final String description;
  final String? rolledRow;

  const BastionTurnEventResult({
    required this.name,
    required this.description,
    this.rolledRow,
  });

  factory BastionTurnEventResult.fromJson(Map<String, dynamic> json) {
    return BastionTurnEventResult(
      name: json['name'] as String,
      description: json['description'] as String,
      rolledRow: json['rolledRow'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'rolledRow': rolledRow,
    };
  }
}
