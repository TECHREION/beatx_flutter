class AudiobookModel {
  const AudiobookModel({
    required this.title,
    required this.author,
    required this.narrator,
    required this.cover,
    required this.chapter,
    required this.progress,
    required this.remaining,
    required this.audioAsset,
  });

  final String title;
  final String author;
  final String narrator;
  final String cover;
  final String chapter;
  final double progress;
  final String remaining;
  final String audioAsset;
}
