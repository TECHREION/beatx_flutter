class EpisodeModel {
  const EpisodeModel({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.image,
    this.isNew = false,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String image;
  final bool isNew;
}
