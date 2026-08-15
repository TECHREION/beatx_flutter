class ListenMusicDetailsModel {
  final String id;

  // Submission / review
  final String? ownerId;
  final String? submittedStatus;
  final DateTime? submittedScheduledAt;
  final DateTime? submittedAt;
  final String? rejectionReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  // Basic information
  final String title;
  final String artist;
  final String? album;
  final GenreModel genre;

  // Media
  final String coverUrl;
  final String coverKey;
  final String audioKey;
  final int durationMs;
  final String? hlsMasterUrl;
  final String transcodeStatus;

  // Status / statistics
  final bool explicit;
  final int playCount;
  final int playCountWeek;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Flags
  final bool isFeatured;
  final bool isTrending;
  final String? trendDirection;
  final int likeCount;

  /// Whether the signed-in user has liked this song. Absent from responses
  /// that are not user-scoped, in which case it reads false.
  final bool isLiked;

  final int version;

  ListenMusicDetailsModel({
    required this.id,
    this.ownerId,
    this.submittedStatus,
    this.submittedScheduledAt,
    this.submittedAt,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    required this.title,
    required this.artist,
    this.album,
    required this.genre,
    required this.coverUrl,
    required this.coverKey,
    required this.audioKey,
    required this.durationMs,
    this.hlsMasterUrl,
    required this.transcodeStatus,
    required this.explicit,
    required this.playCount,
    required this.playCountWeek,
    required this.status,
    this.scheduledAt,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    required this.isFeatured,
    required this.isTrending,
    this.trendDirection,
    required this.likeCount,
    this.isLiked = false,
    required this.version,
  });

  factory ListenMusicDetailsModel.fromJson(Map<String, dynamic> json) {
    return ListenMusicDetailsModel(
      id: json['_id'] ?? '',

      ownerId: json['ownerId'],
      submittedStatus: json['submittedStatus'],

      submittedScheduledAt:
          _parseDate(json['submittedScheduledAt']),

      submittedAt:
          _parseDate(json['submittedAt']),

      rejectionReason: json['rejectionReason'],
      reviewedBy: json['reviewedBy'],

      reviewedAt:
          _parseDate(json['reviewedAt']),

      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      album: json['album'],

      genre: GenreModel.fromJson(
        json['genre'] ?? {},
      ),

      coverUrl: json['coverUrl'] ?? '',
      coverKey: json['coverKey'] ?? '',
      audioKey: json['audioKey'] ?? '',

      durationMs: json['durationMs'] ?? 0,

      hlsMasterUrl: json['hlsMasterUrl'],

      transcodeStatus:
          json['transcodeStatus'] ?? '',

      explicit: json['explicit'] ?? false,

      playCount: json['playCount'] ?? 0,

      playCountWeek:
          json['playCountWeek'] ?? 0,

      status: json['status'] ?? '',

      scheduledAt:
          _parseDate(json['scheduledAt']),

      publishedAt:
          _parseDate(json['publishedAt']),

      createdAt:
          _parseDate(json['createdAt']),

      updatedAt:
          _parseDate(json['updatedAt']),

      isFeatured:
          json['isFeatured'] ?? false,

      isTrending:
          json['isTrending'] ?? false,

      trendDirection:
          json['trendDirection'],

      likeCount:
          json['likeCount'] ?? 0,

      isLiked:
          json['isLiked'] ?? false,

      version:
          json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,

      'ownerId': ownerId,
      'submittedStatus': submittedStatus,

      'submittedScheduledAt':
          submittedScheduledAt?.toIso8601String(),

      'submittedAt':
          submittedAt?.toIso8601String(),

      'rejectionReason': rejectionReason,
      'reviewedBy': reviewedBy,

      'reviewedAt':
          reviewedAt?.toIso8601String(),

      'title': title,
      'artist': artist,
      'album': album,

      'genre': genre.toJson(),

      'coverUrl': coverUrl,
      'coverKey': coverKey,
      'audioKey': audioKey,

      'durationMs': durationMs,

      'hlsMasterUrl': hlsMasterUrl,
      'transcodeStatus': transcodeStatus,

      'explicit': explicit,

      'playCount': playCount,
      'playCountWeek': playCountWeek,

      'status': status,

      'scheduledAt':
          scheduledAt?.toIso8601String(),

      'publishedAt':
          publishedAt?.toIso8601String(),

      'createdAt':
          createdAt?.toIso8601String(),

      'updatedAt':
          updatedAt?.toIso8601String(),

      'isFeatured': isFeatured,
      'isTrending': isTrending,

      'trendDirection': trendDirection,

      'likeCount': likeCount,
      'isLiked': isLiked,

      '__v': version,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class GenreModel {
  final String id;
  final String name;

  GenreModel({
    required this.id,
    required this.name,
  });

  factory GenreModel.fromJson(Map<String, dynamic> json) {
    return GenreModel(
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

class MetadataModel {
  final String duration;

  MetadataModel({
    required this.duration,
  });

  factory MetadataModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return MetadataModel(
      duration: json['duration'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
    };
  }
}