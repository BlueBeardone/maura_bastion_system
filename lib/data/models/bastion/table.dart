import 'dart:math';

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

/// Rolls on [table]'s data rows (row 0 is the header) and returns the
/// matching row's cells joined with ' | ', or null if no rows are parseable.
///
/// First-column formats: single number ('1', '8') or inclusive range
/// ('01 - 40', '99 - 00' — 0 as an upper bound means 100). The die size is
/// the highest upper bound; a roll matching no range (table gaps) clamps to
/// the first row whose upper bound is >= the roll.
String? rollTableResult(FacilityTable table, {Random? rng}) {
  final rows = table.table.length <= 1
      ? const <List<String>>[]
      : table.table.sublist(1);

  final parsed = <({int min, int max, List<String> cells})>[];
  for (final row in rows) {
    if (row.isEmpty) continue;
    final match = RegExp(r'^\s*(\d+)\s*(?:-\s*(\d+))?\s*$').firstMatch(row.first);
    if (match == null) continue;
    var min = int.parse(match.group(1)!);
    var max = match.group(2) == null ? min : int.parse(match.group(2)!);
    if (min == 0) min = 100;
    if (max == 0) max = 100;
    if (max < min) continue;
    parsed.add((min: min, max: max, cells: row));
  }
  if (parsed.isEmpty) return null;

  final die = parsed.map((p) => p.max).reduce((a, b) => a > b ? a : b);
  final roll = (rng ?? Random()).nextInt(die) + 1;

  ({int min, int max, List<String> cells})? hit;
  for (final p in parsed) {
    if (roll >= p.min && roll <= p.max) {
      hit = p;
      break;
    }
  }
  hit ??= parsed.firstWhere((p) => p.max >= roll, orElse: () => parsed.last);
  return hit.cells.join(' | ');
}
