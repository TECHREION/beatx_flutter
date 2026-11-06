/// What `POST /downloads` answers for a song: its server record and a signed
/// link to the file. A song is the one content type with exactly one file.
class SongDownloadGrant {
  const SongDownloadGrant({
    required this.downloadId,
    required this.url,
    this.format = '',
    this.durationMs,
  });

  final String downloadId;

  /// Works for one hour.
  final String url;
  final String format;
  final int? durationMs;

  factory SongDownloadGrant.fromJson(Map<String, dynamic> json) {
    final download = json['download'];
    final files = json['files'];
    final file = files is List && files.isNotEmpty && files.first is Map
        ? files.first as Map
        : const {};

    return SongDownloadGrant(
      downloadId: download is Map ? (download['_id'] ?? '').toString() : '',
      url: (file['url'] ?? '').toString(),
      format: (file['format'] ?? '').toString(),
      durationMs: (file['durationMs'] as num?)?.toInt(),
    );
  }
}

/// What `POST /downloads/sync` answers.
class DownloadSyncResult {
  const DownloadSyncResult({
    this.keep = const [],
    this.remove = const [],
    this.validUntil,
  });

  final List<String> keep;

  /// Downloads whose files must be deleted from this device.
  final List<String> remove;

  /// Past this moment without another sync, the saved songs must be hidden.
  final DateTime? validUntil;

  factory DownloadSyncResult.fromJson(Map<String, dynamic> json) {
    return DownloadSyncResult(
      keep: _ids(json['keep']),
      remove: _ids(json['remove']),
      validUntil: DateTime.tryParse((json['validUntil'] ?? '').toString()),
    );
  }

  static List<String> _ids(Object? value) => value is List
      ? value.map((id) => id.toString()).toList(growable: false)
      : const [];
}
