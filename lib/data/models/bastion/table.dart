class FacilityTable {
  final List<List<String>> table;

  FacilityTable({required this.table});

  factory FacilityTable.fromJson(Map<String, dynamic> json) {

    return FacilityTable( 
      table: (json['table'] as List? ?? [])
        .map((tableItems) => List<String>.from(tableItems))
        .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'table': table,
    };
  }
}