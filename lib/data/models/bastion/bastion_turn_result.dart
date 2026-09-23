class BastionTurnResult {
  final String bastionId;
  final String bastionName;
  final String quest;
  final BastionTurnAdvancedFacility? advancedFacility;
  final BastionTurnEventResult? event;
  final List<BastionTurnFacilityResult> facilityResults;

  const BastionTurnResult({
    required this.bastionId,
    required this.bastionName,
    required this.quest,
    this.advancedFacility,
    this.event,
    this.facilityResults = const [],
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
      facilityResults: (json['facilityResults'] as List? ?? [])
          .map((r) => BastionTurnFacilityResult.fromJson(
              r as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bastionId': bastionId,
      'bastionName': bastionName,
      'quest': quest,
      'advancedFacility': advancedFacility?.toJson(),
      'event': event?.toJson(),
      'facilityResults': facilityResults.map((r) => r.toJson()).toList(),
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

class BastionTurnFacilityResult {
  final String name;
  final String? rolledRow;

  const BastionTurnFacilityResult({
    required this.name,
    this.rolledRow,
  });

  factory BastionTurnFacilityResult.fromJson(Map<String, dynamic> json) {
    return BastionTurnFacilityResult(
      name: json['name'] as String,
      rolledRow: json['rolledRow'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rolledRow': rolledRow,
    };
  }
}

class BastionTurnDispatchUnitResult {
  final String name;
  final List<int> rolls;
  final int subtotal;

  const BastionTurnDispatchUnitResult({
    required this.name,
    required this.rolls,
    required this.subtotal,
  });

  factory BastionTurnDispatchUnitResult.fromJson(Map<String, dynamic> json) {
    return BastionTurnDispatchUnitResult(
      name: json['name'] as String,
      rolls: (json['rolls'] as List? ?? []).map((r) => r as int).toList(),
      subtotal: json['subtotal'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rolls': rolls,
      'subtotal': subtotal,
    };
  }
}

class BastionTurnDispatchResult {
  final List<BastionTurnDispatchUnitResult> units;
  final int bonus;
  final int total;
  final int dc;
  final bool success;

  const BastionTurnDispatchResult({
    required this.units,
    required this.bonus,
    required this.total,
    required this.dc,
    required this.success,
  });

  factory BastionTurnDispatchResult.fromJson(Map<String, dynamic> json) {
    return BastionTurnDispatchResult(
      units: (json['units'] as List? ?? [])
          .map((u) => BastionTurnDispatchUnitResult.fromJson(
              u as Map<String, dynamic>))
          .toList(),
      bonus: json['bonus'] as int? ?? 0,
      total: json['total'] as int,
      dc: json['dc'] as int,
      success: json['success'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'units': units.map((u) => u.toJson()).toList(),
      'bonus': bonus,
      'total': total,
      'dc': dc,
      'success': success,
    };
  }
}

class BastionTurnEventResult {
  final String name;
  final String description;
  final String? rolledRow;
  final String? rewardSummary;

  /// Name of a facility knocked offline for one construction turn by a failed
  /// dispatch, if any.
  final String? closedFacilityName;
  final BastionTurnDispatchResult? dispatch;

  const BastionTurnEventResult({
    required this.name,
    required this.description,
    this.rolledRow,
    this.rewardSummary,
    this.closedFacilityName,
    this.dispatch,
  });

  factory BastionTurnEventResult.fromJson(Map<String, dynamic> json) {
    return BastionTurnEventResult(
      name: json['name'] as String,
      description: json['description'] as String,
      rolledRow: json['rolledRow'] as String?,
      rewardSummary: json['rewardSummary'] as String?,
      closedFacilityName: json['closedFacilityName'] as String?,
      dispatch: json['dispatch'] == null
          ? null
          : BastionTurnDispatchResult.fromJson(
              json['dispatch'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'rolledRow': rolledRow,
      'rewardSummary': rewardSummary,
      'closedFacilityName': closedFacilityName,
      'dispatch': dispatch?.toJson(),
    };
  }
}
