import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';

void main() {
  group('Defender', () {
    final testJson = {
      'id': 'def_1',
      'name': 'Sir Aldric',
      'description': 'A noble knight of the realm',
      'imgUrl': 'https://example.com/knight.png',
      'type': 'knight',
      'bastionId': 'bastion_1',
    };

    final testJsonNoOptional = {
      'id': 'def_2',
      'type': 'beast',
      'bastionId': 'bastion_1',
    };

    group('fromJson', () {
      test('parses all fields when present', () {
        final defender = Defender.fromJson(testJson);

        expect(defender.id, 'def_1');
        expect(defender.name, 'Sir Aldric');
        expect(defender.description, 'A noble knight of the realm');
        expect(defender.imgUrl, 'https://example.com/knight.png');
        expect(defender.type, DefenderType.knight);
        expect(defender.bastionId, 'bastion_1');
      });

      test('parses nullable fields as null when absent', () {
        final defender = Defender.fromJson(testJsonNoOptional);

        expect(defender.id, 'def_2');
        expect(defender.name, null);
        expect(defender.description, null);
        expect(defender.imgUrl, null);
        expect(defender.type, DefenderType.beast);
        expect(defender.bastionId, 'bastion_1');
      });

      test('parses bastionDefender type from "bastion defender"', () {
        final json = {
          'id': 'def_3',
          'type': 'bastion defender',
          'bastionId': 'bastion_2',
        };
        final defender = Defender.fromJson(json);
        expect(defender.type, DefenderType.bastionDefender);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final defender = Defender(
          id: 'def_1',
          name: 'Sir Aldric',
          description: 'A noble knight',
          imgUrl: 'https://example.com/knight.png',
          type: DefenderType.knight,
          bastionId: 'bastion_1',
        );

        final json = defender.toJson();

        expect(json['id'], 'def_1');
        expect(json['name'], 'Sir Aldric');
        expect(json['description'], 'A noble knight');
        expect(json['imgUrl'], 'https://example.com/knight.png');
        expect(json['type'], 'knight');
        expect(json['bastionId'], 'bastion_1');
      });

      test('serializes nullable fields as null', () {
        final defender = Defender(
          id: 'def_2',
          type: DefenderType.beast,
          bastionId: 'bastion_1',
        );

        final json = defender.toJson();

        expect(json['id'], 'def_2');
        expect(json['name'], null);
        expect(json['description'], null);
        expect(json['imgUrl'], null);
        expect(json['type'], 'beast');
        expect(json['bastionId'], 'bastion_1');
      });
    });

    group('constructor', () {
      test('creates defender with all fields', () {
        final defender = Defender(
          id: 'def_1',
          name: 'Sir Aldric',
          description: 'A noble knight',
          imgUrl: 'https://example.com/knight.png',
          type: DefenderType.knight,
          bastionId: 'bastion_1',
        );

        expect(defender.id, 'def_1');
        expect(defender.name, 'Sir Aldric');
        expect(defender.description, 'A noble knight');
        expect(defender.imgUrl, 'https://example.com/knight.png');
        expect(defender.type, DefenderType.knight);
        expect(defender.bastionId, 'bastion_1');
      });

      test('creates defender with only required fields', () {
        final defender = Defender(
          id: 'def_2',
          type: DefenderType.beast,
          bastionId: 'bastion_1',
        );

        expect(defender.id, 'def_2');
        expect(defender.name, null);
        expect(defender.description, null);
        expect(defender.imgUrl, null);
        expect(defender.type, DefenderType.beast);
        expect(defender.bastionId, 'bastion_1');
      });
    });
  });
}
