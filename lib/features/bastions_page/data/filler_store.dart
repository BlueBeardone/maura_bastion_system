import 'dart:convert';

import 'package:maura_bastion_system/data/models/news_paper/news_paper_article.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FillerStore {
  static const _prefix = 'fillers_';
  static const _cap = 10;

  Future<void> append(String bastionId, NewspaperArticle article) async {
    final existing = await read(bastionId);
    final updated = [...existing, article];
    if (updated.length > _cap) {
      updated.removeRange(0, updated.length - _cap);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$bastionId',
      jsonEncode([for (final a in updated) _toJson(a)]),
    );
  }

  Future<List<NewspaperArticle>> read(String bastionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$bastionId');
    if (raw == null) return [];
    try {
      return _decodeList(jsonDecode(raw) as List<dynamic>);
    } catch (_) {
      return [];
    }
  }

  Future<List<NewspaperArticle>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final all = <NewspaperArticle>[];
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      try {
        all.addAll(_decodeList(jsonDecode(prefs.getString(key)!) as List<dynamic>));
      } catch (_) {
        // Corrupt key: skip silently.
      }
    }
    return all;
  }

  List<NewspaperArticle> _decodeList(List<dynamic> raw) => [
        for (final entry in raw)
          if (entry is Map<String, dynamic>) ?_fromJson(entry),
      ];

  NewspaperArticle? _fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final content = json['content'];
    if (title is! String || content is! String) return null;
    return NewspaperArticle(
      title: title,
      content: content,
      imageUrl: json['imageUrl'] is String ? json['imageUrl'] as String : null,
      author: json['author'] is String ? json['author'] as String : null,
    );
  }

  Map<String, dynamic> _toJson(NewspaperArticle article) => {
        'title': article.title,
        'content': article.content,
        'imageUrl': article.imageUrl,
        'author': article.author,
      };
}
