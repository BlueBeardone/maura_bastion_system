class Prerequisite {
  final List<String>? spellCastingFocus;
  final List<String>? proficiencies;
  final List<String>? facility;

  Prerequisite({
    required this.spellCastingFocus, 
    required this.proficiencies, 
    required this.facility
  });

  factory Prerequisite.fromJson(Map<String, dynamic> json) {

    return Prerequisite(
      spellCastingFocus: List<String>.from(json['spellCastingFocus'] ?? []), 
      proficiencies: List<String>.from(json['proficiencies'] ?? []),
      facility: List<String>.from(json['facility'] ?? []),
    );
  }
}