import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/features/news_paper/presentation/widgets/ornamental_divider.dart';

class MainNewsArticle extends StatelessWidget {
  final NewspaperArticle article;

  const MainNewsArticle({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: OrnamentalDivider(),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.title.toUpperCase(),
                style: GoogleFonts.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: MedievalColors.vermillion,
                  height: 1.1,
                  letterSpacing: -0.3,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                width: 120,
                height: 1.5,
                color: MedievalColors.goldPale,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '\u270d By ${article.author} \u2014 Royal Scribe',
            style: GoogleFonts.imFellEnglish(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: MedievalColors.sepiaSecondary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (article.imageUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildFramedImage(article.imageUrl!),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildImagePlaceholder(),
          ),
        const SizedBox(height: 10),
        _buildArticleWithDropCap(article.content),
      ],
    );
  }

  Widget _buildFramedImage(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: MedievalColors.goldPale, width: 2),
      ),
      child: Stack(
        children: [
          Image.network(
            imageUrl,
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildImagePlaceholder(),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: _nailDot(),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: _nailDot(),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: _nailDot(),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: _nailDot(),
          ),
        ],
      ),
    );
  }

  Widget _nailDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: MedievalColors.goldLeaf,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 1,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: MedievalColors.goldPale, width: 2),
        color: MedievalColors.parchment.withAlpha(80),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories,
            size: 40,
            color: MedievalColors.sepiaMuted,
          ),
          const SizedBox(height: 8),
          Text(
            'Engraving Unavailable',
            style: GoogleFonts.imFellEnglish(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: MedievalColors.sepiaMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleWithDropCap(String text) {
    if (text.isEmpty) return const SizedBox.shrink();

    final trimmed = text.trimLeft();
    final leadingSpaces = text.length - trimmed.length;
    final firstChar = trimmed.substring(0, 1);
    final restOfText = trimmed.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.imFellEnglish(
            fontSize: 16,
            height: 1.5,
            color: MedievalColors.sepiaInk,
          ),
          children: [
            if (leadingSpaces > 0)
              TextSpan(text: text.substring(0, leadingSpaces)),
            TextSpan(
              text: firstChar,
              style: GoogleFonts.cinzelDecorative(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                height: 0.8,
                color: MedievalColors.goldLeaf,
                shadows: [
                  Shadow(
                    color: MedievalColors.vermillion.withAlpha(100),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
            TextSpan(text: restOfText),
          ],
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
