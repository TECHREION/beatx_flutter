import 'listem_miusic_detalis_model.dart';

/// One entry of `GET /songs/recently-played`: the song, plus when the user
/// last played it.
///
/// The nested song is a trimmed view of a full song — the payload carries the
/// id, title, artist, cover, length, status and like flag and nothing else —
/// so the fields [ListenMusicDetailsModel] fills from elsewhere in the API
/// (genre, counts, timestamps) come back at their defaults here.
class RecentlyPlayedModel {
  RecentlyPlayedModel({required this.song, this.lastPlayedAt});

  final ListenMusicDetailsModel song;
  final DateTime? lastPlayedAt;

  factory RecentlyPlayedModel.fromJson(Map<String, dynamic> json) {
    final song = json['song'] is Map
        ? Map<String, dynamic>.from(json['song'] as Map)
        : <String, dynamic>{};

    return RecentlyPlayedModel(
      song: ListenMusicDetailsModel.fromJson(song),
      lastPlayedAt: DateTime.tryParse(json['lastPlayedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'song': song.toJson(),
    'lastPlayedAt': lastPlayedAt?.toIso8601String(),
  };
}

/// One page of history, with the counters the list needs to ask for the next.
class RecentlyPlayedPage {
  const RecentlyPlayedPage({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  final List<RecentlyPlayedModel> items;

  /// How many entries the backend holds in total, across every page.
  final int total;
  final int page;
  final int limit;

  factory RecentlyPlayedPage.fromJson(Map<String, dynamic> json) {
    // `data` is the envelope's inner list — `{ data: [...], total, page,
    // limit }` — but tolerate a bare list in case the shape is flattened.
    final raw = json['data'];
    final entries = raw is List ? raw : const [];

    final items = entries
        .whereType<Map>()
        .map(
          (item) =>
              RecentlyPlayedModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    return RecentlyPlayedPage(
      items: items,
      // Falls back to what came back, so a response that carries no counter
      // still reports the entries it holds rather than none.
      total: _asInt(json['total'], fallback: items.length),
      page: _asInt(json['page'], fallback: 1),
      limit: _asInt(json['limit'], fallback: 20),
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
