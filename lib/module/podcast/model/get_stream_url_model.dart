class EpisodeStreamData {
  final String streamUrl;
  final int durationMs;
  final String streamType;

  EpisodeStreamData({
    required this.streamUrl,
    required this.durationMs,
    required this.streamType,
  });

  factory EpisodeStreamData.fromJson(Map<String, dynamic> json) {
    return EpisodeStreamData(
      streamUrl: json['streamUrl'] ?? '',
      durationMs: json['durationMs'] ?? 0,
      streamType: json['streamType'] ?? '',
    );
  }
}

class Metadata {
  final String duration;

  Metadata({required this.duration});

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(duration: json['duration'] ?? '');
  }
}
