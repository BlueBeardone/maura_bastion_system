import 'api_client.dart';
import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';

class NewspaperApi {
  final ApiClient _client;

  NewspaperApi({required ApiClient client}) : _client = client;

  List<NewspaperArticle> _parseArticles(List<dynamic> data) {
    return data.map((a) {
      final map = a as Map<String, dynamic>;
      return NewspaperArticle(
        title: map['title'] as String,
        content: map['content'] as String,
        imageUrl: map['imageUrl'] as String?,
        author: map['author'] as String?,
      );
    }).toList();
  }

  Map<String, dynamic> _articleToJson(NewspaperArticle article) {
    return {
      'title': article.title,
      'content': article.content,
      'imageUrl': article.imageUrl,
      'author': article.author,
    };
  }

  Future<List<NewspaperArticle>> getAll() async {
    final data = await _client.get<List<dynamic>>(
      '/maura/v1/newspapers',
      parser: (json) => json as List<dynamic>,
    );
    return _parseArticles(data);
  }

  Future<NewspaperArticle> create(NewspaperArticle article) async {
    final data = await _client.post<Map<String, dynamic>>(
      '/maura/v1/newspapers',
      _articleToJson(article),
      parser: (json) => json as Map<String, dynamic>,
    );
    return _parseArticles([data]).first;
  }
}