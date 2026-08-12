class SongStreamUrlModel {
  final String streamUrl;
  final int durationMs;
  final String streamType;

  SongStreamUrlModel({
    required this.streamUrl,
    required this.durationMs,
    required this.streamType,
  });

  factory SongStreamUrlModel.fromJson(Map<String, dynamic> json) {
    return SongStreamUrlModel(
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

class MetadataModel {
  final String duration;

  MetadataModel({
    required this.duration,
  });

  factory MetadataModel.fromJson(Map<String, dynamic> json) {
    return MetadataModel(
      duration: json['duration'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
    };
  }
}