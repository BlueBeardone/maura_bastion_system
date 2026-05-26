import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';

class NewspaperData {
  final String newspaperName;
  final String date;
  final String edition;
  final NewspaperArticle leadArticle;
  final List<NewspaperArticle> otherArticles;

  NewspaperData({
    required this.newspaperName,
    required this.date,
    required this.edition,
    required this.leadArticle,
    required this.otherArticles,
  });
}