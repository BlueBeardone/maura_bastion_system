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
    test('facilityRemovedMessage shows torn-down facility and description', () {
      final bastion = Bastion(id: 'b', name: 'Ravencrest', description: 'd', facilities: []);
      const facility = Facility(
        id: 'cat_barracks',
        name: 'Barracks',
        rank: Rank.D,
        description: 'Houses the guard.',
      );

      expect(
        facilityRemovedMessage(bastion, facility),
        '🏚️ **Ravencrest** has torn down **Barracks** (Rank D).\n\n'
        'Houses the guard.',
      );
    });

    test('facilityRemovedMessage omits the description when blank', () {
      final bastion = Bastion(id: 'b', name: 'Ravencrest', description: 'd', facilities: []);
      const facility = Facility(
        id: 'cat_barracks',
        name: 'Barracks',
        rank: Rank.D,
        description: '   ',
      );

      expect(
        facilityRemovedMessage(bastion, facility),
        '🏚️ **Ravencrest** has torn down **Barracks** (Rank D).',
      );
    });
  });

  group('DiscordAnnouncer transport', () {
    test('announceHirelingHired POSTs the built message', () async {
      late http.Request captured;
      final mock = capturingMock((request) => captured = request);
      final announcer = announcerWith(mock);

      final hireling = Hireling(id: 'h', name: 'Marta', bastionId: 'b');
      await announcer.announceHirelingHired(
        hireling,
        bastionName: 'Ravencrest',
        bastionId: 'bastion-1',
      );

      expect(
        captured.url.toString(),
        'http://example.test/maura/v1/discord/hireling-hired',
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['message'], '🧑‍🌾 **Ravencrest** hires **Marta**!');
      expect(body['bastionId'], 'bastion-1');
    });

    test('announceDefenderAcquired POSTs the built message', () async {
      late http.Request captured;
      final mock = capturingMock((request) => captured = request);
      final announcer = announcerWith(mock);

      final defender = Defender(id: 'd', type: DefenderType.beast, bastionId: 'b');
      await announcer.announceDefenderAcquired(
        defender,
        bastionName: 'Ravencrest',
        bastionId: 'bastion-1',
      );

      expect(
        captured.url.toString(),
        'http://example.test/maura/v1/discord/defender-acquired',
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(
        body['message'],
        '🛡️ **Ravencrest** gains a new defender: **Unnamed Defender** (Beast)!',
      );
      expect(body['bastionId'], 'bastion-1');
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
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(
        body['message'],
        '🏗️ **Ravencrest** has started construction on **Kitchen** (Rank D)!\n\n'
            'Cooks food.\n\n'
            'Cost: 600gp • Build time: 2 turns • Required hirelings: 0',
      );
      expect(body['bastionId'], 'b');
    });

    test('announceFacilityRemoved POSTs the built message', () async {
      late http.Request captured;
      final mock = capturingMock((request) => captured = request);
      final announcer = announcerWith(mock);

      final bastion = Bastion(id: 'b', name: 'Ravencrest', description: 'd', facilities: []);
      const facility = Facility(
        id: 'cat_barracks',
        name: 'Barracks',
        rank: Rank.D,
        description: 'Houses the guard.',
      );
      await announcer.announceFacilityRemoved(bastion, facility);

      expect(
        captured.url.toString(),
        'http://example.test/maura/v1/discord/facility-removed',
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(
        body['message'],
        '🏚️ **Ravencrest** has torn down **Barracks** (Rank D).\n\n'
            'Houses the guard.',
      );
      expect(body['bastionId'], 'b');
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
      const facility = Facility(
        id: 'cat_kitchen',
        name: 'Kitchen',
        rank: Rank.D,
        description: 'Cooks food.',
      );

      await expectLater(
        announcer.announceFacilityBuilt(bastion, facility),
        throwsA(isA<ApiException>()),
      );
    });
  });

  Defender defender(String? name, DefenderType type) => Defender(
        id: '',
        name: name,
        type: type,
        bastionId: 'bastion-1',
      );

  group('defendersRecruitedMessage', () {
    test('lists all names under a single header with the shared type', () {
      final message = defendersRecruitedMessage(
        [
          defender('Aldric Vane', DefenderType.knight),
          defender('Bram Oakfist', DefenderType.knight),
        ],
        bastionName: 'Ravencrest',
      );
      expect(
        message,
        '🛡️ **Ravencrest** recruits 2 new defenders (Knight):\n'
        '• **Aldric Vane**\n'
        '• **Bram Oakfist**',
      );
    });

    test('handles mixed types by omitting the type label', () {
      final message = defendersRecruitedMessage(
        [
          defender('Aldric Vane', DefenderType.knight),
          defender('Growler', DefenderType.beast),
        ],
        bastionName: 'Ravencrest',
      );
      expect(message, startsWith('🛡️ **Ravencrest** recruits 2 new defenders:'));
    });

    test('uses a generic name when no bastion name is given', () {
      final message = defendersRecruitedMessage(
        [defender('Aldric Vane', DefenderType.knight)],
      );
      expect(message, startsWith('🛡️ A new bastion recruits 1 new defender (Knight):'));
    });

    test('shows Unnamed Defender for null names', () {
      final message = defendersRecruitedMessage(
        [defender(null, DefenderType.knight)],
        bastionName: 'Ravencrest',
      );
      expect(message, contains('• **Unnamed Defender**'));
    });
  });

  group('announceDefendersRecruited', () {
    test('sends the summary via the defender-acquired transport', () async {
      final sent = <String>[];
      final bastionIds = <String?>[];
      final announcer = DiscordAnnouncer(
        discordApi: DiscordApi(
          client: ApiClient(
            client: MockClient((request) async {
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              sent.add(body['message'] as String);
              bastionIds.add(body['bastionId'] as String?);
              return http.Response(
                jsonEncode({'success': true, 'message': 'ok', 'data': {}}),
                200,
                headers: {'content-type': 'application/json'},
              );
            }),
          ),
        ),
      );
      await announcer.announceDefendersRecruited(
        [defender('Aldric Vane', DefenderType.knight)],
        bastionName: 'Ravencrest',
        bastionId: 'bastion-1',
      );
      expect(sent, hasLength(1));
      expect(sent.single, contains('**Aldric Vane**'));
      expect(bastionIds.single, 'bastion-1');
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
