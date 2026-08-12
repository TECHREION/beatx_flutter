class GenreModel {
  const GenreModel({required this.title, required this.image});

  final String title;
  final String image;
}

class RecentTrackModel {
  const RecentTrackModel({
    required this.image,
    required this.title,
    required this.artist,
    required this.duration,
  });

  final String image;
  final String title;
  final String artist;
  final String duration;
}
