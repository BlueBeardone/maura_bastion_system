// lib/features/news_paper/logic/filler_article_generator.dart
import 'dart:math';

import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';

/// Index picker: returns a value in [0, max). Injectable for deterministic
/// tests; `Random`-based wrapper is built in [FillerArticleGenerator.generate].
typedef RandomInt = int Function(int max);

enum _FillerKind { bastion, hirelingGossip, chartEmphasis, evergreen }

class FillerArticleGenerator {
  const FillerArticleGenerator();

  NewspaperArticle generate({
    required Bastion bastion,
    Map<EventChart, int> points = const {},
    Random? rng,
    RandomInt? pick,
  }) {
    final next = pick ?? _fromRandom(rng ?? Random());
    final kinds = _availableKinds(
      hirelingCount: bastion.hirelings.length,
      points: points,
    );
    switch (kinds[next(kinds.length)]) {
      case _FillerKind.bastion:
        return _bastionGag(bastion, next);
      case _FillerKind.hirelingGossip:
        return _hirelingGossip(bastion, next);
      case _FillerKind.chartEmphasis:
        return _chartEmphasis(bastion, points, next);
      case _FillerKind.evergreen:
        return _evergreen(next);
    }
  }

  static RandomInt _fromRandom(Random rng) => (max) => rng.nextInt(max);

  /// Kind order is part of the observable contract (tests index into it):
  /// bastion, hirelingGossip, chartEmphasis, evergreen.
  static List<_FillerKind> _availableKinds({
    required int hirelingCount,
    required Map<EventChart, int> points,
  }) =>
      [
        _FillerKind.bastion,
        if (hirelingCount > 0) _FillerKind.hirelingGossip,
        if (points.values.any((p) => p > 0)) _FillerKind.chartEmphasis,
        _FillerKind.evergreen,
      ];

  NewspaperArticle _bastionGag(Bastion bastion, RandomInt next) {
    final name = bastion.name.toUpperCase();
    const templates = <({String title, String content})>[
      (
        title: 'DRILLING AT {NAME} ONCE AGAIN AUDIBLE FROM THE MARKET',
        content:
            'Residents of the market district report that the morning drill at '
            '{NAME} has resumed its full volume, and that the north wall is now '
            'audible before it is visible. The garrison describes the practice '
            'schedule as "aggressive but defensible."\n\n'
            'The Guild of Heralds reminds citizens that the beating of swords '
            'into ploughshares is a seasonal activity and not a substitute for '
            'maintenance.',
      ),
      (
        title: 'THE WALLS OF {NAME} INSPECTED, FOUND TO BE WALLS',
        content:
            'A routine Guild inspection of the fortifications at {NAME} has '
            'confirmed that the walls remain vertical, load-bearing, and '
            '"competently moist" following recent weather. No faults were '
            'recorded.\n\n'
            'The inspection report notes, however, that the gate hinges squeak '
            'in a manner described as "theatrical," and that the garrison has '
            'elected to preserve this.',
      ),
      (
        title: 'QUIET WEEK AT {NAME}; CITIZENS NOTIFIED ANYWAY',
        content:
            'The Guild has confirmed that nothing happened at {NAME} this week, '
            'and has printed this notice so that the nothing is on the record. '
            'Sources close to the battlements describe the week as "structurally '
            'uneventful."\n\n'
            'Residents who feel they witnessed something are invited to submit '
            'a signed statement, two witness affidavits, and a plausible reason '
            'they were awake at that hour.',
      ),
    ];
    return _render(templates[next(templates.length)], name, next, 'A Correspondent');
  }

  NewspaperArticle _hirelingGossip(Bastion bastion, RandomInt next) {
    final hireling = bastion.hirelings[next(bastion.hirelings.length)];
    final role = hireling.role?.trim();
    final label =
        role == null || role.isEmpty ? hireling.name : '${hireling.name} ($role)';
    const templates = <({String title, String content})>[
      (
        title: '"{WHO} SEEMED DIFFERENT ON TUESDAY," SOURCES SAY',
        content:
            'Several reliable sources report that {WHO} of {NAME} appeared '
            '"noticeably different" last Tuesday, in a manner nobody can fully '
            'describe. The Guild has opened a file on the matter and closed it '
            'again for tidiness.\n\n'
            '{WHO} declined to comment, which sources agree is itself '
            'consistent with the alleged difference.',
      ),
      (
        title: 'KITCHEN STAFF AT {NAME} DENY SOUP-RELATED RUMOURS',
        content:
            'Staff at {NAME} have issued a brief statement denying recent '
            'rumours concerning the soup, the recipe, and the question of what '
            'exactly was in it. {WHO} was not named in the statement, which '
            'observers note is how the good ones stay out of print.\n\n'
            'The stew, sources confirm, remains both plentiful and unexplained.',
      ),
      (
        title: 'SLEEPING SCHEDULE OF {WHO} DESCRIBED AS "SUSPICIOUSLY REGULAR"',
        content:
            'Colleagues of {WHO} at {NAME} have raised concerns, in the '
            'friendliest possible terms, about a sleeping schedule described as '
            '"suspiciously regular." The Guild regrets to inform all parties '
            'that there is no regulation against restfulness.\n\n'
            'A watch has nevertheless been established, on the grounds that '
            'nobody that well-rested is up to nothing.',
      ),
    ];
    return _render(
      templates[next(templates.length)],
      bastion.name.toUpperCase(),
      next,
      'A Correspondent',
      who: label.toUpperCase(),
    );
  }

  NewspaperArticle _chartEmphasis(Bastion bastion, Map<EventChart, int> points, RandomInt next) {
    EventChart? top;
    var best = 0;
    for (final chart in EventChart.values) {
      final p = points[chart] ?? 0;
      if (p > best) {
        best = p;
        top = chart;
      }
    }
    const fallback = (
      title: 'WEATHER: EXPECTED TO CONTINUE',
      content:
          'The sky over Maura has been observed at length this week and is '
          'expected to carry on in much the same fashion. The seers of the '
          'weather desk describe conditions as "outdoor" with a strong '
          'likelihood of "days."',
    );
    final template = top == null ? fallback : _chartTemplates[top]!;
    return _render(template, bastion.name.toUpperCase(), next, 'The Editor');
  }

  static const Map<EventChart, ({String title, String content})> _chartTemplates = {
    EventChart.warMarch: (
      title: 'WAR DESK: NOTHING TO REPORT; PRECAUTIONARY PARADE HELD ANYWAY',
      content:
          'The War Desk confirms that nothing is happening along the frontier, '
          'and that a precautionary parade was held regardless, "to keep the '
          'boots honest." Attendance was strong; morale stronger.\n\n'
          'Readers are advised that banners spotted on the road are almost '
          'certainly laundry.',
    ),
    EventChart.hearth: (
      title: 'TAVERN PRICES HOLD STEADY FOR FOURTH CONSECUTIVE WEEK',
      content:
          'Patrons of The Swaying Keg rejoiced quietly as the price of a pint '
          'of house ale held at two coppers for a fourth consecutive week. The '
          'barkeep shrugged in a manner the town has come to regard as '
          'reassuring.\n\n'
          '"A fair pint at a fair price," offered one regular, "is worth more '
          'than any dispatch from the pass."',
    ),
    EventChart.wilds: (
      title: 'FORAGERS REPORT THE FOREST "STILL THERE"',
      content:
          'The foraging guilds confirm that the woods beyond the palisade '
          'remain present, green, and up to their usual business. Mushrooms '
          'were described as "co-operating" for a second straight week.\n\n'
          'Hunters are reminded that anything inside the treeline that waves '
          'first is, by treaty, a person.',
    ),
    EventChart.deeps: (
      title: 'MINE BULLETIN: THE DEPTHS REMAIN DEEP',
      content:
          'The mining commission is pleased to report that the depths beneath '
          'the bastions remain deep, dark, and "very much where we left them." '
          'Ore output held steady; so did the rumours of knocking, which the '
          'commission attributes to good work ethic.\n\n'
          'Miners are reminded that counting is encouraged and naming is not.',
    ),
    EventChart.tradeRoad: (
      title: 'MARKET REPORT: EVERYTHING COSTS ROUGHLY WHAT IT DID',
      content:
          'The Guild of Factors reports that grain, wool, and nearly '
          'everything else changed in price by an amount within the margin of '
          'hearing. Caravans arrived on schedule, which the drivers themselves '
          'called "unsettling."\n\n'
          'The Trade Desk reminds readers that fair prices are a temporary '
          'condition and should be enjoyed while they last.',
    ),
    EventChart.arcane: (
      title: 'OMEN DESK: CLOUD FORMATION "PROBABLY NOTHING"',
      content:
          'The Omen Desk has reviewed this week\'s cloud formations and '
          'classified the lot as "probably nothing," with one exception over '
          'the eastern hills, which was classified as "almost certainly '
          'nothing."\n\n'
          'Citizens who observed the eastern clouds are invited to stop '
          'observing them.',
    ),
  };

  NewspaperArticle _evergreen(RandomInt next) {
    const templates = <({String title, String content})>[
      (
        title: 'WEATHER: EXPECTED TO CONTINUE',
        content:
            'The sky over Maura has been observed at considerable length this '
            'week and is expected to carry on in much the same fashion. The '
            'seers of the weather desk describe conditions as "outdoor" with a '
            'strong likelihood of "days."\n\n'
            'Citizens are advised to dress according to the weather they find '
            'outside, as this remains the most reliable forecasting method '
            'known to the Guild.',
      ),
      (
        title: 'GUILD NOTICE BOARD: SIGN THE LEDGER, BOTH DIRECTIONS',
        content:
            'A courteous reminder that all parties leaving the city walls must '
            'sign the outbound ledger, and — crucially — sign again upon '
            'return. Several renowned heroes remain, administratively speaking, '
            'still abroad from journeys concluded last season.\n\n'
            'The clerk assures the public that no punishment attaches to late '
            'signatures, though repeated offenders may expect a pointed look '
            'at the door.',
      ),
      (
        title: 'LOST: ONE (1) LOAF OF BREAD, ANSWERS TO "LUNCH"',
        content:
            'A loaf of bread has gone missing from the commons at the Guild '
            'hall between the second bell and the second bell, slightly. It is '
            'described as brown, roughly loaf-shaped, and missed.\n\n'
            'The Guild wishes it to be known that no accusation is being made, '
            'merely an inventory, and that whoever returned it by Friday would '
            'find the matter closed and the archive unusually forgiving.',
      ),
    ];
    return _render(templates[next(templates.length)], 'MAURA', next, 'A Correspondent');
  }

  NewspaperArticle _render(
    ({String title, String content}) template,
    String bastionName,
    RandomInt next,
    String author, {
    String? who,
  }) {
    return NewspaperArticle(
      title: template.title
          .replaceAll('{NAME}', bastionName)
          .replaceAll('{WHO}', who ?? bastionName),
      content: template.content
          .replaceAll('{NAME}', bastionName)
          .replaceAll('{WHO}', who ?? bastionName),
      imageUrl: null,
      author: author,
    );
  }
}
