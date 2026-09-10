/// How far the signed-in user has watched one video.
///
/// The same shape arrives from two places: the `userProgress` field on a video
/// details response, and the body returned when a position is saved.
class VideoProgressModel {
  final String id;
  final String videoId;
  final String userId;
  final bool completed;
  final double percentComplete;
  final int positionMs;
  final DateTime? lastWatchedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VideoProgressModel({
    this.id = '',
    this.videoId = '',
    this.userId = '',
    this.completed = false,
    this.percentComplete = 0,
    this.positionMs = 0,
    this.lastWatchedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory VideoProgressModel.fromJson(Map<String, dynamic> json) {
    return VideoProgressModel(
      id: json['_id']?.toString() ?? '',
      videoId: json['videoId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      completed: json['completed'] ?? false,
      percentComplete: (json['percentComplete'] as num?)?.toDouble() ?? 0,
      positionMs: (json['positionMs'] as num?)?.toInt() ?? 0,
      lastWatchedAt: _parseDate(json['lastWatchedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'videoId': videoId,
      'userId': userId,
      'completed': completed,
      'percentComplete': percentComplete,
      'positionMs': positionMs,
      'lastWatchedAt': lastWatchedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Where playback should pick up, measured against [durationMs].
  ///
  /// A finished video — or one stopped in its last seconds — starts over
  /// rather than resuming at the very end.
  Duration resumePosition(int durationMs) {
    if (completed || positionMs <= 0) return Duration.zero;
    if (durationMs > 0 && positionMs >= durationMs - 1000) return Duration.zero;
    return Duration(milliseconds: positionMs);
  }
}
