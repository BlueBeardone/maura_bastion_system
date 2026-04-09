class NewspaperArticle {
  final String title;
  final String content;
  final String? imageUrl;
  final String? author;

  NewspaperArticle({
    required this.title,
    required this.content,
    this.imageUrl,
    this.author,
  });
}