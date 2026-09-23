// test/features/news_paper/logic/filler_article_generator_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/bastion/facility.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';
import 'package:maura_bastion_system/features/news_paper/logic/filler_article_generator.dart';

Bastion _bastion({
  String name = 'Ashdown Keep',
  List<Hireling> hirelings = const [],
  List<Defender>? defenders,
  List<Facility> facilities = const [],
}) =>
    Bastion(
      id: 'b1',
      name: name,
      description: '',
      facilities: facilities,
      defenders: defenders ??
          [
            Defender(
                id: 'd1',
                name: 'Aldric',
                type: DefenderType.bastionDefender,
                bastionId: 'b1'),
          ],
      hirelings: hirelings,
    );

Hireling _hireling(String name, String? role) => Hireling(
      id: 'h1',
      name: name,
      role: role,
      bastionId: 'b1',
    );

Defender _defender(String name, DefenderType type) => Defender(
      id: name.isEmpty ? 'd-anon' : 'd-$name',
      name: name.isEmpty ? null : name,
      type: type,
      bastionId: 'b1',
    );

Facility _facility(String name, Rank rank,
        {int constructedTurns = 99, int constructionTurns = 99}) =>
    Facility(
      id: 'f-$name',
      name: name,
      rank: rank,
      description: '',
      constructedTurns: constructedTurns,
      constructionTurns: constructionTurns,
    );

void main() {
  const generator = FillerArticleGenerator();

  test('first kind with empty state produces the bastion-name gag', () {
    final article = generator.generate(bastion: _bastion(), pick: (_) => 0);
    expect(article.title, contains('ASHDOWN KEEP'));
    expect(article.title, contains('DRILLING'));
    expect(article.content, isNotEmpty);
    expect(article.author, isNotNull);
  });

  test('last kind with empty state produces the evergreen filler', () {
    final article = generator.generate(bastion: _bastion(), pick: (max) => max - 1);
    expect(article.title, contains('LOST'));
  });

  test('hireling gossip quotes the hireling name', () {
    final bastion = _bastion(hirelings: [_hireling('Gareth', 'Weaponsmith')]);
    // kinds for this bastion: [bastion, hirelingGossip, evergreen] — pick gossip (index 1),
    // template index 0.
    var pickCall = 0;
    final article = generator.generate(
      bastion: bastion,
      pick: (max) => pickCall++ == 0 ? 1 : max - 1,
    );
    expect(article.title, contains('GARETH'));
  });

  test('chart emphasis picks the highest-point chart theme', () {
    // kinds: [bastion, defenderGossip, chartEmphasis, factionGossip,
    // evergreen] — pick chart (index 2), template index 0.
    final article = generator.generate(
      bastion: _bastion(),
      points: {EventChart.warMarch: 5, EventChart.hearth: 1},
      pick: (max) => max >= 4 ? 2 : max - 1,
    );
    expect(article.title, contains('WAR DESK'));
  });

  test('defender gossip quotes the defender name and type', () {
    final bastion = _bastion(
      defenders: [_defender('Aldric', DefenderType.bastionDefender)],
    );
    // kinds: [bastion, defenderGossip, factionGossip, evergreen] — pick
    // defenderGossip (index 1), defender index 0, template index 0.
    var pickCall = 0;
    final article = generator.generate(
      bastion: bastion,
      pick: (max) => pickCall++ == 0 ? 1 : max - 1,
    );
    expect(article.title, contains('ALDRIC'));
    expect(article.content, contains('Bastion Defender'));
  });

  test('unnamed defenders do not enable the defenderGossip kind', () {
    final article = generator.generate(
      bastion: _bastion(defenders: [_defender('', DefenderType.beast)]),
      points: {},
      pick: (max) => max - 1,
    );
    // kinds: [bastion, factionGossip, evergreen] — last kind is evergreen.
    expect(article.title, contains('LOST'));
  });

  test('facility gag uses the facility name and rank', () {
    final bastion = _bastion(
      defenders: const [],
      facilities: [_facility('Smithy', Rank.C)],
    );
    // kinds: [bastion, facilityGag, evergreen] — pick facilityGag (index 1),
    // facility index 0, template index 0.
    var pickCall = 0;
    final article = generator.generate(
      bastion: bastion,
      pick: (max) => pickCall++ == 0 ? 1 : 0,
    );
    expect(article.title, contains('SMITHY'));
    expect(article.content, contains('Rank C'));
  });

  test('under-construction facility gets the construction template', () {
    final bastion = _bastion(
      defenders: const [],
      facilities: [
        _facility('Smithy', Rank.C, constructedTurns: 1, constructionTurns: 3),
      ],
    );
    // kinds: [bastion, facilityGag, evergreen] — pick facilityGag (index 1),
    // facility index 0; construction template is the only choice.
    var pickCall = 0;
    final article = generator.generate(
      bastion: bastion,
      pick: (max) => pickCall++ == 0 ? 1 : 0,
    );
    expect(article.title, contains('CONSTRUCTION'));
  });

  test('same rng seed produces the same article', () {
    final bastion = _bastion(hirelings: [_hireling('Gareth', 'Weaponsmith')]);
    final a = generator.generate(bastion: bastion, rng: Random(42));
    final b = generator.generate(bastion: bastion, rng: Random(42));
    expect(a.title, b.title);
    expect(a.content, b.content);
  });

  test('every template renders non-empty title and content', () {
    final bastion = _bastion(
      hirelings: [_hireling('Gareth', 'Weaponsmith')],
      defenders: [
        _defender('Aldric', DefenderType.bastionDefender),
        _defender('Bram', DefenderType.knight),
        _defender('', DefenderType.beast),
      ],
      facilities: [
        _facility('Smithy', Rank.C),
        _facility('Garden', Rank.E,
            constructedTurns: 0, constructionTurns: 2),
      ],
    );
    for (var seed = 0; seed < 200; seed++) {
      final article = generator.generate(
        bastion: bastion,
        points: {EventChart.wilds: 2},
        rng: Random(seed),
      );
      expect(article.title, isNotEmpty);
      expect(article.content, isNotEmpty);
    }
  });

  test('faction gossip is reachable and renders its first template', () {
    // kinds for this bastion: [bastion, factionGossip, evergreen] — pick
    // factionGossip (index 1), then template 0.
    var pickCall = 0;
    final article = generator.generate(
      bastion: _bastion(defenders: const []),
      pick: (max) => pickCall++ == 0 ? 1 : 0,
    );
    expect(article.title, contains('SKELETOR'));
    expect(article.content, isNotEmpty);
  });

  test('every faction template renders non-empty title and content', () {
    for (var template = 0; template < 4; template++) {
      var pickCall = 0;
      final article = generator.generate(
        bastion: _bastion(defenders: const []),
        pick: (max) => pickCall++ == 0 ? 1 : template,
      );
      expect(article.title, isNotEmpty);
      expect(article.content, isNotEmpty);
    }
  });
}
