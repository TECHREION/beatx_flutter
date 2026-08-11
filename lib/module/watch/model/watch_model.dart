class MusicVideoModel {
  const MusicVideoModel({
    required this.title,
    required this.artist,
    required this.meta,
    required this.duration,
    required this.image,
    required this.videoAsset,
  });

  final String title;
  final String artist;
  final String meta;
  final String duration;
  final String image;
  final String videoAsset;
}

class MusicModel {
  final String title;
  final String artist;
  final String image;
  final String duration;
  final String description;
  final String views;

  MusicModel({
    required this.title,
    required this.artist,
    required this.image,
    required this.duration,
    required this.description,
    required this.views,
  });
}

class HomeData {
  final List<VideoModel> featured;
  final List<TopCategoryModel> topCategories;
  final TopCreatorsModel topCreators;
  final List<VideoModel> recent;

  HomeData({
    required this.featured,
    required this.topCategories,
    required this.topCreators,
    required this.recent,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      featured: (json['featured'] as List? ?? [])
          .map((e) => VideoModel.fromJson(e))
          .toList(),
      topCategories: (json['topCategories'] as List? ?? [])
          .map((e) => TopCategoryModel.fromJson(e))
          .toList(),
      topCreators: TopCreatorsModel.fromJson(json['topCreators'] ?? {}),
      recent: (json['recent'] as List? ?? [])
          .map((e) => VideoModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'featured': featured.map((e) => e.toJson()).toList(),
      'topCategories': topCategories.map((e) => e.toJson()).toList(),
      'topCreators': topCreators.toJson(),
      'recent': recent.map((e) => e.toJson()).toList(),
    };
  }
}

class VideoModel {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final GenreModel genre;
  final OwnerModel ownerId;
  final int durationMs;
  final int playCount;
  final String? publishedAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.genre,
    required this.ownerId,
    required this.durationMs,
    required this.playCount,
    this.publishedAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      genre: GenreModel.fromJson(json['genre'] ?? {}),
      ownerId: OwnerModel.fromJson(json['ownerId'] ?? {}),
      durationMs: json['durationMs'] ?? 0,
      playCount: json['playCount'] ?? 0,
      publishedAt: json['publishedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'coverUrl': coverUrl,
      'genre': genre.toJson(),
      'ownerId': ownerId.toJson(),
      'durationMs': durationMs,
      'playCount': playCount,
      'publishedAt': publishedAt,
    };
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

class OwnerModel {
  final String id;
  final String name;

  OwnerModel({
    required this.id,
    required this.name,
  });

  factory OwnerModel.fromJson(Map<String, dynamic> json) {
    return OwnerModel(
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

class TopCategoryModel {
  final String genreId;
  final String name;
  final int videoCount;

  TopCategoryModel({
    required this.genreId,
    required this.name,
    required this.videoCount,
  });

  factory TopCategoryModel.fromJson(Map<String, dynamic> json) {
    return TopCategoryModel(
      genreId: json['genreId'] ?? '',
      name: json['name'] ?? '',
      videoCount: json['videoCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'genreId': genreId,
      'name': name,
      'videoCount': videoCount,
    };
  }
}

class TopCreatorsModel {
  final List<CreatorModel> data;
  final int total;
  final int page;
  final int limit;

  TopCreatorsModel({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory TopCreatorsModel.fromJson(Map<String, dynamic> json) {
    return TopCreatorsModel(
      data: (json['data'] as List? ?? [])
          .map((e) => CreatorModel.fromJson(e))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((e) => e.toJson()).toList(),
      'total': total,
      'page': page,
      'limit': limit,
    };
  }
}

class CreatorModel {
  final String id;
  final String name;
  final String? stageName;
  final String? artistAvatar;
  final bool isFollowing;

  CreatorModel({
    required this.id,
    required this.name,
    this.stageName,
    this.artistAvatar,
    required this.isFollowing,
  });

  factory CreatorModel.fromJson(Map<String, dynamic> json) {
    return CreatorModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      stageName: json['stageName'],
      artistAvatar: json['artistAvatar'],
      isFollowing: json['isFollowing'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'stageName': stageName,
      'artistAvatar': artistAvatar,
      'isFollowing': isFollowing,
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