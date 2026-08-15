class PodcastDetailsModel {
  final Podcast podcast;
  final List<PodcastEpisode> episodes;
  final int episodesTotal;

  PodcastDetailsModel({
    required this.podcast,
    required this.episodes,
    required this.episodesTotal,
  });

  factory PodcastDetailsModel.fromJson(Map<String, dynamic> json) {
    return PodcastDetailsModel(
      podcast: Podcast.fromJson(json['podcast'] ?? {}),
      episodes: (json['episodes'] as List? ?? [])
          .map((e) => PodcastEpisode.fromJson(e))
          .toList(),
      episodesTotal: json['episodesTotal'] ?? 0,
    );
  }
}

class Podcast {
  final String? submittedStatus;
  final DateTime? submittedScheduledAt;
  final DateTime? submittedAt;
  final String? rejectionReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  final String id;
  final String title;
  final String description;
  final String? coverUrl;
  final String? coverKey;
  final String language;

  final Genre genre;
  final Owner ownerId;

  final int totalEpisodes;
  final int totalDurationMs;

  final double ratingAverage;
  final int ratingCount;

  final int playCount;
  final int playCountWeek;

  final bool isFeatured;
  final bool isTrending;

  final String trendDirection;
  final String status;

  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Whether the signed-in user has liked this podcast. The episode
  /// endpoints carry no such flag, so this record is what the player screen
  /// settles its heart against.
  final bool isLiked;
  final int likeCount;

  final int version;

  Podcast({
    this.submittedStatus,
    this.submittedScheduledAt,
    this.submittedAt,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    required this.id,
    required this.title,
    required this.description,
    this.coverUrl,
    this.coverKey,
    required this.language,
    required this.genre,
    required this.ownerId,
    required this.totalEpisodes,
    required this.totalDurationMs,
    required this.ratingAverage,
    required this.ratingCount,
    required this.playCount,
    required this.playCountWeek,
    required this.isFeatured,
    required this.isTrending,
    required this.trendDirection,
    required this.status,
    this.scheduledAt,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    this.isLiked = false,
    this.likeCount = 0,
    required this.version,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      submittedStatus: json['submittedStatus'],
      submittedScheduledAt: _parseDate(json['submittedScheduledAt']),
      submittedAt: _parseDate(json['submittedAt']),
      rejectionReason: json['rejectionReason'],
      reviewedBy: json['reviewedBy'],
      reviewedAt: _parseDate(json['reviewedAt']),
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverUrl: json['coverUrl'],
      coverKey: json['coverKey'],
      language: json['language'] ?? '',
      genre: Genre.fromJson(json['genre'] ?? {}),
      ownerId: Owner.fromJson(json['ownerId'] ?? {}),
      totalEpisodes: json['totalEpisodes'] ?? 0,
      totalDurationMs: json['totalDurationMs'] ?? 0,
      ratingAverage: (json['ratingAverage'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      playCount: json['playCount'] ?? 0,
      playCountWeek: json['playCountWeek'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      isTrending: json['isTrending'] ?? false,
      trendDirection: json['trendDirection'] ?? '',
      status: json['status'] ?? '',
      scheduledAt: _parseDate(json['scheduledAt']),
      publishedAt: _parseDate(json['publishedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      isLiked: json['isLiked'] ?? false,
      likeCount: json['likeCount'] ?? 0,
      version: json['__v'] ?? 0,
    );
  }
}

class Genre {
  final String id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(id: json['_id'] ?? '', name: json['name'] ?? '');
  }
}

class Owner {
  final String id;
  final String name;

  Owner({required this.id, required this.name});

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(id: json['_id'] ?? '', name: json['name'] ?? '');
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
      publishedAt: _parseDate(json['publishedAt']),
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

DateTime? _parseDate(dynamic value) {
  if (value == null || value.toString().isEmpty) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}
