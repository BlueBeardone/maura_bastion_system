import 'package:flutter/material.dart';
import 'package:maura_bastion_system/models/news_paper/news_paper_article.dart';
import 'package:maura_bastion_system/models/news_paper/news_paper_data.dart';
import 'package:maura_bastion_system/widgets/news_paper/news_article.dart';

class NewspaperLayout extends StatelessWidget {
  final NewspaperData data;

  const NewspaperLayout({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark, // dark surrounding area
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200), // classic broadsheet width
          color: Theme.of(context).scaffoldBackgroundColor, // aged paper
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMasthead(context),
                Divider(thickness: 2),
                const SizedBox(height: 16),
                _buildLeadArticle(context, data.leadArticle),
                const SizedBox(height: 24),
                _buildSecondaryArticles(data.otherArticles),
                const SizedBox(height: 32),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMasthead(BuildContext context) {
    return Column(
      children: [
        Text(
          data.newspaperName.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 48,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(data.date),
          ],
        ),
        const SizedBox(height: 8),
        Divider(thickness: 2),
        const SizedBox(height: 8),
        Text(
          '“ALL THE NEWS THAT’S FIT TO PRINT”',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLeadArticle(BuildContext context, NewspaperArticle article) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'By ${article.author}',
          ),
          const SizedBox(height: 12),
          // Image placeholder (1900s style)
          _buildImagePlaceholder(article.imageUrl),
          const SizedBox(height: 12),
          // Article text with drop cap
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

  Widget _buildSecondaryArticles(List<NewspaperArticle> articles) {
    if (articles.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use 2 columns on wide screens, otherwise 1 column.
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            mainAxisExtent: 380, // fixed height for each article card
          ),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return NewsArticle(article: article,);
          },
        );
      },
    );
  }

  // ------------------- Image placeholder (1900s black & white look) -------------------
  Widget _buildImagePlaceholder(String? imageUrl, {double height = 180}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: height,
        width: double.infinity,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_camera, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'VINTAGE PHOTOGRAPH',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------- Footer (simple line & mock advertisement) -------------------
  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Divider(thickness: 2),
        const SizedBox(height: 16),
        Text(
          '“THE MOST RELIABLE NEWS IN THE CITY”',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Published. Offices at Guild of Maura Street, Maura.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}