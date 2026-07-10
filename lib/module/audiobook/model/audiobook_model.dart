class HomeAudiobookData {
  final List<ContinueListeningBook> continueListening;
  final List<Audiobook> newReleases;
  final List<Bestseller> bestsellers;
  final List<TrendingAudiobook> trending;

  const HomeAudiobookData({
    this.continueListening = const [],
    this.newReleases = const [],
    this.bestsellers = const [],
    this.trending = const [],
  });

  factory HomeAudiobookData.fromJson(Map<String, dynamic> json) {
    return HomeAudiobookData(
      continueListening: _mapList(
        json['continueListening'],
        ContinueListeningBook.fromJson,
      ),
      newReleases: _mapList(json['newReleases'], Audiobook.fromJson),
      bestsellers: _mapList(json['bestsellers'], Bestseller.fromJson),
      trending: _mapList(json['trending'], TrendingAudiobook.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'continueListening': continueListening.map((e) => e.toJson()).toList(),
      'newReleases': newReleases.map((e) => e.toJson()).toList(),
      'bestsellers': bestsellers.map((e) => e.toJson()).toList(),
      'trending': trending.map((e) => e.toJson()).toList(),
    };
  }

  bool get isEmpty =>
      continueListening.isEmpty &&
      newReleases.isEmpty &&
      bestsellers.isEmpty &&
      trending.isEmpty;
}

List<T> _mapList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

class Audiobook {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final int totalChapters;
  final int totalDurationMs;
  final Genre? genre;
  final double ratingAverage;
  final DateTime? publishedAt;

  const Audiobook({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl = '',
    this.totalChapters = 0,
    this.totalDurationMs = 0,
    this.genre,
    this.ratingAverage = 0,
    this.publishedAt,
  });

  factory Audiobook.fromJson(Map<String, dynamic> json) {
    return Audiobook(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
      totalChapters: parseInt(json['totalChapters']),
      totalDurationMs: parseInt(json['totalDurationMs']),
      genre: json['genre'] is Map
          ? Genre.fromJson(Map<String, dynamic>.from(json['genre'] as Map))
          : null,
      ratingAverage: parseDouble(json['ratingAverage']),
      publishedAt: parseDate(json['publishedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'totalChapters': totalChapters,
      'totalDurationMs': totalDurationMs,
      'genre': genre?.toJson(),
      'ratingAverage': ratingAverage,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }

  String get genreName => genre?.name ?? '';

  /// `16h 10m`, `52m`, or an empty string when the backend reports no duration.
  String get formattedDuration => formatDuration(totalDurationMs);
}

class Genre {
  final String id;
  final String name;

  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'_id': id, 'name': name};
}

/// A `newReleases`/`trending` entry the user has already started.
///
/// The backend returned an empty `continueListening` array while this was
/// written, so playback keys are read leniently from the aliases the rest of
/// the API uses.
class ContinueListeningBook extends Audiobook {
  final int positionMs;
  final String chapterTitle;

  const ContinueListeningBook({
    required super.id,
    required super.title,
    required super.author,
    super.coverUrl,
    super.totalChapters,
    super.totalDurationMs,
    super.genre,
    super.ratingAverage,
    super.publishedAt,
    this.positionMs = 0,
    this.chapterTitle = '',
  });

  factory ContinueListeningBook.fromJson(Map<String, dynamic> json) {
    final book = Audiobook.fromJson(json);
    final chapter = json['currentChapter'];

    return ContinueListeningBook(
      id: book.id,
      title: book.title,
      author: book.author,
      coverUrl: book.coverUrl,
      totalChapters: book.totalChapters,
      totalDurationMs: book.totalDurationMs,
      genre: book.genre,
      ratingAverage: book.ratingAverage,
      publishedAt: book.publishedAt,
      positionMs: parseInt(json['positionMs'] ?? json['lastPositionMs']),
      chapterTitle: chapter is Map
          ? (chapter['title']?.toString() ?? '')
          : (json['chapterTitle']?.toString() ?? ''),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'positionMs': positionMs,
    'chapterTitle': chapterTitle,
  };

  /// 0..1, safe against a zero or missing `totalDurationMs`.
  double get progress {
    if (totalDurationMs <= 0) return 0;
    return (positionMs / totalDurationMs).clamp(0.0, 1.0);
  }

  int get remainingMs =>
      (totalDurationMs - positionMs).clamp(0, totalDurationMs);

  String get formattedRemaining {
    final remaining = formatDuration(remainingMs);
    return remaining.isEmpty ? '' : '$remaining REMAINING';
  }
}

class TrendingAudiobook extends Audiobook {
  final int playCountWeek;
  final String trendDirection;

  const TrendingAudiobook({
    required super.id,
    required super.title,
    required super.author,
    super.coverUrl,
    super.totalChapters,
    super.totalDurationMs,
    super.genre,
    super.ratingAverage,
    super.publishedAt,
    this.playCountWeek = 0,
    this.trendDirection = '',
  });

  factory TrendingAudiobook.fromJson(Map<String, dynamic> json) {
    final book = Audiobook.fromJson(json);

    return TrendingAudiobook(
      id: book.id,
      title: book.title,
      author: book.author,
      coverUrl: book.coverUrl,
      totalChapters: book.totalChapters,
      totalDurationMs: book.totalDurationMs,
      genre: book.genre,
      ratingAverage: book.ratingAverage,
      publishedAt: book.publishedAt,
      playCountWeek: parseInt(json['playCountWeek']),
      trendDirection: json['trendDirection']?.toString() ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'playCountWeek': playCountWeek,
    'trendDirection': trendDirection,
  };

  bool get isTrendingUp => trendDirection.toLowerCase() == 'up';
}

class Bestseller {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final double ratingAverage;
  final int bestsellerRank;
  final String trendDirection;

  const Bestseller({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl = '',
    this.ratingAverage = 0,
    this.bestsellerRank = 0,
    this.trendDirection = '',
  });

  factory Bestseller.fromJson(Map<String, dynamic> json) {
    return Bestseller(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString() ?? '',
      ratingAverage: parseDouble(json['ratingAverage']),
      bestsellerRank: parseInt(json['bestsellerRank']),
      trendDirection: json['trendDirection']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'author': author,
    'coverUrl': coverUrl,
    'ratingAverage': ratingAverage,
    'bestsellerRank': bestsellerRank,
    'trendDirection': trendDirection,
  };

  bool get isTrendingUp => trendDirection.toLowerCase() == 'up';

  String get formattedRank => bestsellerRank.toString().padLeft(2, '0');

  Audiobook toAudiobook() => Audiobook(
    id: id,
    title: title,
    author: author,
    coverUrl: coverUrl,
    ratingAverage: ratingAverage,
  );
}

int parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String formatDuration(int milliseconds) {
  if (milliseconds <= 0) return '';
  final duration = Duration(milliseconds: milliseconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '${minutes}m';
  return '${hours}h ${minutes}m';
}
