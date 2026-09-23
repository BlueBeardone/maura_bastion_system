// test/data/default_data/news_paper/default_news_paper_data_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/data/default_data/news_paper/default_news_paper_data.dart';

void main() {
  test('builds one edition with a lead and nine secondary articles', () {
    final papers = getDefaultNewspapers(rng: Random(1));

    expect(papers.length, 1);
    final paper = papers.first;
    expect(paper.newspaperName, 'Maura Weekly');
    expect(paper.date, isNotEmpty);
    expect(paper.leadArticle.title, isNotEmpty);
    expect(paper.leadArticle.imageUrl, isNull);
    expect(paper.otherArticles.length, 9);
    for (final article in paper.otherArticles) {
      expect(article.title, isNotEmpty);
      expect(article.content, isNotEmpty);
    }
  });

  test('different seeds produce different editions', () {
    final first = getDefaultNewspapers(rng: Random(1)).first;
    final second = getDefaultNewspapers(rng: Random(2)).first;

    final firstTitles = {
      first.leadArticle.title,
      ...first.otherArticles.map((a) => a.title),
    };
    final secondTitles = {
      second.leadArticle.title,
      ...second.otherArticles.map((a) => a.title),
    };

    expect(firstTitles, isNot(equals(secondTitles)));
  });

  test('an edition never repeats an article', () {
    final paper = getDefaultNewspapers(rng: Random(7)).first;

    final titles = [
      paper.leadArticle.title,
      ...paper.otherArticles.map((a) => a.title),
    ];

    expect(titles.toSet().length, titles.length);
  });

  test('editions always include exactly ten distinct articles', () {
    for (var seed = 0; seed < 20; seed++) {
      final paper = getDefaultNewspapers(rng: Random(seed)).first;
      final count = 1 + paper.otherArticles.length;
      expect(count, 10);
    }
  });
}
