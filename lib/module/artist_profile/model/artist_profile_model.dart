class ArtistProductModel {
  const ArtistProductModel({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.currency,
    required this.coinPrice,
    required this.image,
  });

  final String title;
  final String subtitle;
  final String price;
  final String currency;
  final int coinPrice;
  final String image;
}

class ArtistSongModel {
  const ArtistSongModel({
    required this.rank,
    required this.title,
    required this.plays,
    required this.cover,
  });

  final String rank;
  final String title;
  final String plays;
  final String cover;
}

class AlbumModel {
  const AlbumModel({
    required this.title,
    required this.type,
    required this.year,
    required this.cover,
  });

  final String title;
  final String type;
  final String year;
  final String cover;
}

class TourDateModel {
  const TourDateModel({
    required this.month,
    required this.day,
    required this.venue,
    required this.location,
    required this.isSoldOut,
  });

  final String month;
  final String day;
  final String venue;
  final String location;
  final bool isSoldOut;
}

class SimilarArtistModel {
  const SimilarArtistModel({required this.name, required this.image});

  final String name;
  final String image;
}

class ArtistProfileModel {
  const ArtistProfileModel({
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
  });

  final String name;
  final String rank;
  final String monthlyListeners;
  final String bio;
  final String heroImage;
  final List<ArtistSongModel> songs;
  final String playlistTitle;
  final String playlistCover;
  final List<AlbumModel> albums;
  final List<TourDateModel> tourDates;
  final List<SimilarArtistModel> similarArtists;
  final List<ArtistProductModel> products;
}
