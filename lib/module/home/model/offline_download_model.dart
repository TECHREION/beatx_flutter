/// One file of a download: the item itself, or one chapter of an audiobook.
class DownloadGrantFile {
  const DownloadGrantFile({
    required this.contentId,
    required this.url,
    this.title = '',
    this.format = '',
    this.durationMs,
    this.trackNumber = 0,
  });

  final String contentId;

  /// Works for one hour.
  final String url;
  final String title;
  final String format;
  final int? durationMs;
  final int trackNumber;

  factory DownloadGrantFile.fromJson(Map json) => DownloadGrantFile(
    contentId: (json['contentId'] ?? '').toString(),
    url: (json['url'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    format: (json['format'] ?? '').toString(),
    durationMs: (json['durationMs'] as num?)?.toInt(),
    trackNumber: (json['trackNumber'] as num?)?.toInt() ?? 0,
  );
}

/// What `POST /downloads` answers: the server record and signed links to the
/// files. A song, episode or video has one file; an audiobook one per
/// chapter, in order.
class SongDownloadGrant {
  const SongDownloadGrant({
    required this.downloadId,
    required this.url,
    this.format = '',
    this.durationMs,
    this.files = const [],
  });

  /// Every file, in order. [url], [format] and [durationMs] are the first's.
  final List<DownloadGrantFile> files;

  final String downloadId;

  /// Works for one hour.
  final String url;
  final String format;
  final int? durationMs;

  factory SongDownloadGrant.fromJson(Map<String, dynamic> json) {
    final download = json['download'];
    final files = json['files'];
    final parsed = files is List
        ? files.whereType<Map>().map(DownloadGrantFile.fromJson).toList()
        : const <DownloadGrantFile>[];
    final file = files is List && files.isNotEmpty && files.first is Map
        ? files.first as Map
        : const {};

    return SongDownloadGrant(
      downloadId: download is Map ? (download['_id'] ?? '').toString() : '',
      url: (file['url'] ?? '').toString(),
      format: (file['format'] ?? '').toString(),
      durationMs: (file['durationMs'] as num?)?.toInt(),
      files: parsed,
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
