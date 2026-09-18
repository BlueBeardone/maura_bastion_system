import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';

Bastion _bastion() => Bastion(
      id: 'bastion-1',
      userId: 'user_1',
      name: 'Shadowfen Keep',
      description: 'A misty stronghold.',
      imgUrl: 'https://example.com/keep.png',
      facilities: [
        Facility(
          id: 'keep',
          name: 'Keep',
          rank: Rank.D,
          description: 'The central keep.',
        ),
      ],
      defenders: [
        Defender(id: 'd1', type: DefenderType.knight, bastionId: 'bastion-1'),
      ],
      hirelings: [
        Hireling(id: 'h1', name: 'Tom', bastionId: 'bastion-1'),
      ],
    );

void main() {
  test('copyWith updates name, description and imgUrl, preserving the rest',
      () {
    final updated = _bastion().copyWith(
      name: 'Ravencrest',
      description: 'New description.',
      imgUrl: 'https://example.com/raven.png',
    );

    expect(updated.id, 'bastion-1');
    expect(updated.userId, 'user_1');
    expect(updated.name, 'Ravencrest');
    expect(updated.description, 'New description.');
    expect(updated.imgUrl, 'https://example.com/raven.png');
    expect(updated.facilities, hasLength(1));
    expect(updated.facilities.first.id, 'keep');
    expect(updated.defenders, hasLength(1));
    expect(updated.hirelings, hasLength(1));
  });

  test('copyWith clears imgUrl when passed an explicit null', () {
    final cleared = _bastion().copyWith(imgUrl: null);

    expect(cleared.imgUrl, isNull);
    expect(cleared.name, 'Shadowfen Keep');
  });

  test('copyWith keeps imgUrl when the parameter is omitted', () {
    final kept = _bastion().copyWith(name: 'Ravencrest');

    expect(kept.imgUrl, 'https://example.com/keep.png');
    expect(kept.name, 'Ravencrest');
  });
}
