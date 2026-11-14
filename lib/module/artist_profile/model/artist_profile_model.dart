import '../../shop/model/event_model.dart';

/// Image fields below hold either a network URL from the API or a bundled
/// asset path; an empty string means "no image" and shows a placeholder.

class ArtistProductModel {
  const ArtistProductModel({
    this.id = '',
    required this.title,
    required this.subtitle,
    required this.price,
    required this.currency,
    required this.coinPrice,
    required this.image,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Ready to show (the API's `priceDisplay`, e.g. `৳29.99`).
  final String price;
  final String currency;
  final int coinPrice;
  final String image;

  /// A row of `GET /products?ownerId=`.
  factory ArtistProductModel.fromJson(Map<String, dynamic> json) {
    final images = json['images'];
    final first = images is List && images.isNotEmpty ? images.first : null;
    final image = first is Map
        ? (first['url'] ?? '').toString()
        : (first ?? '').toString();
    final category = (json['category'] ?? '').toString();
    return ArtistProductModel(
      id: _id(json),
      title: (json['title'] ?? '').toString(),
      subtitle: category.isEmpty
          ? ''
          : category[0].toUpperCase() + category.substring(1),
      price: (json['priceDisplay'] ?? '').toString(),
      currency: '',
      coinPrice: _int(json['coinReward']),
      image: image,
    );
  }
}

class ArtistSongModel {
  const ArtistSongModel({
    this.id = '',
    required this.rank,
    required this.title,
    required this.plays,
    required this.cover,
  });

  final String id;
  final String rank;
  final String title;
  final String plays;
  final String cover;

  /// A row of `GET /songs?ownerId=&sort=plays`, at position [index].
  factory ArtistSongModel.fromJson(Map<String, dynamic> json, int index) =>
      ArtistSongModel(
        id: _id(json),
        rank: (index + 1).toString().padLeft(2, '0'),
        title: (json['title'] ?? '').toString(),
        plays: '${compactCount(_int(json['playCount']))} plays',
        cover: (json['coverUrl'] ?? '').toString(),
      );
}

class AlbumModel {
  const AlbumModel({
    this.id = '',
    required this.title,
    required this.type,
    required this.year,
    required this.cover,
  });

  final String id;
  final String title;
  final String type;
  final String year;
  final String cover;

  /// A row of `GET /albums?ownerId=`.
  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    final type = (json['releaseType'] ?? 'album').toString();
    final date = DateTime.tryParse(
      (json['releaseDate'] ?? json['publishedAt'] ?? json['createdAt'] ?? '')
          .toString(),
    );
    return AlbumModel(
      id: _id(json),
      title: (json['title'] ?? '').toString(),
      type: type == 'ep'
          ? 'EP'
          : type.isEmpty
          ? 'Album'
          : type[0].toUpperCase() + type.substring(1),
      year: date == null ? '' : '${date.year}',
      cover: (json['coverUrl'] ?? '').toString(),
    );
  }
}

class TourDateModel {
  const TourDateModel({
    required this.month,
    required this.day,
    required this.venue,
    required this.location,
    required this.isSoldOut,
    this.event,
  });

  final String month;
  final String day;
  final String venue;
  final String location;
  final bool isSoldOut;

  /// The event behind this row, for opening ticket checkout.
  final ShopEvent? event;

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  /// A row of `GET /events?ownerId=&upcoming=true`.
  factory TourDateModel.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(
      (json['eventDate'] ?? '').toString(),
    )?.toLocal();
    final venue = (json['venue'] ?? '').toString();
    final city = (json['city'] ?? '').toString();
    return TourDateModel(
      month: date == null ? '' : _months[date.month - 1],
      day: date == null ? '' : date.day.toString().padLeft(2, '0'),
      venue: venue.isNotEmpty ? venue : (json['title'] ?? '').toString(),
      location: city,
      isSoldOut: json['soldOut'] == true || json['availability'] == 'sold_out',
      event: ShopEvent.fromJson(json),
    );
  }
}

class SimilarArtistModel {
  const SimilarArtistModel({
    this.id = '',
    required this.name,
    required this.image,
  });

  final String id;
  final String name;
  final String image;

  /// A row of `GET /artists/:id/related`.
  factory SimilarArtistModel.fromJson(Map<String, dynamic> json) {
    final stage = (json['stageName'] ?? '').toString().trim();
    return SimilarArtistModel(
      id: _id(json),
      name: stage.isNotEmpty ? stage : (json['name'] ?? '').toString(),
      image: (json['avatar'] ?? '').toString(),
    );
  }
}

class ArtistProfileModel {
  const ArtistProfileModel({
    this.id = '',
    required this.name,
    required this.rank,
    required this.monthlyListeners,
    required this.bio,
    required this.heroImage,
    required this.songs,
    required this.playlistTitle,
    required this.playlistCover,
    required this.albums,
    required this.tourDates,
    required this.similarArtists,
    required this.products,
    this.avatar = '',
    this.isVerified = false,
    this.isFollowing = false,
    this.followerCount = 0,
    this.genres = const [],
  });

  final String id;
  final String name;

  /// A short badge in the hero corner; empty hides it.
  final String rank;
  final String monthlyListeners;
  final String bio;
  final String heroImage;
  final String avatar;
  final bool isVerified;
  final bool isFollowing;
  final int followerCount;
  final List<String> genres;
  final List<ArtistSongModel> songs;
  final String playlistTitle;
  final String playlistCover;
  final List<AlbumModel> albums;
  final List<TourDateModel> tourDates;
  final List<SimilarArtistModel> similarArtists;
  final List<ArtistProductModel> products;

  /// Builds the page from `GET /artists/:id` plus the per-artist lists.
  factory ArtistProfileModel.fromJson(
    Map<String, dynamic> json, {
    List<ArtistSongModel> songs = const [],
    List<AlbumModel> albums = const [],
    List<TourDateModel> tourDates = const [],
    List<SimilarArtistModel> similarArtists = const [],
    List<ArtistProductModel> products = const [],
  }) {
    final stage = (json['stageName'] ?? '').toString().trim();
    final name = stage.isNotEmpty ? stage : (json['name'] ?? '').toString();
    final avatar = (json['avatar'] ?? '').toString();
    final cover = (json['coverImageUrl'] ?? '').toString();
    final hero = cover.isNotEmpty ? cover : avatar;
    final genres = json['genres'] is List
        ? (json['genres'] as List)
              .map((g) => g is Map ? (g['name'] ?? '').toString() : '$g')
              .where((g) => g.isNotEmpty)
              .toList()
        : const <String>[];
    final bio = (json['fullBio'] ?? json['bio'] ?? '').toString();

    return ArtistProfileModel(
      id: _id(json),
      name: name,
      rank: json['isVerified'] == true ? 'Verified' : '',
      monthlyListeners:
          '${compactCount(_int(json['monthlyListeners']))} monthly listeners'
          ' · ${compactCount(_int(json['followerCount']))} followers',
      bio: bio.isNotEmpty ? bio : genres.join(' · '),
      heroImage: hero,
      avatar: avatar,
      isVerified: json['isVerified'] == true,
      isFollowing: json['isFollowing'] == true,
      followerCount: _int(json['followerCount']),
      genres: genres,
      songs: songs,
      playlistTitle: 'The Best of $name',
      playlistCover: songs.isNotEmpty && songs.first.cover.isNotEmpty
          ? songs.first.cover
          : hero,
      albums: albums,
      tourDates: tourDates,
      similarArtists: similarArtists,
      products: products,
    );
  }

  ArtistProfileModel copyWith({bool? isFollowing, int? followerCount}) {
    final following = isFollowing ?? this.isFollowing;
    final followers = followerCount ?? this.followerCount;
    return ArtistProfileModel(
      id: id,
      name: name,
      rank: rank,
      monthlyListeners: monthlyListeners.replaceFirst(
        RegExp(r'· [^·]* followers$'),
        '· ${compactCount(followers)} followers',
      ),
      bio: bio,
      heroImage: heroImage,
      avatar: avatar,
      isVerified: isVerified,
      isFollowing: following,
      followerCount: followers,
      genres: genres,
      songs: songs,
      playlistTitle: playlistTitle,
      playlistCover: playlistCover,
      albums: albums,
      tourDates: tourDates,
      similarArtists: similarArtists,
      products: products,
    );
  }
}

/// 1234 → `1.2K`, 1200000 → `1.2M`.
String compactCount(int value) {
  String trim(double v) {
    final text = v.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }

  if (value >= 1000000) return '${trim(value / 1000000)}M';
  if (value >= 1000) return '${trim(value / 1000)}K';
  return '$value';
}

String _id(Map<String, dynamic> json) =>
    (json['_id'] ?? json['id'] ?? '').toString();

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('${value ?? ''}') ?? 0;
