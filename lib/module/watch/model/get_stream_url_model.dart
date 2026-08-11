class VideoStreamUrlModel {
  final String streamUrl;
  final int durationMs;
  final String streamType;

  VideoStreamUrlModel({
    required this.streamUrl,
    required this.durationMs,
    required this.streamType,
  });

  factory VideoStreamUrlModel.fromJson(Map<String, dynamic> json) {
    return VideoStreamUrlModel(
      streamUrl: json['streamUrl'] ?? '',
      durationMs: json['durationMs'] ?? 0,
      streamType: json['streamType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streamUrl': streamUrl,
      'durationMs': durationMs,
      'streamType': streamType,
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