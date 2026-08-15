class EpisodeDetailsData {
  final EpisodeDetails episode;
  final UserProgress? userProgress;

  EpisodeDetailsData({
    required this.episode,
    this.userProgress,
  });

  factory EpisodeDetailsData.fromJson(Map<String, dynamic> json) {
    return EpisodeDetailsData(
      episode: EpisodeDetails.fromJson(json['episode'] ?? {}),
      userProgress: json['userProgress'] != null
          ? UserProgress.fromJson(json['userProgress'])
          : null,
    );
  }
}

class EpisodeDetails {
  final String id;
  final PodcastInfo podcastId;
  final int episodeNumber;
  final int seasonNumber;
  final String title;
  final String description;
  final String? coverUrl;
  final String? coverKey;
  final String? audioKey;
  final int durationMs;
  final String? hlsMasterUrl;
  final String transcodeStatus;
  final String? transcript;
  final int playCount;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int version;

  EpisodeDetails({
    required this.id,
    required this.podcastId,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.title,
    required this.description,
    this.coverUrl,
    this.coverKey,
    this.audioKey,
    required this.durationMs,
    this.hlsMasterUrl,
    required this.transcodeStatus,
    this.transcript,
    required this.playCount,
    required this.status,
    this.scheduledAt,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    required this.version,
  });

  factory EpisodeDetails.fromJson(Map<String, dynamic> json) {
    return EpisodeDetails(
      id: json['_id'] ?? '',
      podcastId: PodcastInfo.fromJson(json['podcastId'] ?? {}),
      episodeNumber: json['episodeNumber'] ?? 0,
      seasonNumber: json['seasonNumber'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverUrl: json['coverUrl'],
      coverKey: json['coverKey'],
      audioKey: json['audioKey'],
      durationMs: json['durationMs'] ?? 0,
      hlsMasterUrl: json['hlsMasterUrl'],
      transcodeStatus: json['transcodeStatus'] ?? '',
      transcript: json['transcript'],
      playCount: json['playCount'] ?? 0,
      status: json['status'] ?? '',
      scheduledAt: DateTime.tryParse(json['scheduledAt'] ?? ''),
      publishedAt: DateTime.tryParse(json['publishedAt'] ?? ''),
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      version: json['__v'] ?? 0,
    );
  }
}

class PodcastInfo {
  final String id;
  final String title;
  final String? coverUrl;
  final String genre;
  final String ownerId;

  PodcastInfo({
    required this.id,
    required this.title,
    this.coverUrl,
    required this.genre,
    required this.ownerId,
  });

  factory PodcastInfo.fromJson(Map<String, dynamic> json) {
    return PodcastInfo(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      coverUrl: json['coverUrl'],
      genre: json['genre'] ?? '',
      ownerId: json['ownerId'] ?? '',
    );
  }
}

class UserProgress {
  final String id;
  final bool completed;
  final double percentComplete;
  final int positionMs;

  UserProgress({
    required this.id,
    required this.completed,
    required this.percentComplete,
    required this.positionMs,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      id: json['_id'] ?? '',
      completed: json['completed'] ?? false,
      percentComplete: (json['percentComplete'] ?? 0).toDouble(),
      positionMs: json['positionMs'] ?? 0,
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

