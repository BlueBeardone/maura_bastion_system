// test/features/news_paper/logic/filler_article_generator_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/npcs/defender.dart';
import 'package:maura_bastion_system/data/models/npcs/hireling.dart';
import 'package:maura_bastion_system/features/news_paper/logic/filler_article_generator.dart';

Bastion _bastion({
  String name = 'Ashdown Keep',
  List<Hireling> hirelings = const [],
}) =>
    Bastion(
      id: 'b1',
      name: name,
      description: '',
      facilities: const [],
      defenders: [
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
    // kinds: [bastion, chartEmphasis, evergreen] — pick chart (index 1),
    // template index 0.
    final article = generator.generate(
      bastion: _bastion(),
      points: {EventChart.warMarch: 5, EventChart.hearth: 1},
      pick: (max) => max >= 3 ? 1 : max - 1,
    );
    expect(article.title, contains('WAR DESK'));
  });

  test('same rng seed produces the same article', () {
    final bastion = _bastion(hirelings: [_hireling('Gareth', 'Weaponsmith')]);
    final a = generator.generate(bastion: bastion, rng: Random(42));
    final b = generator.generate(bastion: bastion, rng: Random(42));
    expect(a.title, b.title);
    expect(a.content, b.content);
  });

  test('every template renders non-empty title and content', () {
    final bastion = _bastion(hirelings: [_hireling('Gareth', 'Weaponsmith')]);
    for (var seed = 0; seed < 100; seed++) {
      final article =
          generator.generate(bastion: bastion, points: {EventChart.wilds: 2}, rng: Random(seed));
      expect(article.title, isNotEmpty);
      expect(article.content, isNotEmpty);
    }
  });
}
