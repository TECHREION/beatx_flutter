/// A song saved to the device for offline playback.
///
/// Only file *names* are stored, never absolute paths: on iOS the app's
/// container moves to a new path on every app update, so a stored absolute
/// path would stop resolving. [SongDownloadService] joins the names onto the
/// downloads folder at runtime.
class DownloadedSong {
  final String id;
  final String title;
  final String artist;

  /// The online cover, kept so the row can still show art if the local copy
  /// of the cover could not be saved.
  final String artworkUrl;

  /// The audio file inside the downloads folder, e.g. `6aa4….flac`.
  final String fileName;

  /// The cover inside the downloads folder, or empty when none was saved.
  final String coverFileName;

  final int fileSize;
  final int durationMs;
  final String genre;
  final DateTime downloadedAt;

  const DownloadedSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.fileName,
    this.coverFileName = '',
    required this.fileSize,
    this.durationMs = 0,
    this.genre = '',
    required this.downloadedAt,
  });

  factory DownloadedSong.fromJson(Map<String, dynamic> json) {
    return DownloadedSong(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      artist: json['artist']?.toString() ?? '',
      artworkUrl: json['artworkUrl']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      coverFileName: json['coverFileName']?.toString() ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      genre: json['genre']?.toString() ?? '',
      downloadedAt:
          DateTime.tryParse(json['downloadedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artworkUrl': artworkUrl,
      'fileName': fileName,
      'coverFileName': coverFileName,
      'fileSize': fileSize,
      'durationMs': durationMs,
      'genre': genre,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }
}
