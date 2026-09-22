import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/juice/juice.dart';
import 'package:maura_bastion_system/core/juice/juice_sfx.dart';
import 'package:maura_bastion_system/core/juice/reveal_widgets.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_data.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/articles/main_news_article.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/articles/news_article.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/articles/news_paper_title.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/ornamental_divider.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class NewspaperPage extends StatefulWidget {
  final NewspaperData newspaperData;

  const NewspaperPage({super.key, required this.newspaperData});

  @override
  State<NewspaperPage> createState() => _NewspaperPageState();
}

class _NewspaperPageState extends State<NewspaperPage> {
  int _replaySeed = 0;

  @override
  void initState() {
    super.initState();
    Juice.sfx(SfxClip.pageTurn);
  }

  @override
  void didUpdateWidget(covariant NewspaperPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.newspaperData.date != widget.newspaperData.date) {
      setState(() => _replaySeed++);
      Juice.sfx(SfxClip.pageTurn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('reveal_${widget.newspaperData.date}_$_replaySeed'),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            MedievalColors.parchmentLight,
            MedievalColors.parchmentDark,
          ],
          stops: const [0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: CustomPaint(
        painter: ParchmentBorderPainter(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              StampIn(
                child: NewsPaperTitle(newspaperData: widget.newspaperData),
              ),
              const SizedBox(height: 12),
              FadeSlide(
                delay: const Duration(milliseconds: 150),
                child:
                    MainNewsArticle(article: widget.newspaperData.leadArticle),
              ),
              const SizedBox(height: 16),
              _buildSecondaryArticles(
                widget.newspaperData.otherArticles,
                widget.newspaperData.date,
              ),
              const SizedBox(height: 16),
              FadeSlide(
                delay: const Duration(milliseconds: 600),
                child: OrnamentalDivider(),
              ),
              const SizedBox(height: 10),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryArticles(
      List<NewspaperArticle> articles, String date) {
    if (articles.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        int columns;
        if (availableWidth > 700) {
          columns = 3;
        } else if (availableWidth > 450) {
          columns = 2;
        } else {
          columns = 1;
        }

        if (columns == 1) {
          return Column(
            children: articles.indexed.map((indexed) {
              final (i, a) = indexed;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FadeSlide(
                  delay: Duration(milliseconds: 250 + 100 * i),
                  child: NewsArticle(article: a, date: date),
                ),
              );
            }).toList(),
          );
        }

        final rows = <List<NewspaperArticle>>[];
        for (int i = 0; i < articles.length; i += columns) {
          rows.add(articles.skip(i).take(columns).toList());
        }

        var articleIndex = 0;
        return Column(
          children: rows.map((row) {
            final rowStart = articleIndex;
            articleIndex += row.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < row.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                            width: 1,
                            color: MedievalColors.goldPale.withAlpha(80),
                          ),
                        ),
                      Expanded(
                        child: FadeSlide(
                          delay:
                              Duration(milliseconds: 250 + 100 * (rowStart + i)),
                          child: NewsArticle(
                            article: row[i],
                            date: date,
                          ),
                        ),
                      ),
                    ],
                    for (int i = row.length; i < columns; i++)
                      Expanded(child: const SizedBox.shrink()),
                  ],
                ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 12, color: MedievalColors.goldLeaf),
            const SizedBox(width: 8),
            Text(
              'Printed by The Guild in the City of Maura',
              textAlign: TextAlign.center,
              style: GoogleFonts.imFellEnglish(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: MedievalColors.sepiaSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.auto_awesome, size: 12, color: MedievalColors.goldLeaf),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Postal Press',
          textAlign: TextAlign.center,
          style: GoogleFonts.imFellEnglish(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
      ],
    );
  }
}
