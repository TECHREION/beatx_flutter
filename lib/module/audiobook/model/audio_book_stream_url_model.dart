class AudioBookStreamUrlModel {
  final String streamUrl;
  final int durationMs;
  final String streamType;

  AudioBookStreamUrlModel({
    required this.streamUrl,
    required this.durationMs,
    required this.streamType,
  });

  factory AudioBookStreamUrlModel.fromJson(Map<String, dynamic> json) {
    return AudioBookStreamUrlModel(
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

class ResponseMetadata {
  final String duration;

  ResponseMetadata({
    required this.duration,
  });

  factory ResponseMetadata.fromJson(Map<String, dynamic> json) {
    return ResponseMetadata(
      duration: json['duration'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
    };
  }
}