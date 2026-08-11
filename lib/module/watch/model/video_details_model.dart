class VideoDetailsModel {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String coverKey;
  final Genre genre;
  final Owner ownerId;
  final String sourceKey;
  final int durationMs;
  final String? hlsMasterUrl;
  final String transcodeStatus;
  final int playCount;
  final int likeCount;
  final int playCountWeek;
  final bool isFeatured;
  final bool isTrending;
  final String trendDirection;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int version;
  final bool isLiked;

  VideoDetailsModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.coverKey,
    required this.genre,
    required this.ownerId,
    required this.sourceKey,
    required this.durationMs,
    this.hlsMasterUrl,
    required this.transcodeStatus,
    required this.playCount,
    required this.likeCount,
    required this.playCountWeek,
    required this.isFeatured,
    required this.isTrending,
    required this.trendDirection,
    required this.status,
    this.scheduledAt,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    required this.version,
    required this.isLiked,
  });

  factory VideoDetailsModel.fromJson(Map<String, dynamic> json) {
    return VideoDetailsModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      coverKey: json['coverKey'] ?? '',
      genre: Genre.fromJson(json['genre'] ?? {}),
      ownerId: Owner.fromJson(json['ownerId'] ?? {}),
      sourceKey: json['sourceKey'] ?? '',
      durationMs: json['durationMs'] ?? 0,
      hlsMasterUrl: json['hlsMasterUrl'],
      transcodeStatus: json['transcodeStatus'] ?? '',
      playCount: json['playCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      playCountWeek: json['playCountWeek'] ?? 0,
      isFeatured: json['isFeatured'] ?? false,
      isTrending: json['isTrending'] ?? false,
      trendDirection: json['trendDirection'] ?? '',
      status: json['status'] ?? '',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : null,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      version: json['__v'] ?? 0,
      isLiked: json['isLiked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'coverKey': coverKey,
      'genre': genre.toJson(),
      'ownerId': ownerId.toJson(),
      'sourceKey': sourceKey,
      'durationMs': durationMs,
      'hlsMasterUrl': hlsMasterUrl,
      'transcodeStatus': transcodeStatus,
      'playCount': playCount,
      'likeCount': likeCount,
      'playCountWeek': playCountWeek,
      'isFeatured': isFeatured,
      'isTrending': isTrending,
      'trendDirection': trendDirection,
      'status': status,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': version,
      'isLiked': isLiked,
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

class Owner {
  final String id;
  final String name;

  Owner({
    required this.id,
    required this.name,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
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