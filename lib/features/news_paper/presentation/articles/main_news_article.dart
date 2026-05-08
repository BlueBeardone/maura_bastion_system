import 'package:flutter/material.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';

class MainNewsArticle extends StatelessWidget {

  final NewspaperArticle article;

  const MainNewsArticle({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              article.title.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'By ${article.author}',
            ),
          ),
          const SizedBox(height: 12),
          _buildImagePlaceholder(context, article.imageUrl),
          const SizedBox(height: 12),
          _buildArticleWithDropCap(article.content),
        ],
      ),
    );
  }

  Widget _buildArticleWithDropCap(String text) {
    if (text.isEmpty) return const SizedBox.shrink();

    final firstChar = text.substring(0, 1);
    final restOfText = text.substring(1);

    return Padding(
      padding: EdgeInsetsGeometry.all(8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: firstChar,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 56,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            TextSpan(
              text: restOfText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context, String? imageUrl, {double height = 360}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: height,
        width: double.infinity,
        color: imageUrl != null? Theme.of(context).appBarTheme.backgroundColor : Colors.grey[300],
        child: Center(
          child: imageUrl != null? Image.network(imageUrl)
           : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_camera, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'Image',
              ),
            ],
          ),
        ),
      ),
    );
  }
}