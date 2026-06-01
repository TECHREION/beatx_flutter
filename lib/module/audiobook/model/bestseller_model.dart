class BestsellerModel {
  const BestsellerModel({
    required this.rank,
    required this.title,
    required this.author,
    required this.cover,
    required this.trendUp,
  });

  final String rank;
  final String title;
  final String author;
  final String cover;
  final bool trendUp;
}
