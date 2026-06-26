class MusicVideoModel {
  const MusicVideoModel({
    required this.title,
    required this.artist,
    required this.meta,
    required this.duration,
    required this.image,
  });

  final String title;
  final String artist;
  final String meta;
  final String duration;
  final String image;
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