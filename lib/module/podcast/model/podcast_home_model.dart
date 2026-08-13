class PodcastHomeData {
  final List<ContinueListening> continueListening;
  final List<FeaturedPodcast> featured;
  final List<TopCategory> topCategories;
  final TopPodcasters topPodcasters;
  final List<RecentEpisode> recentEpisodes;

  PodcastHomeData({
    required this.continueListening,
    required this.featured,
    required this.topCategories,
    required this.topPodcasters,
    required this.recentEpisodes,
  });

  factory PodcastHomeData.fromJson(Map<String, dynamic> json) {
    return PodcastHomeData(
      continueListening: (json['continueListening'] as List? ?? [])
          .map((e) => ContinueListening.fromJson(e))
          .toList(),
      featured: (json['featured'] as List? ?? [])
          .map((e) => FeaturedPodcast.fromJson(e))
          .toList(),
      topCategories: (json['topCategories'] as List? ?? [])
          .map((e) => TopCategory.fromJson(e))
          .toList(),
      topPodcasters: TopPodcasters.fromJson(json['topPodcasters'] ?? {}),
      recentEpisodes: (json['recentEpisodes'] as List? ?? [])
          .map((e) => RecentEpisode.fromJson(e))
          .toList(),
    );
  }
}

class ContinueListening {
  final Progress progress;
  final Episode episode;
  final PodcastBasic podcast;

  ContinueListening({
    required this.progress,
    required this.episode,
    required this.podcast,
  });

  factory ContinueListening.fromJson(Map<String, dynamic> json) {
    return ContinueListening(
      progress: Progress.fromJson(json['progress'] ?? {}),
      episode: Episode.fromJson(json['episode'] ?? {}),
      podcast: PodcastBasic.fromJson(json['podcast'] ?? {}),
    );
  }
}

class Progress {
  final int positionMs;
  final double percentComplete;
  final DateTime lastListenedAt;

  Progress({
    required this.positionMs,
    required this.percentComplete,
    required this.lastListenedAt,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      positionMs: json['positionMs'] ?? 0,
      percentComplete: (json['percentComplete'] ?? 0).toDouble(),
      lastListenedAt: DateTime.parse(json['lastListenedAt']),
    );
  }
}

class Episode {
  final String id;
  final String title;
  final String? coverUrl;
  final int durationMs;

  Episode({
    required this.id,
    required this.title,
    this.coverUrl,
    required this.durationMs,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      coverUrl: json['coverUrl'],
      durationMs: json['durationMs'] ?? 0,
    );
  }
}

class PodcastBasic {
  final String id;
  final String title;
  final String? coverUrl;

  PodcastBasic({
    required this.id,
    required this.title,
    this.coverUrl,
  });

  factory PodcastBasic.fromJson(Map<String, dynamic> json) {
    return PodcastBasic(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      coverUrl: json['coverUrl'],
    );
  }
}

class FeaturedPodcast {
  final String id;
  final String title;
  final String description;
  final String? coverUrl;
  final Genre genre;
  final int totalEpisodes;
  final double ratingAverage;

  FeaturedPodcast({
    required this.id,
    required this.title,
    required this.description,
    this.coverUrl,
    required this.genre,
    required this.totalEpisodes,
    required this.ratingAverage,
  });

  factory FeaturedPodcast.fromJson(Map<String, dynamic> json) {
    return FeaturedPodcast(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverUrl: json['coverUrl'],
      genre: Genre.fromJson(json['genre'] ?? {}),
      totalEpisodes: json['totalEpisodes'] ?? 0,
      ratingAverage: (json['ratingAverage'] ?? 0).toDouble(),
    );
  }
}

class Genre {
  final String id;
  final String name;

  Genre({
    required this.id,
    required this.name,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class TopCategory {
  final String genreId;
  final String name;
  final int podcastCount;

  TopCategory({
    required this.genreId,
    required this.name,
    required this.podcastCount,
  });

  factory TopCategory.fromJson(Map<String, dynamic> json) {
    return TopCategory(
      genreId: json['genreId'] ?? '',
      name: json['name'] ?? '',
      podcastCount: json['podcastCount'] ?? 0,
    );
  }
}

class TopPodcasters {
  final List<Podcaster> data;
  final int total;
  final int page;
  final int limit;

  TopPodcasters({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory TopPodcasters.fromJson(Map<String, dynamic> json) {
    return TopPodcasters(
      data: (json['data'] as List? ?? [])
          .map((e) => Podcaster.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 5,
    );
  }
}

class Podcaster {
  final String id;
  final String name;
  final String? stageName;
  final String? artistAvatar;
  final bool isFollowing;

  Podcaster({
    required this.id,
    required this.name,
    this.stageName,
    this.artistAvatar,
    required this.isFollowing,
  });

  factory Podcaster.fromJson(Map<String, dynamic> json) {
    return Podcaster(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      stageName: json['stageName'],
      artistAvatar: json['artistAvatar'],
      isFollowing: json['isFollowing'] ?? false,
    );
  }
}

class RecentEpisode {
  final String id;
  final PodcastBasic podcastId;
  final int episodeNumber;
  final int seasonNumber;
  final String title;
  final String? coverUrl;
  final int durationMs;
  final DateTime publishedAt;

  RecentEpisode({
    required this.id,
    required this.podcastId,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.title,
    this.coverUrl,
    required this.durationMs,
    required this.publishedAt,
  });

  factory RecentEpisode.fromJson(Map<String, dynamic> json) {
    return RecentEpisode(
      id: json['_id'] ?? '',
      podcastId: PodcastBasic.fromJson(json['podcastId'] ?? {}),
      episodeNumber: json['episodeNumber'] ?? 0,
      seasonNumber: json['seasonNumber'] ?? 0,
      title: json['title'] ?? '',
      coverUrl: json['coverUrl'],
      durationMs: json['durationMs'] ?? 0,
      publishedAt: DateTime.parse(json['publishedAt']),
    );
  }
}

class Metadata {
  final String duration;

  Metadata({
    required this.duration,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      duration: json['duration'] ?? '',
    );
  }
}