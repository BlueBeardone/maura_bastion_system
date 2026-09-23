// lib/features/news_paper/logic/filler_article_generator.dart
import 'dart:math';

import 'package:maura_bastion_system/data/enums/defender_type.dart';
import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/bastion/bastion.dart';
import 'package:maura_bastion_system/data/models/events/event_chart.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';

/// Index picker: returns a value in [0, max). Injectable for deterministic
/// tests; `Random`-based wrapper is built in [FillerArticleGenerator.generate].
typedef RandomInt = int Function(int max);

enum _FillerKind {
  bastion,
  hirelingGossip,
  defenderGossip,
  facilityGag,
  chartEmphasis,
  factionGossip,
  evergreen,
}

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
      bastion: bastion,
      points: points,
    );
    switch (kinds[next(kinds.length)]) {
      case _FillerKind.bastion:
        return _bastionGag(bastion, next);
      case _FillerKind.hirelingGossip:
        return _hirelingGossip(bastion, next);
      case _FillerKind.defenderGossip:
        return _defenderGossip(bastion, next);
      case _FillerKind.facilityGag:
        return _facilityGag(bastion, next);
      case _FillerKind.chartEmphasis:
        return _chartEmphasis(bastion, points, next);
      case _FillerKind.factionGossip:
        return _factionGossip(next);
      case _FillerKind.evergreen:
        return _evergreen(next);
    }
  }

  static RandomInt _fromRandom(Random rng) => (max) => rng.nextInt(max);

  /// Kind order is part of the observable contract (tests index into it):
  /// bastion, hirelingGossip, defenderGossip, facilityGag, chartEmphasis,
  /// factionGossip, evergreen.
  static List<_FillerKind> _availableKinds({
    required Bastion bastion,
    required Map<EventChart, int> points,
  }) =>
      [
        _FillerKind.bastion,
        if (bastion.hirelings.isNotEmpty) _FillerKind.hirelingGossip,
        if (bastion.defenders.any((d) => (d.name ?? '').trim().isNotEmpty))
          _FillerKind.defenderGossip,
        if (bastion.facilities.isNotEmpty) _FillerKind.facilityGag,
        if (points.values.any((p) => p > 0)) _FillerKind.chartEmphasis,
        _FillerKind.factionGossip,
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
      (
        title: 'GATE DUTY AT {NAME} FILLED WITHOUT INCIDENT; GUILD SUSPICIOUS',
        content:
            'The gate at {NAME} was staffed on time, every day, all week. '
            'The Guild has asked whether this is sustainable and been told, '
            'disturbingly, yes.\n\n'
            'A contingency plan has been drafted in case the reliability '
            'spreads to other departments.',
      ),
      (
        title: 'SUPPLY ROOM AT {NAME} INVENTORIED; NOTHING MISSING, ONE THING ADDED',
        content:
            'The quarterly inventory of the supply room at {NAME} is '
            'complete. Nothing is missing. One item is unaccounted for in '
            'the other direction, and the Guild does not discuss items that '
            'arrive.\n\n'
            'The ledgers balance, which is what matters, and the crate is '
            'loading itself politely into the margin.',
      ),
      (
        title: 'ROOF OF {NAME} DECLARED "ADEQUATELY SLOPED" BY INSPECTORS',
        content:
            'The roof of {NAME} has passed inspection with the written '
            'verdict "adequately sloped," which inspectors confirm is high '
            'praise when applied to a roof.\n\n'
            'The gutters were also found to be attached, in the correct '
            'places, in what one inspector called "a season of good news."',
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
      (
        title: '{WHO} PAST THE DUTY BOARD TWICE WITHOUT SIGNING; WATCH "NOT ALARMED, YET"',
        content:
            'Witnesses report that {WHO} of {NAME} walked past the duty '
            'board twice this week without signing anything. The watch '
            'stresses that this is not an accusation, merely a count.\n\n'
            '{WHO} has been invited to sign something — anything — to '
            'restore baseline.',
      ),
      (
        title: 'HORSESHOE FOUND ON DOOR OF {WHO}; SOURCES DIVIDED ON LUCK THEORY',
        content:
            'A horseshoe has appeared above the door of {WHO} at {NAME}. '
            'Sources are divided on whether it points up, down, or '
            '"metaphorically." The Guild defers to tradition, then to '
            'whichever argument is louder.\n\n'
            'One week in, the luck remains localised and, so far, '
            'everybody\'s.',
      ),
      (
        title: '{WHO} REQUESTS TRANSFER TO "THE QUIET SHIFT"; NO SUCH SHIFT EXISTS',
        content:
            'A transfer request has been lodged by {WHO} of {NAME} citing '
            '"the quiet shift." Administration confirms no such shift is '
            'scheduled, currently, or conceptually.\n\n'
            'The request has been filed under pending, where the Guild '
            'keeps most of its weather.',
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

  NewspaperArticle _defenderGossip(Bastion bastion, RandomInt next) {
    final named =
        bastion.defenders.where((d) => (d.name ?? '').trim().isNotEmpty).toList();
    final defender = named[next(named.length)];
    final label = defender.name!.trim().toUpperCase();
    final type = defender.type.title;
    const templates = <({String title, String content})>[
      (
        title: '{WHO} VOTED "MOST LIKELY TO STAND STILL" BY ACCLAMATION',
        content:
            'The garrison at {NAME} has concluded its informal end-of-season '
            'awards, and the title of "most likely to stand still" went to '
            '{WHO}, who accepted the honour by not moving. The Guild regards '
            'the vote as binding.\n\n'
            'As a {TYPE}, {WHO} was ineligible for the "most improved" '
            'category, having been described as "already complete."',
      ),
      (
        title: 'ROLL CALL AT {NAME} ATTENDED BY ALL, MOSTLY VOLUNTARILY',
        content:
            'Every defender at {NAME} answered the weekly roll call, an '
            'outcome the clerk has annotated "unprecedented, keep an eye on '
            'it." One attendee required a second summons, which sources '
            'attribute to enthusiasm rather than absence.\n\n'
            'The roll book remains open for one (1) late signature.',
      ),
      (
        title: 'GUILD INSPECTORS CONFIRM {WHO} REMAINS A {TYPE}',
        content:
            'Following routine paperwork, the Guild has confirmed in writing '
            'that {WHO} of {NAME} continues to be a {TYPE}, as registered. '
            'The certificate has been framed by the garrison.\n\n'
            'Inspectors note the matter was never in doubt and the visit '
            'was "administrative," which the garrison interprets as praise.',
      ),
      (
        title: 'SHADOWING DUTY AT {NAME} ASSIGNED TO {WHO}; SHADOW UNAWARE',
        content:
            'Duty rosters at {NAME} have assigned {WHO} to shadow the '
            'watch rounds for a week, on the grounds that {WHO} is a {TYPE} '
            'and therefore "ideally suited to following people around."\n\n'
            'The watch reports no complaints, several helpful notes, and one '
            'incident of being out-walked.',
      ),
    ];
    return _render(
      templates[next(templates.length)],
      bastion.name.toUpperCase(),
      next,
      'A Correspondent',
      who: label,
      type: type,
    );
  }

  NewspaperArticle _facilityGag(Bastion bastion, RandomInt next) {
    final facility = bastion.facilities[next(bastion.facilities.length)];
    final underConstruction =
        facility.constructedTurns < facility.constructionTurns;
    if (underConstruction) {
      const construction = <({String title, String content})>[
        (
          title: 'CONSTRUCTION AT {FACILITY} ON SCHEDULE; WEATHER "UNCONFIRMED"',
          content:
              'Works at {FACILITY} proceed on schedule, weather permitting. '
              'The weather has not, at press time, confirmed anything.\n\n'
              'The site foreman describes progress as "mostly upwards," and '
              'the Guild describes the funding as "mostly ongoing." Visitors '
              'are reminded that hard hats are optional but humility is not.',
        ),
        (
          title: 'SCAFFOLDING AT {FACILITY} DECLARED "STRUCTURALLY OPTIMISTIC"',
          content:
              'The scaffolding around {FACILITY} has passed its weekly '
              'inspection and been described as "structurally optimistic" by '
              'the visiting clerk, who meant it kindly.\n\n'
              'Locals have begun timing their walks past the site to the '
              'hourly cart, a practice the Guild neither endorses nor '
              'discourages.',
        ),
      ];
      return _render(
        construction[next(construction.length)],
        bastion.name.toUpperCase(),
        next,
        'The Editor',
        facility: facility.name.toUpperCase(),
      );
    }
    const templates = <({String title, String content})>[
      (
        title: '{FACILITY} MAINTAINS RANK {RANK}; INSPECTORS "BRIEFLY IMPRESSED"',
        content:
            'The seasonal Guild inspection of {FACILITY} is complete, and the '
            'facility retains its Rank {RANK} standing. Inspectors were '
            '"briefly impressed," which the staff have chosen to frame as a '
            'review.\n\n'
            'The inspection ledger notes zero faults and one compliment, '
            'both records for the site.',
      ),
      (
        title: 'NOISE FROM {FACILITY} DESCRIBED AS "SCHEDULED" BY THE GARRISON',
        content:
            'Residents near {NAME} report unusual noises from {FACILITY}, '
            'which the garrison describes as "scheduled" and the Guild '
            'describes as "audible." Both parties consider the matter '
            'closed.\n\n'
            'The noise is expected to continue, possibly rhythmically.',
      ),
      (
        title: 'VISITING INSPECTOR SPENDS AN HOUR IN {FACILITY}, TAKES NO NOTES',
        content:
            'A visiting inspector spent a full hour inside {FACILITY} this '
            'week and left without writing anything, an outcome the staff '
            'describe as "the best possible review."\n\n'
            'The Guild has logged the visit as "uneventful," which at Rank '
            '{RANK} is considered the whole point.',
      ),
    ];
    return _render(
      templates[next(templates.length)],
      bastion.name.toUpperCase(),
      next,
      'A Correspondent',
      facility: facility.name.toUpperCase(),
      rank: facility.rank.title,
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
    const fallback = <({String title, String content})>[
      (
        title: 'WEATHER: EXPECTED TO CONTINUE',
        content:
            'The sky over Maura has been observed at length this week and is '
            'expected to carry on in much the same fashion. The seers of the '
            'weather desk describe conditions as "outdoor" with a strong '
            'likelihood of "days."',
      ),
    ];
    final templates = top == null ? fallback : _chartTemplates[top]!;
    final template = templates[next(templates.length)];
    return _render(template, bastion.name.toUpperCase(), next, 'The Editor');
  }

  /// One template list per chart; order within each list is part of the
  /// observable contract (tests index into it).
  static const Map<EventChart, List<({String title, String content})>> _chartTemplates = {
    EventChart.warMarch: [
      (
        title: 'ALERT LEVEL AT {NAME} RAISED TO "VIGILANT (DECORATIVE)"',
        content:
            'The alert board at {NAME} has been raised to "vigilant," which '
            'the duty officer clarifies is the decorative tier, "the good '
            'flag, not the other flag."\n\n'
            'Drills continue at the usual volume, which the market has '
            'learned to interpret as Tuesday.',
      ),
      (
        title: 'WAR DESK: NOTHING TO REPORT; PRECAUTIONARY PARADE HELD ANYWAY',
        content:
            'The War Desk confirms that nothing is happening along the frontier, '
            'and that a precautionary parade was held regardless, "to keep the '
            'boots honest." Attendance was strong; morale stronger.\n\n'
            'Readers are advised that banners spotted on the road are almost '
            'certainly laundry.',
      ),
    ],
    EventChart.hearth: [
      (
        title: 'STEW AT {NAME} ENTERS THIRD GENERATION; RECIPE "STANDING ON TRADITION"',
        content:
            'The house stew at {NAME} has reached its third recorded '
            'generation, at which point the cook describes it as "less a '
            'recipe, more a resident."\n\n'
            'The Guild\'s food desk has sampled it, nodded, and declined to '
            'ask the follow-up question.',
      ),
      (
        title: 'TAVERN PRICES HOLD STEADY FOR FOURTH CONSECUTIVE WEEK',
        content:
            'Patrons of The Swaying Keg rejoiced quietly as the price of a pint '
            'of house ale held at two coppers for a fourth consecutive week. The '
            'barkeep shrugged in a manner the town has come to regard as '
            'reassuring.\n\n'
            '"A fair pint at a fair price," offered one regular, "is worth more '
            'than any dispatch from the pass."',
      ),
    ],
    EventChart.wilds: [
      (
        title: 'BERRY SEASON OPENS EARLY; FOREST DESCRIBED AS "SHOWING OFF"',
        content:
            'The berry season has opened ahead of schedule along the palisade '
            'trail, which foragers attribute to luck, weather, or the forest '
            '"showing off again."\n\n'
            'Pickers are reminded of the treaty regarding things in the '
            'treeline that wave first, and of its one-hole exception.',
      ),
      (
        title: 'FORAGERS REPORT THE FOREST "STILL THERE"',
        content:
            'The foraging guilds confirm that the woods beyond the palisade '
            'remain present, green, and up to their usual business. Mushrooms '
            'were described as "co-operating" for a second straight week.\n\n'
            'Hunters are reminded that anything inside the treeline that waves '
            'first is, by treaty, a person.',
      ),
    ],
    EventChart.deeps: [
      (
        title: 'SECOND LANTERN APPROVED FOR THE DEEPS; SHADOWS "CO-OPERATING"',
        content:
            'A second lantern has been approved for descent work beneath '
            '{NAME}, a decision the mining commission calls "generous" and '
            'the shadows call "temporary."\n\n'
            'Output held steady this week. So did the knocking, which the '
            'commission continues to attribute to good work ethic.',
      ),
      (
        title: 'MINE BULLETIN: THE DEPTHS REMAIN DEEP',
        content:
            'The mining commission is pleased to report that the depths beneath '
            'the bastions remain deep, dark, and "very much where we left them." '
            'Ore output held steady; so did the rumours of knocking, which the '
            'commission attributes to good work ethic.\n\n'
            'Miners are reminded that counting is encouraged and naming is not.',
      ),
    ],
    EventChart.tradeRoad: [
      (
        title: 'CARAVAN SCHEDULE PUBLISHED; DRIVERS "CAUTIOUSLY OPTIMISTIC"',
        content:
            'The new caravan schedule has been posted along the Trade Road, '
            'and drivers describe themselves as "cautiously optimistic" — '
            'the official mood of the road since records began.\n\n'
            'Tolls are unchanged. Whistling while hauling is legal again, '
            'in a minor key.',
      ),
      (
        title: 'MARKET REPORT: EVERYTHING COSTS ROUGHLY WHAT IT DID',
        content:
            'The Guild of Factors reports that grain, wool, and nearly '
            'everything else changed in price by an amount within the margin of '
            'hearing. Caravans arrived on schedule, which the drivers themselves '
            'called "unsettling."\n\n'
            'The Trade Desk reminds readers that fair prices are a temporary '
            'condition and should be enjoyed while they last.',
      ),
    ],
    EventChart.arcane: [
      (
        title: 'LOCAL CAT OBSERVED STARING AT EMPTY CORNER; OMEN DESK UNCONCERNED',
        content:
            'A cat of no fixed abode has been observed staring at an empty '
            'corner of the market for a third consecutive afternoon. The '
            'Omen Desk classifies the event as "a cat."\n\n'
            'Citizens who feel watched are invited to check whether the '
            'watching entity has four legs before filing a report.',
      ),
      (
        title: 'OMEN DESK: CLOUD FORMATION "PROBABLY NOTHING"',
        content:
            'The Omen Desk has reviewed this week\'s cloud formations and '
            'classified the lot as "probably nothing," with one exception over '
            'the eastern hills, which was classified as "almost certainly '
            'nothing."\n\n'
            'Citizens who observed the eastern clouds are invited to stop '
            'observing them.',
      ),
    ],
  };

  NewspaperArticle _factionGossip(RandomInt next) {
    const templates = <({String title, String content})>[
      (
        title: "SKELETOR'S CREW DENY WELL INCIDENT; WELL 'IMPROVED'",
        content:
            "Skeletor's Crew has issued a statement denying that anything "
            'happened at the well, that the well was like that already, and '
            "that the hamlet's cough was ever their concern. All three "
            'denials, the Guild notes, arrived before any accusation.\n\n'
            'The Crew further wishes it known that its workers receive two '
            'meal breaks and a pension, and that the Guild should perhaps sit '
            'with that for a while.',
      ),
      (
        title: 'MYSTERY BARD PLAYS THREE CROSSINGS AT ONCE; GUILD "NOT COUNTING"',
        content:
            'Witnesses at three separate crossings report the same performer, '
            'the same set, and the same quiet certainty that the song was '
            'about them personally. The Guild has declined to investigate, on '
            'the grounds that some arithmetic is best left alone.\n\n'
            'Anyone able to describe the bard from memory is asked to try, and '
            'then to notice that they cannot.',
      ),
      (
        title: 'TWINSTERS SEEN WALKING NORTH ROAD IN STEP; ROAD "CO-OPERATING" BY LEAVING',
        content:
            'The Twinsters were observed walking the north road this week, in '
            'step, in the manner the town has learned to read as a warning. '
            'The road was empty within the hour and remained so behind them.\n\n'
            'The family sends its regards. The regards are addressed to '
            'everyone.',
      ),
      (
        title: 'WHISPERS CLOSE "DOOR THAT SHOULD NOT HAVE BEEN THERE"; DOOR DISAGREES',
        content:
            'The Whispers report that a door which should not have existed has '
            'been closed, and that the screaming is "closing noise" and no '
            'cause for alarm. They declined further comment, which the Guild '
            'has, for the first time, accepted.\n\n'
            'Residents near the orchard are advised that the seam in the air '
            'is gone, and that they should stop looking for it.',
      ),
    ];
    return _render(
      templates[next(templates.length)],
      'MAURA',
      next,
      'A Correspondent',
    );
  }

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
        title: 'AUCTION RESULTS: ONE (1) CHAIR, BOUGHT BY ITS FORMER OWNER',
        content:
            'The Guild auction closed this week with the sale of one chair '
            'to its former owner, who bid with what onlookers describe as '
            '"the calm of a man reclaiming a country."\n\n'
            'The auctioneer has declared the result valid and the chair '
            'comfortable, in that order.',
      ),
      (
        title: 'GUILD CALENDAR CORRECTION: TUESDAY WILL OCCUR AS SCHEDULED',
        content:
            'The Guild wishes to correct Wednesday\'s notice: Tuesday will '
            'occur as scheduled, and will not be moved to accommodate the '
            'festival, the fair, or the fishmongers.\n\n'
            'The fishmongers have withdrawn their request, calling the '
            'matter "resolved by the tide."',
      ),
      (
        title: 'LETTERS TO THE EDITOR: NONE RECEIVED; EDITOR PLEASED',
        content:
            'No letters arrived at the editorial desk this week, an outcome '
            'the editor describes as "peace, achieved through print."\n\n'
            'Readers who wish to disagree are reminded that the desk closes '
            'at the second bell and, informally, at the first.',
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
    String? type,
    String? facility,
    String? rank,
  }) {
    String apply(String text) => text
        .replaceAll('{NAME}', bastionName)
        .replaceAll('{WHO}', who ?? bastionName)
        .replaceAll('{TYPE}', type ?? 'citizen')
        .replaceAll('{FACILITY}', facility ?? bastionName)
        .replaceAll('{RANK}', rank ?? 'A');
    return NewspaperArticle(
      title: apply(template.title),
      content: apply(template.content),
      imageUrl: null,
      author: author,
    );
  }
}
