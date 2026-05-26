import 'package:flutter/material.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';

class NewsArticle extends StatelessWidget {
  final NewspaperArticle article;

  const NewsArticle({super.key, required this.article});

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
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.all(8.0), // Fixed EdgeInsetsGeometry.all
            child: Text('By ${article.author}'),
          ),
          const SizedBox(height: 8),
          _buildImagePlaceholder(context, article.imageUrl, height: 360),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Optional: keep text padding consistent
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: article.content),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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