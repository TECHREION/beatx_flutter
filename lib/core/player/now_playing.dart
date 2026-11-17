import 'package:get/get.dart';

/// What kind of collection the shared player is playing from.
enum NowPlayingKind {
  /// A song, from a list such as Liked Songs or an artist's songs.
  song,

  /// A chapter of an audiobook.
  chapter,

  /// An episode of a podcast.
  episode,
}

/// One playable item of the collection: a chapter or an episode.
class NowPlayingEntry {
  const NowPlayingEntry({
    required this.id,
    required this.title,
    required this.label,
    this.group = '',
    this.durationMs = 0,
  });

  final String id;
  final String title;

  /// Where it sits in the collection: "Chapter 3", "S2 · E5".
  final String label;

  /// A heading the entries are grouped under, such as "Season 2"; '' for
  /// none.
  final String group;

  final int durationMs;
}

/// How a suggested collection relates to the one playing.
enum SeriesRelation {
  /// Comes before it in the series.
  prequel,

  /// Comes after it in the series.
  sequel,

  /// Not part of the series, but similar (same genre).
  related,
}

/// Another book (or show) offered alongside the one playing.
class SeriesEntry {
  const SeriesEntry({
    required this.id,
    required this.title,
    required this.relation,
    this.subtitle = '',
    this.coverUrl = '',
  });

  final String id;
  final String title;
  final SeriesRelation relation;

  /// The author, or a short description.
  final String subtitle;
  final String coverUrl;
}

/// Tells the player what it is playing *from*, so the user can see which
/// chapter of which book (or which episode of which show) is on, browse the
/// rest of it, and find what comes next in the series.
///
/// The module that starts playback builds one and hands it to
/// [PlayerController.setNowPlaying] before calling `play`. It is dropped as
/// soon as something outside it starts playing.
class NowPlayingContext {
  NowPlayingContext({
    required this.kind,
    required this.collectionId,
    required this.collectionTitle,
    this.collectionSubtitle = '',
    this.collectionCoverUrl = '',
    List<NowPlayingEntry> entries = const [],
    this.playEntry,
    this.openSeries,
    this.playSeries,
  }) : entries = entries.obs;

  final NowPlayingKind kind;

  /// The book, show or list id.
  final String collectionId;

  /// The book title, show name or list name ("Liked Songs").
  final String collectionTitle;

  /// The author or host.
  final String collectionSubtitle;
  final String collectionCoverUrl;

  /// Every chapter or episode, in listening order. Observable, since a show's
  /// episode list may arrive after playback has started.
  final RxList<NowPlayingEntry> entries;

  /// Earlier and later books in the series ([SeriesRelation.prequel] /
  /// [SeriesRelation.sequel]), filled in once loaded.
  final series = <SeriesEntry>[].obs;

  /// Similar collections to try next.
  final suggestions = <SeriesEntry>[].obs;

  /// Plays one of [entries].
  final Future<void> Function(String entryId)? playEntry;

  /// Opens a suggested collection's page.
  final void Function(SeriesEntry entry)? openSeries;

  /// Starts listening to a suggested collection straight away.
  final Future<void> Function(SeriesEntry entry)? playSeries;

  bool contains(String entryId) => entries.any((e) => e.id == entryId);

  int indexOf(String entryId) => entries.indexWhere((e) => e.id == entryId);

  NowPlayingEntry? entry(String entryId) =>
      entries.firstWhereOrNull((e) => e.id == entryId);

  /// The book that follows this one in the series, if there is one.
  SeriesEntry? get sequel =>
      series.firstWhereOrNull((s) => s.relation == SeriesRelation.sequel);

  SeriesEntry? get prequel =>
      series.firstWhereOrNull((s) => s.relation == SeriesRelation.prequel);

  /// The small caps line over the collection name in the player.
  String get heading => switch (kind) {
    NowPlayingKind.chapter => 'PLAYING FROM AUDIOBOOK',
    NowPlayingKind.episode => 'PLAYING FROM PODCAST',
    NowPlayingKind.song => 'PLAYING FROM',
  };

  /// What the list of [entries] is called.
  String get listName => switch (kind) {
    NowPlayingKind.chapter => 'Chapters',
    NowPlayingKind.episode => 'Episodes',
    NowPlayingKind.song => 'Queue',
  };

  /// "Chapter 3 of 12", "S2 · E5 · 4 of 20"; '' when [entryId] is not one of
  /// [entries].
  String position(String entryId) {
    final i = indexOf(entryId);
    if (i < 0) return '';
    final label = entries[i].label;
    return switch (kind) {
      NowPlayingKind.chapter => '$label of ${entries.length}',
      NowPlayingKind.episode => label,
      NowPlayingKind.song => '${i + 1} of ${entries.length}',
    };
  }
}
