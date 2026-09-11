import 'package:maura_bastion_system/data/models/bastion/table.dart';

class IndividualBastionEvent {
  final String id;
  final String name;
  final int rollMin;
  final int rollMax;
  final String description;
  final FacilityTable? table;

  IndividualBastionEvent({
    required this.id,
    required this.name,
    required this.rollMin,
    required this.rollMax,
    required this.description,
    this.table,
  });

  factory IndividualBastionEvent.fromJson(Map<String, dynamic> json) {
    return IndividualBastionEvent(
      id: json['id'] as String,
      name: json['name'] as String,
      rollMin: json['rollMin'] as int,
      rollMax: json['rollMax'] as int,
      description: json['description'] as String,
      table: json['table'] == null
          ? null
          : FacilityTable.fromJson(json['table'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rollMin': rollMin,
      'rollMax': rollMax,
      'description': description,
      'table': table?.toJson(),
    };
  }

  bool matchesRoll(int roll) => roll >= rollMin && roll <= rollMax;
}
