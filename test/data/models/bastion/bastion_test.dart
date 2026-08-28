import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';

void main() {
  group('Bastion', () {
    final testJson = {
      'id': 'bastion_1',
      'userId': 'user_1',
      'name': 'Aurelian Keep',
      'description': 'A grand keep',
      'imgUrl': 'https://example.com/keep.png',
      'facilities': [],
      'defenders': [],
      'hirelings': [],
    };

    final testJsonNoOptional = {
      'id': 'bastion_2',
      'name': 'Briarwatch Garrison',
      'description': 'A rugged outpost',
    };

    group('fromJson', () {
      test('parses all fields when present', () {
        final bastion = Bastion.fromJson(testJson);

        expect(bastion.id, 'bastion_1');
        expect(bastion.userId, 'user_1');
        expect(bastion.name, 'Aurelian Keep');
        expect(bastion.description, 'A grand keep');
        expect(bastion.imgUrl, 'https://example.com/keep.png');
        expect(bastion.facilities, isEmpty);
        expect(bastion.defenders, isEmpty);
        expect(bastion.hirelings, isEmpty);
      });

      test('parses nullable fields as null when absent', () {
        final bastion = Bastion.fromJson(testJsonNoOptional);

        expect(bastion.id, 'bastion_2');
        expect(bastion.userId,null);
        expect(bastion.name, 'Briarwatch Garrison');
        expect(bastion.description, 'A rugged outpost');
        expect(bastion.imgUrl,null);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final bastion = Bastion(
          id: 'bastion_1',
          userId: 'user_1',
          name: 'Aurelian Keep',
          description: 'A grand keep',
          imgUrl: 'https://example.com/keep.png',
          facilities: const [],
        );

        final json = bastion.toJson();

        expect(json['id'], 'bastion_1');
        expect(json['userId'], 'user_1');
        expect(json['name'], 'Aurelian Keep');
        expect(json['description'], 'A grand keep');
        expect(json['imgUrl'], 'https://example.com/keep.png');
      });
    });

    group('belongsTo', () {
      test('returns true when userId matches', () {
        final bastion = Bastion(
          id: 'bastion_1',
          userId: 'user_1',
          name: 'Aurelian Keep',
          description: 'A grand keep',
          facilities: const [],
        );

        expect(bastion.belongsTo('user_1'), isTrue);
      });

      test('returns false when userId differs', () {
        final bastion = Bastion(
          id: 'bastion_2',
          userId: 'user_2',
          name: 'Briarwatch Garrison',
          description: 'A rugged outpost',
          facilities: const [],
        );

        expect(bastion.belongsTo('user_1'), isFalse);
      });

      test('returns false when userId is null', () {
        final bastion = Bastion(
          id: 'bastion_3',
          name: 'Stonegate Bastion',
          description: 'An old fortress',
          facilities: const [],
        );

        expect(bastion.belongsTo('user_1'), isFalse);
      });
    });
  });
}