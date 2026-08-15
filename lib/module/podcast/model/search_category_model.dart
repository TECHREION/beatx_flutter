/// One page of the podcast search results — what `/podcasts/search` returns
/// when filtered by category.
class SearchCategoryData {
  final List<CategoryPodcast> data;
  final int total;
  final int page;
  final int limit;

  SearchCategoryData({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory SearchCategoryData.fromJson(Map<String, dynamic> json) {
    return SearchCategoryData(
      data: (json['data'] as List? ?? [])
          .map((e) => CategoryPodcast.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }
}

class CategoryPodcast {
  final String id;
  final String title;
  final String description;
  final String? coverUrl;
  final int totalEpisodes;
  final double ratingAverage;
  final int ratingCount;
  final DateTime? publishedAt;
  final PodcastCategory category;

  CategoryPodcast({
    required this.id,
    required this.title,
    required this.description,
    this.coverUrl,
    required this.totalEpisodes,
    required this.ratingAverage,
    required this.ratingCount,
    this.publishedAt,
    required this.category,
  });

  factory CategoryPodcast.fromJson(Map<String, dynamic> json) {
    return CategoryPodcast(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverUrl: json['coverUrl'],
      totalEpisodes: json['totalEpisodes'] ?? 0,
      ratingAverage: (json['ratingAverage'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
      category: PodcastCategory.fromJson(json['category'] ?? {}),
    );
  }

  /// `2 episodes`, `1 episode`, or '' when the show has none yet.
  String get episodeCountLabel {
    if (totalEpisodes <= 0) return '';
    return totalEpisodes == 1 ? '1 episode' : '$totalEpisodes episodes';
  }
}

class PodcastCategory {
  final String id;
  final String name;

  PodcastCategory({required this.id, required this.name});

  factory PodcastCategory.fromJson(Map<String, dynamic> json) {
    return PodcastCategory(id: json['_id'] ?? '', name: json['name'] ?? '');
  }
}
