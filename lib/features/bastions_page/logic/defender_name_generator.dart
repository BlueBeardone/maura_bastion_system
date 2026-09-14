import 'dart:math';

class DefenderNameGenerator {
  DefenderNameGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const _firstNames = [
    'Aldric', 'Bram', 'Cedric', 'Dorian', 'Edwin', 'Fendrel', 'Gareth',
    'Hamon', 'Ivo', 'Jorund', 'Kellen', 'Leofric', 'Merek', 'Niles',
    'Osric', 'Percival', 'Quintus', 'Rowan', 'Sigmund', 'Thane', 'Ulric',
    'Varian', 'Wystan', 'Yorick', 'Aldous', 'Bertrand', 'Corwin', 'Dunstan',
    'Everard', 'Godric', 'Halric', 'Irwin', 'Jareth', 'Kendrick', 'Lucan',
    'Marlow', 'Osbert', 'Roderick', 'Talmadge', 'Wilfred',
  ];

  static const _surnames = [
    'Vane', 'Oakfist', 'Ashdown', 'Blackwood', 'Castellan', 'Dunmar',
    'Eastvale', 'Fenwick', 'Grimwald', 'Hale', 'Ironhart', 'Jessup',
    'Kells', 'Lockwood', 'Marsh', 'Northgate', 'Ormsby', 'Peverell',
    'Quill', 'Ravensworth', 'Stonebrook', 'Thornbury', 'Underhill',
    'Vexley', 'Wraithmoor', 'Yewdale', 'Ashcombe', 'Coldwater', 'Draymoor',
    'Elmsworth', 'Fallbrook', 'Greywell', 'Halloway', 'Ironwood',
    'Kingsley', 'Larkspur', 'Mistvale', 'Norwood', 'Oakenshield', 'Saltmarsh',
  ];

  List<String> generate(int count) {
    assert(
      count <= _firstNames.length * _surnames.length,
      'Cannot generate $count unique names from the name pool',
    );
    final names = <String>{};
    while (names.length < count) {
      final first = _firstNames[_random.nextInt(_firstNames.length)];
      final surname = _surnames[_random.nextInt(_surnames.length)];
      names.add('$first $surname');
    }
    return names.toList();
  }
}