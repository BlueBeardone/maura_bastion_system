import 'package:flutter/material.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';

class NewsArticle extends StatelessWidget {
  final NewspaperArticle article;

  const NewsArticle({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              article.title.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('By ${article.author}', style: Theme.of(context).textTheme.bodySmall),
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
                      TextSpan(
                        text: article.content,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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
        color: imageUrl != null? Theme.of(context).cardColor : Colors.grey[300],
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