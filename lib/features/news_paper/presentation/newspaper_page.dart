import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_data.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/articles/main_news_article.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/articles/news_article.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/articles/news_paper_title.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/ornamental_divider.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/parchment_border.dart';

class NewspaperPage extends StatelessWidget {
  final NewspaperData newspaperData;

  const NewspaperPage({super.key, required this.newspaperData});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              NewsPaperTitle(newspaperData: newspaperData),
              const SizedBox(height: 12),
              MainNewsArticle(article: newspaperData.leadArticle),
              const SizedBox(height: 16),
              _buildSecondaryArticles(
                newspaperData.otherArticles,
                newspaperData.date,
              ),
              const SizedBox(height: 16),
              OrnamentalDivider(),
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
            children: articles
                .map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NewsArticle(article: a, date: date),
                    ))
                .toList(),
          );
        }

        final rows = <List<NewspaperArticle>>[];
        for (int i = 0; i < articles.length; i += columns) {
          rows.add(articles.skip(i).take(columns).toList());
        }

        return Column(
          children: rows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IntrinsicHeight(
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
                        child: NewsArticle(
                          article: row[i],
                          date: date,
                        ),
                      ),
                    ],
                    for (int i = row.length; i < columns; i++)
                      Expanded(child: const SizedBox.shrink()),
                  ],
                ),
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
                fontSize: 11,
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
            fontSize: 10,
            fontStyle: FontStyle.italic,
            color: MedievalColors.sepiaSecondary,
          ),
        ),
      ],
    );
  }
}
