class EpisodeModel {
  final List<PodcastEpisode> data;
  final int total;
  final int page;
  final int limit;

  EpisodeModel({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      data: (json['data'] as List? ?? [])
          .map((e) => PodcastEpisode.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
    );
  }
}

class PodcastEpisode {
  final String id;
  final int episodeNumber;
  final int seasonNumber;
  final String title;
  final String description;
  final String? coverUrl;
  final int durationMs;
  final DateTime? publishedAt;

  PodcastEpisode({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.title,
    required this.description,
    this.coverUrl,
    required this.durationMs,
    this.publishedAt,
  });

  factory PodcastEpisode.fromJson(Map<String, dynamic> json) {
    return PodcastEpisode(
      id: json['_id'] ?? '',
      episodeNumber: json['episodeNumber'] ?? 0,
      seasonNumber: json['seasonNumber'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverUrl: json['coverUrl'],
      durationMs: json['durationMs'] ?? 0,
      publishedAt: DateTime.tryParse(json['publishedAt'] ?? ''),
    );
  }
}

class Metadata {
  final String duration;

  Metadata({required this.duration});

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(duration: json['duration'] ?? '');
  }
}
