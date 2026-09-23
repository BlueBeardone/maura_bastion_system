import 'dart:math';

import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_data.dart';
import 'package:maura_bastion_system/data/news_paper/news_paper_format.dart';

const int _articlesPerEdition = 10;

List<NewspaperData> getDefaultNewspapers({Random? rng}) {
  final random = rng ?? Random();
  final pool = List<NewspaperArticle>.of(_articlePool())..shuffle(random);
  final edition = pool.take(_articlesPerEdition).toList();

  return [
    NewspaperData(
      newspaperName: 'Maura Weekly',
      date: formatDate(DateTime.now()),
      edition: 'Vol. XLII, No. ${1 + random.nextInt(52)}',
      leadArticle: edition.first,
      otherArticles: edition.sublist(1),
    ),
  ];
}

List<NewspaperArticle> _articlePool() {
  return [
    NewspaperArticle(
      title: 'THE QUIET EDITION — No Dispatches from the Frontier This Week',
      content: '''
The Guild of Heralds regrets to inform the good citizens of Maura that no word has arrived from the frontier, the passes, or the high roads this week. Whether the roads are quiet or the couriers are merely slow, none can say — and the Guild does not speculate in print.

In the absence of hard news, the presses of the Postal Press have been put to other uses, and this humble sheet is offered to the town as a reminder that no news, in these times, is widely considered good news.

Readers with credible accounts of events are invited to present themselves at the Guild hall with pen, paper, and witnesses. The ledger of correspondents remains open, and the town of Maura remains, as ever, listening.
          ''',
      author: 'The Editor',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'TAVERN PRICES HOLD STEADY FOR THIRD CONSECUTIVE WEEK',
      content: '''
Patrons of The Swaying Keg rejoiced quietly this week as the price of a pint of house ale remained fixed at two coppers for the third week running. The barkeep, when pressed on the matter, shrugged in a manner the town has come to regard as reassuring.

Local opinion holds that steady prices are the surest sign of prosperity this side of the Guild hall. "A fair pint at a fair price," offered one regular, "is worth more than any dispatch from the pass."

The Keg's famous stew, sources confirm, remains both plentiful and unexplained.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'GUILD NOTICE BOARD: ADVENTURERS REMINDED TO SIGN THE LEDGER',
      content: '''
The Adventurers' Guild has posted a courteous reminder that all parties departing the city walls must sign the outbound ledger, and — crucially — sign again upon their return. Several renowned heroes remain, administratively speaking, still abroad from journeys concluded last season.

The Guild clerk assures the public that no punishment attaches to late signatures, though repeated offenders may expect a pointed look at the door.

Contracts, bounties, and the ever-popular rat-catching postings may be viewed at the hall from dawn until dusk, save during the clerk's lunch, which is not to be discussed.
          ''',
      author: 'The Editor',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'WEATHER: EXPECTED TO CONTINUE',
      content: '''
The sky over Maura, our correspondents report, has been observed at considerable length this week and is expected to carry on in much the same fashion. The seers of the weather desk describe conditions as "outdoor" with a strong likelihood of "days."

Citizens are advised to dress according to the weather they find outside, as this remains the most reliable forecasting method known to the Guild.

Long-range predictions suggest that the seasons will continue arriving in their accustomed order, and that winter, as always, is coming but has not yet confirmed a date.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'MARKET ROUNDUP: TURNIPS BOUNTIFUL, RUMORS STEADY',
      content: '''
The farmers' market reports a surfeit of turnips this week, following the discovery that turnips, like all honest vegetables, grow when planted. Prices have responded by remaining sensible, and the turnip sellers remain cheerful in the manner of those whose crop has no enemies.

Elsewhere in the market, the price of rumors held firm, with the week's best trades involving a distant dragon, a retired pirate running a bakery, and the true identity of the Mystery Bard — all purchased, as usual, with no evidence attached.

The Guild of Heralds reminds citizens that rumors, like turnips, should be inspected before being taken home.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'CITY WALLS INSPECTED; CONFIRMED STILL WALLS',
      content: '''
The annual inspection of Maura's city walls concluded this week with the official finding that the walls are, and remain, walls. The inspector describes their condition as "upright, continuous, and reassuringly thick," and has certified them fit to be a city's exterior for another year.

A small ceremony was held at the East Gate, during which the captain of the watch knocked upon the wall, listened carefully, and pronounced the sound "solid."

Residents inside the walls expressed quiet satisfaction with the arrangement. Residents outside the walls could not be reached, as they are, by definition, outside the walls.
          ''',
      author: 'The Editor',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: "SKELETOR'S CREW RAID WELL; WELL IMPROVES",
      content: '''
Skeletor's Crew has issued a statement denying that anything happened at the well, that the well was ever unwell, and that the hamlet's cough was any of their concern. The Guild notes that all three denials arrived before any accusation was made.

The Crew further wishes it known that its workers receive two meal breaks, a fair wage, and a pension of unspecified bones, and that the Guild is invited to sit with that information for a while.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'MYSTERY BARD SIGHTED AT THREE CROSSINGS IN ONE EVENING',
      content: '''
Witnesses at three separate crossings report the same performer, the same set, and the same quiet certainty that the song was about them personally. The Guild of Heralds has declined to investigate, on the grounds that some arithmetic is best left alone.

Anyone able to describe the bard from memory is asked to try, and then to notice that they cannot.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'THE TWINSTERS SEEN ON THE NORTH ROAD; TOWN WARNED, TOWN LISTENS',
      content: '''
The Twinsters were observed walking the north road this week, in step, in the manner the town has learned to read as a warning. The road was empty within the hour and remained empty behind them.

The family sends its regards, which are addressed to everyone, and the watch advises that visibility is optional and currently discouraged.
          ''',
      author: 'The Editor',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'WHISPERS CLOSE \'A DOOR THAT SHOULD NOT HAVE BEEN THERE\'',
      content: '''
The Whispers report that a door which should not have existed has been closed, and that the screaming is "closing noise" and no cause for alarm. They declined further comment, which the Guild has, for the first time on record, accepted.

Residents near the orchard are advised that the seam in the air is gone, and are asked to stop looking for it.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'ARCHIVE ACQUIRES BOOK THAT "EXPLAINS ITSELF"; ARCHIVE UNCONVINCED',
      content: '''
The Grand Archive has accepted delivery of a book which, its cover claims, explains itself. Two archivists have now read it twice and report that it explains "a great many things, none of them the book."

The volume has been shelved in the usual place. It was found there again the following morning, which the Archive records as normal and not at all worth remarking upon.
          ''',
      author: 'The Editor',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'WATCH CAPTAIN RETIRES; CLOCK NOW UNSUPERVISED',
      content: '''
After forty years of glancing at it with suspicion, the captain of the watch has retired, leaving the Guild hall clock entirely unsupervised for the first time since records began. The clock has been observed ticking in a manner staff describe as "emboldened."

No replacement is sought. The Guild has decided to see what the clock does.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'FESTIVAL OF THE SECOND BELL DRAWS RECORD CROWD OF PEOPLE ALREADY THERE',
      content: '''
The Festival of the Second Bell was declared a success this week after a record number of attendees were counted among those who had, in fact, never left. Organizers describe the turnout as "unavoidable."

Music was played, ribbons were hung, and one stall sold out of a single item it had not intended to offer. Planning for next year has begun, earlier than usual, in a locked room.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'SMITH FORGES SWORD; SWORD "RESIGNED TO IT"',
      content: '''
A local smith has completed a long-commissioned sword, which was inspected, balanced, and returned to its sheath with what onlookers describe as a sigh. The smith calls the work "honest," which is the highest praise available in his trade and the lowest in most others.

The sword has not been named. It is understood to prefer it that way.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: "BAKERY'S MYSTERY PIE CONTEST CONCLUDES; WINNER UNKNOWN TO WINNER",
      content: '''
The annual Mystery Pie Contest has concluded with a unanimous verdict and no clear winner. The judges describe the experience as "educational" and have declined to identify which of the pies was, in fact, the pie.

One contestant accepted the ribbon on behalf of a recipe that could not be located. The ribbon is on display at the bakery, where it is watched.
          ''',
      author: 'The Editor',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'LOCAL PHILOSOPHER PROVES STONE EXISTS; STONE DECLINES COMMENT',
      content: '''
A local philosopher has completed a rigorous proof demonstrating that the stone outside his door exists, and has submitted it to the Guild for publication. The Guild has asked whether the stone agreed, and has been told that agreement was not the point.

The stone remains where it was, which the philosopher cites as corroboration. He has been advised to rest.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'NEW PAVING STONES LAID; OLD PAVING STONES "TAKEN INTO CUSTODY"',
      content: '''
The market square has been repaved in a project the Guild describes as "long overdue and now, therefore, on time." The old stones have been removed for their own protection and are being held at an undisclosed location pending an investigation into how they got there.

Pedestrians report the new surface as level, which is the only review paving ever receives.
          ''',
      author: 'The Editor',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'APPRENTICE WIZARD CASTS FIRST LIGHT; ROOM "ADEQUATELY LIT"',
      content: '''
An apprentice of the Arcane Collegium successfully cast his first lasting light this week, illuminating a modest room to the satisfaction of all present. The master awarded him the traditional nod of "acceptable," which the apprentice has described to relatives as "a triumph."

The light has since been moved to a jar, where it will be asked to continue.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'RIVER CONFIRMED TO BE EVERYTHING IT USED TO BE',
      content: '''
Following public concern, the river has been inspected and found to be entirely itself: wet at the edges, flowing in the direction of the sea, and no longer maintaining the strange stillness it kept last month without explanation.

The Guild thanks the river for its cooperation and reminds it that this arrangement is expected to hold through the season.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'GUILD LEVIES MODEST TAX ON NOTHING; REVENUE UNCHANGED',
      content: '''
The Guild has introduced a modest tax on nothing, payable by anyone who has nothing, with the first collection due at the next bell. Citizens who possess nothing are reminded to declare it promptly and in full.

Early returns are unchanged from last year, which the treasury says is exactly as projected and not, in any sense, a disappointment.
          ''',
      author: 'The Editor',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'GUILD HEAD OF INTELLIGENCE CREDITED WITH PERFECT FORECAST RECORD',
      content: '''
The Guild Head of Intelligence has been credited with a perfect forecast record for the eleventh year running, having correctly anticipated every event of note before it occurred. The Guild has described the consistency of this record as "the sort of thing we have learned not to question."

The Head's earlier forecasts are not currently available for review, as the vault in which they were kept has been reorganized for efficiency. The reorganized vault is also very efficient, according to the one clerk permitted to open it.

Requests to interview the Head were met with a thorough and flattering summary of the Head, submitted on the Head's behalf and signed by no one.
          ''',
      author: 'The Editor',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: "INTELLIGENCE CHIEF'S INSPECTION RETURNS ZERO FAULTS FOR NINTH YEAR",
      content: '''
The annual inspection of the Office of Intelligence has returned zero faults for the ninth consecutive year, a result the Guild calls "historically tidy." The written report supporting the finding has been filed in a drawer that was subsequently organized, and it is hoped the two will be reunited in due course.

The Head personally thanked the inspector on the steps of the hall, warmly and at length. The inspector departed the next morning for a long holiday and has asked not to be contacted about work.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'CITIZENS UNANIMOUS IN PRAISE OF GUILD HEAD OF INTELLIGENCE',
      content: '''
Citizens from six unrelated districts have offered praise for the Guild Head of Intelligence using, remarkably, the same words in the same order and the same tone. The Guild regards the unanimity as heartening and has asked no further questions.

One citizen, when thanked for her kind words, reported that she could not recall having been asked for them, but that she meant them anyway. She has since been invited to a reception she also does not recall agreeing to attend.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'FORMER GUILD HEAD OF INTELLIGENCE RETIRES TO FARM "NOT ON ANY MAP"',
      content: '''
The previous Guild Head of Intelligence has retired to a small farm which, by all accounts, is peaceful, prosperous, and not marked on any map maintained by the Guild or by anyone else. He sends his regards to the office and notes that the weather there is "better than can be confirmed."

His predecessor retired similarly, to a place described at the time as "unfindable" and "a great success." The Guild wishes both of them well through the usual channels, which have also proven difficult to locate.
          ''',
      author: 'The Editor',
      imageUrl: null,
    ),
    NewspaperArticle(
      title: 'INTELLIGENCE BUDGET BALANCES ITSELF; AUDITORS "HAPPIEST EVER"',
      content: '''
The Office of Intelligence has submitted a budget that balances to the copper, an outcome the auditors have called the happiest of their careers. Two of the auditors have been reassigned to a pleasant posting and are said to be delighted.

The Head offered to audit the office himself, an offer the Guild accepted with thanks and without further discussion. The books are available for inspection at a time and place to be announced by the office, at its convenience, when ready.
          ''',
      author: 'A Correspondent',
      imageUrl: null,
    ),
  ];
}
