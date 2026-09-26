/// How far the signed-in user has listened to one song.
///
/// The same shape arrives from two places: the `userProgress` field on a song
/// details response, and the body returned when a position is saved.
class SaveProgressModel {
  final String id;
  final String songId;
  final String userId;
  final bool completed;
  final double percentComplete;
  final int positionMs;
  final int playCount;
  final DateTime? lastPlayedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SaveProgressModel({
    this.id = '',
    this.songId = '',
    this.userId = '',
    this.completed = false,
    this.percentComplete = 0,
    this.positionMs = 0,
    this.playCount = 0,
    this.lastPlayedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SaveProgressModel.fromJson(Map<String, dynamic> json) {
    return SaveProgressModel(
      id: json['_id']?.toString() ?? '',
      songId: json['songId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      completed: json['completed'] == true,
      percentComplete: (json['percentComplete'] as num?)?.toDouble() ?? 0,
      positionMs: (json['positionMs'] as num?)?.toInt() ?? 0,
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      lastPlayedAt: _parseDate(json['lastPlayedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'songId': songId,
      'userId': userId,
      'completed': completed,
      'percentComplete': percentComplete,
      'positionMs': positionMs,
      'playCount': playCount,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Where playback should pick up, measured against [durationMs].
  ///
  /// A finished song — or one stopped in its last seconds — starts over
  /// rather than resuming at the very end.
  Duration resumePosition(int durationMs) {
    if (completed || positionMs <= 0) return Duration.zero;
    if (durationMs > 0 && positionMs >= durationMs - 1000) return Duration.zero;
    return Duration(milliseconds: positionMs);
  }
}
