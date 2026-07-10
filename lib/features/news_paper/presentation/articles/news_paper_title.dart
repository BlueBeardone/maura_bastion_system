import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_data.dart';

class NewsPaperTitle extends StatelessWidget {
  final NewspaperData newspaperData;

  const NewsPaperTitle({super.key, required this.newspaperData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MedievalColors.parchmentDark.withAlpha(80),
        border: Border(
          top: BorderSide(color: MedievalColors.goldLeaf, width: 2),
          bottom: BorderSide(color: MedievalColors.goldLeaf, width: 2),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield, size: 20, color: MedievalColors.goldLeaf),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  newspaperData.newspaperName.toUpperCase(),
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: MedievalColors.vermillion,
                    letterSpacing: 4,
                    height: 0.95,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.shield, size: 20, color: MedievalColors.goldLeaf),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            color: MedievalColors.goldPale,
            margin: const EdgeInsets.symmetric(horizontal: 40),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                newspaperData.edition,
                style: GoogleFonts.imFellEnglish(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: MedievalColors.sepiaSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '\u2726',
                style: TextStyle(
                  fontSize: 8,
                  color: MedievalColors.goldPale,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                newspaperData.date,
                style: GoogleFonts.imFellEnglish(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: MedievalColors.sepiaSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '\u2726',
                style: TextStyle(
                  fontSize: 8,
                  color: MedievalColors.goldPale,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'PRICE: TWO COPPER',
                style: GoogleFonts.imFellEnglish(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: MedievalColors.sepiaSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(color: MedievalColors.goldPale, thickness: 1, height: 1),
          const SizedBox(height: 4),
          Text(
            '\u201cYe Olde Reliable Newes\u201d',
            style: GoogleFonts.imFellEnglish(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: MedievalColors.sepiaSecondary,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
