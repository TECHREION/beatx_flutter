class ListenMusicModel {
  final List<FeaturedSong> featured;
  final List<TrendingSong> trending;
  final List<NewReleaseSong> newReleases;
  final List<TopCategory> topCategories;
  final List<DailyDiscoverySong> dailyDiscovery;
  final PaginatedSongs onRepeat;
  final PaginatedSongs recentlyPlayed;

  ListenMusicModel({
    this.featured = const [],
    this.trending = const [],
    this.newReleases = const [],
    this.topCategories = const [],
    this.dailyDiscovery = const [],
    this.onRepeat = const PaginatedSongs(),
    this.recentlyPlayed = const PaginatedSongs(),
  });

  factory ListenMusicModel.fromJson(Map<String, dynamic> json) {
    return ListenMusicModel(
      featured: (json['featured'] as List? ?? [])
          .map((e) => FeaturedSong.fromJson(e))
          .toList(),
      trending: (json['trending'] as List? ?? [])
          .map((e) => TrendingSong.fromJson(e))
          .toList(),
      newReleases: (json['newReleases'] as List? ?? [])
          .map((e) => NewReleaseSong.fromJson(e))
          .toList(),
      topCategories: (json['topCategories'] as List? ?? [])
          .map((e) => TopCategory.fromJson(e))
          .toList(),
      dailyDiscovery: (json['dailyDiscovery'] as List? ?? [])
          .map((e) => DailyDiscoverySong.fromJson(e))
          .toList(),
      onRepeat: PaginatedSongs.fromJson(json['onRepeat'] ?? {}),
      recentlyPlayed:
          PaginatedSongs.fromJson(json['recentlyPlayed'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'featured': featured.map((e) => e.toJson()).toList(),
      'trending': trending.map((e) => e.toJson()).toList(),
      'newReleases': newReleases.map((e) => e.toJson()).toList(),
      'topCategories': topCategories.map((e) => e.toJson()).toList(),
      'dailyDiscovery': dailyDiscovery.map((e) => e.toJson()).toList(),
      'onRepeat': onRepeat.toJson(),
      'recentlyPlayed': recentlyPlayed.toJson(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}

class FeaturedSong {
  final String id;
  final String title;
  final String artist;
  final Genre genre;
  final String coverUrl;
  final int durationMs;
  final int playCount;

  FeaturedSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.coverUrl,
    required this.durationMs,
    required this.playCount,
  });

  factory FeaturedSong.fromJson(Map<String, dynamic> json) {
    return FeaturedSong(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      genre: Genre.fromJson(json['genre'] ?? {}),
      coverUrl: json['coverUrl'] ?? '',
      durationMs: json['durationMs'] ?? 0,
      playCount: json['playCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'artist': artist,
      'genre': genre.toJson(),
      'coverUrl': coverUrl,
      'durationMs': durationMs,
      'playCount': playCount,
    };
  }
}

class TrendingSong {
  final String id;
  final String title;
  final String artist;
  final Genre genre;
  final String coverUrl;
  final int durationMs;
  final String trendDirection;

  TrendingSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.coverUrl,
    required this.durationMs,
    required this.trendDirection,
  });

  factory TrendingSong.fromJson(Map<String, dynamic> json) {
    return TrendingSong(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      genre: Genre.fromJson(json['genre'] ?? {}),
      coverUrl: json['coverUrl'] ?? '',
      durationMs: json['durationMs'] ?? 0,
      trendDirection: json['trendDirection'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'artist': artist,
      'genre': genre.toJson(),
      'coverUrl': coverUrl,
      'durationMs': durationMs,
      'trendDirection': trendDirection,
    };
  }
}

class NewReleaseSong {
  final String id;
  final String title;
  final String artist;
  final Genre genre;
  final String coverUrl;
  final int durationMs;
  final DateTime publishedAt;

  NewReleaseSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.coverUrl,
    required this.durationMs,
    required this.publishedAt,
  });

  factory NewReleaseSong.fromJson(Map<String, dynamic> json) {
    return NewReleaseSong(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      genre: Genre.fromJson(json['genre'] ?? {}),
      coverUrl: json['coverUrl'] ?? '',
      durationMs: json['durationMs'] ?? 0,
      publishedAt: DateTime.parse(json['publishedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'artist': artist,
      'genre': genre.toJson(),
      'coverUrl': coverUrl,
      'durationMs': durationMs,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }
}

class DailyDiscoverySong {
  final String id;
  final String title;
  final String artist;
  final Genre genre;
  final String coverUrl;
  final int durationMs;

  DailyDiscoverySong({
    required this.id,
    required this.title,
    required this.artist,
    required this.genre,
    required this.coverUrl,
    required this.durationMs,
  });

  factory DailyDiscoverySong.fromJson(Map<String, dynamic> json) {
    return DailyDiscoverySong(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      genre: Genre.fromJson(json['genre'] ?? {}),
      coverUrl: json['coverUrl'] ?? '',
      durationMs: json['durationMs'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'artist': artist,
      'genre': genre.toJson(),
      'coverUrl': coverUrl,
      'durationMs': durationMs,
    };
  }
}

class TopCategory {
  final String genreId;
  final String name;
  final int songCount;

  TopCategory({
    required this.genreId,
    required this.name,
    required this.songCount,
  });

  factory TopCategory.fromJson(Map<String, dynamic> json) {
    return TopCategory(
      genreId: json['genreId'] ?? '',
      name: json['name'] ?? '',
      songCount: json['songCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'genreId': genreId,
      'name': name,
      'songCount': songCount,
    };
  }
}

class PaginatedSongs {
  final List<dynamic> data;
  final int total;
  final int page;
  final int limit;

  const PaginatedSongs({
    this.data = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 10,
  });

  factory PaginatedSongs.fromJson(Map<String, dynamic> json) {
    return PaginatedSongs(
      data: json['data'] ?? [],
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'total': total,
      'page': page,
      'limit': limit,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
    };
  }
}