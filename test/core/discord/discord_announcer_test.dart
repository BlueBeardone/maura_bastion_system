import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maura_bastion_system/api/api_client.dart';
import 'package:maura_bastion_system/api/api_exception.dart';
import 'package:maura_bastion_system/api/discord_api.dart';
import 'package:maura_bastion_system/core/discord/discord_announcer.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/branch_upgrade.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';

DiscordAnnouncer announcerWith(MockClient mock) => DiscordAnnouncer(
      discordApi: DiscordApi(
        client: ApiClient(baseUrl: 'http://example.test', client: mock),
      ),
    );

MockClient capturingMock(void Function(http.Request) onCapture) =>
    MockClient((request) async {
      onCapture(request);
      return http.Response(
        jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

void main() {
  group('message builders', () {
    test('bastionCreatedMessage includes description and facilities', () {
      final bastion = Bastion(
        id: 'bastion-1',
        name: 'Ravencrest',
        description: 'A keep on the hill.',
        facilities: [
          Facility(
            id: 'cat_kitchen',
            name: 'Kitchen',
            rank: Rank.D,
            description: 'Cooks food.',
            constructionTurns: 2,
            cost: 600,
          ),
          Facility(id: 'cat_well_room', name: 'Well Room', rank: Rank.D, description: 'Water.'),
        ],
      );

      final message = bastionCreatedMessage(bastion);

      expect(
        message,
        '🏰 **Ravencrest** has been founded!\n\n'
        'A keep on the hill.\n\n'
        '**Starting facilities** (2):\n'
        '• **Kitchen** (Rank D) — 600gp, 2 turns to build\n'
        '• **Well Room** (Rank D) — 0gp, 0 turns to build',
      );
    });

    test('bastionCreatedMessage omits null description and empty facilities', () {
      final bastion = Bastion(
        id: 'bastion-1',
        name: 'Ravencrest',
        description: '   ',
        facilities: [],
      );

      expect(bastionCreatedMessage(bastion), '🏰 **Ravencrest** has been founded!');
    });

    test('bastionCreatedMessage appends the image url when set', () {
      final bastion = Bastion(
        id: 'bastion-1',
        name: 'Ravencrest',
        description: 'A keep.',
        imgUrl: 'https://example.test/ravencrest.png',
        facilities: [],
      );

      expect(
        bastionCreatedMessage(bastion),
        '🏰 **Ravencrest** has been founded!\n\n'
        'A keep.\n\n'
        'https://example.test/ravencrest.png',
      );
    });

    test('facilityBuiltMessage includes description, cost, build time, hirelings', () {
      final bastion = Bastion(id: 'b', name: 'Ravencrest', description: 'd', facilities: []);
      const facility = Facility(
        id: 'cat_kitchen',
        name: 'Kitchen',
        rank: Rank.D,
        description: 'Cooks food.',
        minimumRequiredHirelings: 1,
        constructionTurns: 2,
        cost: 600,
        imgUrl: 'https://example.test/kitchen.png',
      );

      expect(
        facilityBuiltMessage(bastion, facility),
        '🏗️ **Ravencrest** has started construction on **Kitchen** (Rank D)!\n\n'
        'Cooks food.\n\n'
        'Cost: 600gp • Build time: 2 turns • Required hirelings: 1\n'
        'https://example.test/kitchen.png',
      );
    });

    test('facilityRankUpMessage shows old and new rank plus upgrade cost', () {
      final bastion = Bastion(id: 'b', name: 'Ravencrest', description: 'd', facilities: []);
      const old = Facility(
        id: 'cat_barracks',
        name: 'Barracks',
        rank: Rank.D,
        description: 'Houses the guard.',
      );
      // upgradeFacility produces: next rank, constructionTurns 2, base cost of new rank.
      const upgraded = Facility(
        id: 'cat_barracks',
        name: 'Barracks',
        rank: Rank.C,
        description: 'Houses the guard.',
        constructionTurns: 2,
        cost: 1500,
      );

      expect(
        facilityRankUpMessage(bastion, old, upgraded),
        '⬆️ **Ravencrest**\'s **Barracks** is advancing from Rank D to Rank C!\n\n'
        'Houses the guard.\n\n'
        'Upgrade cost: 900gp • Construction: 2 turns',
      );
    });

    test('branchUpgradePurchasedMessage includes kind, cost and capacity', () {
      final bastion = Bastion(id: 'b', name: 'Ravencrest', description: 'd', facilities: []);
      const kitchen = Facility(id: 'cat_kitchen', name: 'Kitchen', rank: Rank.D, description: 'd');
      const upgrade = BranchUpgrade(
        id: 'bru_industrial_kitchen',
        facilityId: 'cat_kitchen',
        name: 'Industrial Kitchen',
        cost: 500,
        description: 'The kitchen can hold 3 hirelings.',
        kind: BranchUpgradeKind.oneTime,
        hirelingCapacity: 3,
      );

      expect(
        branchUpgradePurchasedMessage(bastion, kitchen, upgrade),
        '🌟 **Ravencrest**\'s **Kitchen** activates **Industrial Kitchen**!\n\n'
        'The kitchen can hold 3 hirelings.\n\n'
        'One-time purchase • Cost: 500gp • Hireling capacity: 3',
      );
    });

    test('branchUpgradePurchasedMessage omits capacity when null and shows per-turn kind', () {
      final bastion = Bastion(id: 'b', name: 'Ravencrest', description: 'd', facilities: []);
      const upgrade = BranchUpgrade(
        id: 'bru_vault_of_knowledge',
        facilityId: 'cat_library',
        name: 'Vault of Knowledge',
        cost: 1000,
        description: 'Pay to gain information.',
        kind: BranchUpgradeKind.perTurn,
      );

      expect(
        branchUpgradePurchasedMessage(bastion, library(), upgrade),
        '🌟 **Ravencrest**\'s **Library** activates **Vault of Knowledge**!\n\n'
        'Pay to gain information.\n\n'
        'Per-turn cost • Cost: 1000gp',
      );
    });

    test('hirelingHiredMessage includes role, description, story and image', () {
      final hireling = Hireling(
        id: 'h1',
        name: 'Marta',
        role: 'Cook',
        description: 'Keeps the pots boiling.',
        imgUrl: 'https://example.test/marta.png',
        bastionId: 'b',
        acquisitionStory: 'Bought free from the docks.',
      );

      expect(
        hirelingHiredMessage(hireling, bastionName: 'Ravencrest'),
        '🧑‍🌾 **Ravencrest** hires **Marta** as Cook!\n\n'
        'Keeps the pots boiling.\n\n'
        'How they were found: Bought free from the docks.\n\n'
        'https://example.test/marta.png',
      );
    });

    test('hirelingHiredMessage omits role/description/story/url when null', () {
      final hireling = Hireling(id: 'h', name: 'Marta', bastionId: 'b');

      expect(
        hirelingHiredMessage(hireling, bastionName: 'Ravencrest'),
        '🧑‍🌾 **Ravencrest** hires **Marta**!',
      );
    });

    test('hirelingHiredMessage falls back when bastionName is null', () {
      final hireling = Hireling(id: 'h', name: 'Marta', bastionId: 'b');

      expect(
        hirelingHiredMessage(hireling),
        '🧑‍🌾 A new bastion hires **Marta**!',
      );
    });

    test('defenderAcquiredMessage includes type, description, story and url', () {
      final defender = Defender(
        id: 'd',
        name: 'Sergeant Aldric',
        description: 'A stern veteran.',
        imgUrl: 'https://example.test/aldric.png',
        type: DefenderType.knight,
        bastionId: 'b',
        acquisitionStory: 'Won in a duel.',
      );

      expect(
        defenderAcquiredMessage(defender, bastionName: 'Ravencrest'),
        '🛡️ **Ravencrest** gains a new defender: **Sergeant Aldric** (Knight)!\n\n'
        'A stern veteran.\n\n'
        'How they were gained: Won in a duel.\n\n'
        'https://example.test/aldric.png',
      );
    });

    test('defenderAcquiredMessage handles null name and missing fields', () {
      final defender = Defender(id: 'd', type: DefenderType.beast, bastionId: 'b');

      expect(
        defenderAcquiredMessage(defender, bastionName: 'Ravencrest'),
        '🛡️ **Ravencrest** gains a new defender: **Unnamed Defender** (Beast)!',
      );
    });
  });

  group('DiscordAnnouncer transport', () {
    test('announceBastionCreated POSTs the built message to /maura/v1/discord/bastion-creation', () async {
      late http.Request captured;
      final mock = capturingMock((request) => captured = request);
      final announcer = announcerWith(mock);

      final bastion = Bastion(
        id: 'bastion-1',
        name: 'Ravencrest',
        description: 'A keep on the hill.',
        facilities: [],
      );
      await announcer.announceBastionCreated(bastion);

      expect(captured.method, 'POST');
      expect(
        captured.url.toString(),
        'http://example.test/maura/v1/discord/bastion-creation',
      );
      expect(
        captured.body,
        jsonEncode({
          'message': '🏰 **Ravencrest** has been founded!\n\nA keep on the hill.',
        }),
      );
    });

    test('announceHirelingHired POSTs the built message', () async {
      late http.Request captured;
      final mock = capturingMock((request) => captured = request);
      final announcer = announcerWith(mock);

      final hireling = Hireling(id: 'h', name: 'Marta', bastionId: 'b');
      await announcer.announceHirelingHired(hireling, bastionName: 'Ravencrest');

      expect(
        captured.url.toString(),
        'http://example.test/maura/v1/discord/hireling-hired',
      );
      expect(
        captured.body,
        jsonEncode({'message': '🧑‍🌾 **Ravencrest** hires **Marta**!'}),
      );
    });

    test('announceDefenderAcquired POSTs the built message', () async {
      late http.Request captured;
      final mock = capturingMock((request) => captured = request);
      final announcer = announcerWith(mock);

      final defender = Defender(id: 'd', type: DefenderType.beast, bastionId: 'b');
      await announcer.announceDefenderAcquired(defender, bastionName: 'Ravencrest');

      expect(
        captured.url.toString(),
        'http://example.test/maura/v1/discord/defender-acquired',
      );
      expect(
        captured.body,
        jsonEncode({
          'message': '🛡️ **Ravencrest** gains a new defender: **Unnamed Defender** (Beast)!',
        }),
      );
    });

    test('announceFacilityBuilt POSTs the built message', () async {
      late http.Request captured;
      final mock = capturingMock((request) => captured = request);
      final announcer = announcerWith(mock);

      final bastion = Bastion(id: 'b', name: 'Ravencrest', description: 'd', facilities: []);
      const facility = Facility(
        id: 'cat_kitchen',
        name: 'Kitchen',
        rank: Rank.D,
        description: 'Cooks food.',
        constructionTurns: 2,
        cost: 600,
      );
      await announcer.announceFacilityBuilt(bastion, facility);

      expect(
        captured.url.toString(),
        'http://example.test/maura/v1/discord/facility-built',
      );
      expect(
        captured.body,
        jsonEncode({
          'message':
              '🏗️ **Ravencrest** has started construction on **Kitchen** (Rank D)!\n\n'
                  'Cooks food.\n\n'
                  'Cost: 600gp • Build time: 2 turns • Required hirelings: 0',
        }),
      );
    });

    test('propagates ApiException so callers can gate actions on it', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'webhook unreachable'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });
      final announcer = announcerWith(mock);

      final bastion = Bastion(id: 'b', name: 'Ravencrest', description: 'd', facilities: []);

      await expectLater(
        announcer.announceBastionCreated(bastion),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

// Helper fixtures used by the branch-upgrade builder tests.
Facility kitchen() => const Facility(
      id: 'cat_kitchen',
      name: 'Kitchen',
      rank: Rank.D,
      description: 'Cooks food.',
    );

Facility library() => const Facility(
      id: 'cat_library',
      name: 'Library',
      rank: Rank.C,
      description: 'Books.',
    );
