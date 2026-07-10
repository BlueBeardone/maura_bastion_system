import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maura_bastion_system/core/themes/theme_colors.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';

class NewsArticle extends StatefulWidget {
  final NewspaperArticle article;
  final String date;

  const NewsArticle({super.key, required this.article, required this.date});

  @override
  State<NewsArticle> createState() => _NewsArticleState();
}

class _NewsArticleState extends State<NewsArticle> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: MedievalColors.parchment.withAlpha(60),
          border: Border(
            left: BorderSide(color: MedievalColors.goldPale, width: 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.article.title.toUpperCase(),
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MedievalColors.vermillion,
                height: 1.15,
                letterSpacing: -0.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              width: 60,
              height: 1,
              color: MedievalColors.goldPale,
            ),
            const SizedBox(height: 6),
            Text(
              widget.date,
              style: GoogleFonts.imFellEnglish(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: MedievalColors.sepiaSecondary,
              ),
            ),
            const SizedBox(height: 6),
            if (widget.article.imageUrl != null)
              _buildFramedImage(widget.article.imageUrl!)
            else
              _buildImagePlaceholder(),
            const SizedBox(height: 8),
            Text(
              widget.article.content,
              style: GoogleFonts.imFellEnglish(
                fontSize: 14,
                height: 1.45,
                color: MedievalColors.sepiaInk,
              ),
              maxLines: _isExpanded ? null : 4,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
              textAlign: TextAlign.justify,
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 8),
              Divider(color: MedievalColors.goldPale, thickness: 0.5, height: 1),
              const SizedBox(height: 4),
              Text(
                'Written by ${widget.article.author}',
                style: GoogleFonts.imFellEnglish(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: MedievalColors.sepiaSecondary,
                ),
              ),
            ],
            if (!_isExpanded && widget.article.content.length > 200)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Read the full account...',
                  style: GoogleFonts.imFellEnglish(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: MedievalColors.goldLeaf,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFramedImage(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: MedievalColors.goldPale, width: 1.5),
      ),
      child: Stack(
        children: [
          Image.network(
            imageUrl,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildImagePlaceholder(),
          ),
          Positioned(
            top: 2,
            left: 2,
            child: _nailDot(),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: _nailDot(),
          ),
          Positioned(
            bottom: 2,
            left: 2,
            child: _nailDot(),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: _nailDot(),
          ),
        ],
      ),
    );
  }

  Widget _nailDot() {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: MedievalColors.goldLeaf,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 1,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: MedievalColors.goldPale.withAlpha(100)),
        color: MedievalColors.parchment.withAlpha(50),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories,
            size: 24,
            color: MedievalColors.sepiaMuted,
          ),
          const SizedBox(height: 4),
          Text(
            'No Engraving',
            style: GoogleFonts.imFellEnglish(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: MedievalColors.sepiaMuted,
            ),
          ),
        ],
      ),
    );
  }
}