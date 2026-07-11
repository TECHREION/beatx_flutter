class AudiobookDetailsData {
  final Book? book;
  final List<Chapter>? chapters;
  final UserProgress? userProgress;

  AudiobookDetailsData({
    this.book,
    this.chapters,
    this.userProgress,
  });

  factory AudiobookDetailsData.fromJson(Map<String, dynamic> json) {
    return AudiobookDetailsData(
      book: json['book'] != null ? Book.fromJson(json['book']) : null,
      chapters: json['chapters'] != null
          ? List<Chapter>.from(
              json['chapters'].map((x) => Chapter.fromJson(x)),
            )
          : [],
      userProgress: json['userProgress'] != null
          ? UserProgress.fromJson(json['userProgress'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book?.toJson(),
      'chapters': chapters?.map((e) => e.toJson()).toList(),
      'userProgress': userProgress?.toJson(),
    };
  }
}

class Book {
  final String? id;
  final String? title;
  final String? author;
  final String? narrator;
  final String? coverUrl;
  final String? coverKey;
  final String? synopsis;
  final String? language;
  final int? totalDurationMs;
  final Genre? genre;
  final double? ratingAverage;
  final int? ratingCount;
  final int? playCount;
  final int? playCountWeek;
  final bool? isBestseller;
  final bool? isTrending;
  final bool? isFeatured;
  final String? status;
  final List<dynamic>? universe;
  final String? publishedAt;
  final int? bestsellerRank;
  final String? trendDirection;
  final String? createdAt;
  final String? updatedAt;
  final int? v;
  final int? totalChapters;

  Book({
    this.id,
    this.title,
    this.author,
    this.narrator,
    this.coverUrl,
    this.coverKey,
    this.synopsis,
    this.language,
    this.totalDurationMs,
    this.genre,
    this.ratingAverage,
    this.ratingCount,
    this.playCount,
    this.playCountWeek,
    this.isBestseller,
    this.isTrending,
    this.isFeatured,
    this.status,
    this.universe,
    this.publishedAt,
    this.bestsellerRank,
    this.trendDirection,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.totalChapters,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['_id'],
      title: json['title'],
      author: json['author'],
      narrator: json['narrator'],
      coverUrl: json['coverUrl'],
      coverKey: json['coverKey'],
      synopsis: json['synopsis'],
      language: json['language'],
      totalDurationMs: json['totalDurationMs'],
      genre: json['genre'] != null ? Genre.fromJson(json['genre']) : null,
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'],
      playCount: json['playCount'],
      playCountWeek: json['playCountWeek'],
      isBestseller: json['isBestseller'],
      isTrending: json['isTrending'],
      isFeatured: json['isFeatured'],
      status: json['status'],
      universe: json['universe'] ?? [],
      publishedAt: json['publishedAt'],
      bestsellerRank: json['bestsellerRank'],
      trendDirection: json['trendDirection'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      v: json['__v'],
      totalChapters: json['totalChapters'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'author': author,
      'narrator': narrator,
      'coverUrl': coverUrl,
      'coverKey': coverKey,
      'synopsis': synopsis,
      'language': language,
      'totalDurationMs': totalDurationMs,
      'genre': genre?.toJson(),
      'ratingAverage': ratingAverage,
      'ratingCount': ratingCount,
      'playCount': playCount,
      'playCountWeek': playCountWeek,
      'isBestseller': isBestseller,
      'isTrending': isTrending,
      'isFeatured': isFeatured,
      'status': status,
      'universe': universe,
      'publishedAt': publishedAt,
      'bestsellerRank': bestsellerRank,
      'trendDirection': trendDirection,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
      'totalChapters': totalChapters,
    };
  }
}

class Genre {
  final String? id;
  final String? name;

  Genre({
    this.id,
    this.name,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}

class Chapter {
  final String? id;
  final int? chapterNumber;
  final String? title;
  final int? durationMs;

  Chapter({
    this.id,
    this.chapterNumber,
    this.title,
    this.durationMs,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['_id'],
      chapterNumber: json['chapterNumber'],
      title: json['title'],
      durationMs: json['durationMs'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'chapterNumber': chapterNumber,
      'title': title,
      'durationMs': durationMs,
    };
  }
}

/// Currently the API returns `null` for userProgress.
/// Extend this model later if the backend starts sending data.
class UserProgress {
  UserProgress();

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress();
  }

  Map<String, dynamic> toJson() => {};
}

class Metadata {
  final String? duration;

  Metadata({
    this.duration,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
    };
  }
}