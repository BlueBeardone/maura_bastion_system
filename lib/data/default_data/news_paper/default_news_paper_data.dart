import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_data.dart';
import 'package:maura_bastion_system/data/news_paper/news_paper_format.dart';

List<NewspaperData> getDefaultNewspapers() {
  return [
    NewspaperData(
      newspaperName: 'Maura Weekly',
      date: formatDate(DateTime.now()),
      edition: 'Vol. XLII, No. 1 — Special Edition',
      leadArticle: NewspaperArticle(
        title: 'THE QUIET EDITION — No Dispatches from the Frontier This Week',
        content: '''
The Guild of Heralds regrets to inform the good citizens of Maura that no word has arrived from the frontier, the passes, or the high roads this week. Whether the roads are quiet or the couriers are merely slow, none can say — and the Guild does not speculate in print.

In the absence of hard news, the presses of the Postal Press have been put to other uses, and this humble sheet is offered to the town as a reminder that no news, in these times, is widely considered good news.

Readers with credible accounts of events are invited to present themselves at the Guild hall with pen, paper, and witnesses. The ledger of correspondents remains open, and the town of Maura remains, as ever, listening.
          ''',
        author: 'The Editor',
        imageUrl: null,
      ),
      otherArticles: [
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
      ],
    ),
  ];
}
