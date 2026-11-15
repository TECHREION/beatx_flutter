/// A published legal page from `GET /legal/:slug`.
class LegalPage {
  const LegalPage({
    required this.slug,
    required this.title,
    required this.body,
    this.updatedAt,
  });

  final String slug;
  final String title;

  /// Markdown source.
  final String body;
  final DateTime? updatedAt;

  factory LegalPage.fromJson(Map<String, dynamic> json) => LegalPage(
    slug: (json['slug'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    body: (json['body'] ?? '').toString(),
    updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
  );

  /// The markdown as readable plain text: headings, emphasis and link
  /// syntax are stripped, list markers become bullets.
  String get plainText {
    return body
        .split('\n')
        .map((line) {
          var text = line.replaceFirst(RegExp(r'^\s{0,3}#{1,6}\s*'), '');
          text = text.replaceFirst(RegExp(r'^\s*[-*+]\s+'), '• ');
          text = text.replaceAllMapped(
            RegExp(r'\[([^\]]+)\]\([^)]+\)'),
            (m) => m[1]!,
          );
          // Only paired markers are removed, so underscores and asterisks
          // inside ordinary words survive.
          return text.replaceAll(RegExp(r'(\*\*|__|`)'), '');
        })
        .join('\n')
        .trim();
  }
}
