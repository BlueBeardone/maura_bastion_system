import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maura_bastion_system/core/juice/reveal_widgets.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_data.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/newspaper_page.dart';

NewspaperData _paper() => NewspaperData(
      newspaperName: 'The Maura Herald',
      date: 'Hammerfest 3',
      edition: 'Morning Edition',
      leadArticle: NewspaperArticle(
        title: 'Herald Ink',
        content: 'The presses never stop.',
      ),
      otherArticles: [
        NewspaperArticle(title: 'Sideline', content: 'Quiet week out west.'),
      ],
    );

void main() {
  testWidgets('newspaper opens with a staged reveal and settles',
      (tester) async {
    final paper = _paper();
    // The real app mounts NewspaperPage inside a SingleChildScrollView
    // (news_paper.dart); mirror that here so the unrolled broadsheet content
    // isn't height-constrained by the test viewport.
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: NewspaperPage(newspaperData: paper),
      ),
    ));
    await tester.pump();
    expect(find.byType(StampIn), findsWidgets);
    expect(find.byType(FadeSlide), findsWidgets);
    // MainNewsArticle and NewsArticle render titles via title.toUpperCase().
    expect(find.text('HERALD INK'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('SIDELINE'), findsOneWidget);
  });
}
