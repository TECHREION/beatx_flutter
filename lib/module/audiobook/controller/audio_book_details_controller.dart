import 'dart:async';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/common/widget/now_playing_sheet.dart';
import 'package:beatx_flutter/core/player/now_playing.dart';
import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/module/home/presentation/screens/audio_play_screen.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:get/get.dart';

import '../../../core/helpers/typedefs.dart';

import '../model/audio_book_details_model.dart';
import '../model/audiobook_model.dart' as home_model;
import '../presentation/screen/audiobook_detail_screen.dart';
import '../services/audio_book_interface.dart';
import '../services/audio_book_interface_impl.dart';
import 'audiobook_download_controller.dart';
import 'audiobook_like_controller.dart';
import 'liked_audiobooks_controller.dart';

class AudioBookDetailsController extends GetxController {
  final details = Rxn<AudiobookDetailsData>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isStreamLoading = false.obs;

  /// Whether the user has liked this book. Settled against
  /// `GET /audiobooks/liked` once the screen opens, since neither the details
  /// payload nor the home payload carries a per-user flag.
  final isLiked = false.obs;
  final isTogglingLike = false.obs;

  String? _loadedAudiobookId;

  /// The books before and after this one in its series, once loaded.
  final seriesBooks = <SeriesEntry>[].obs;

  /// Books in the same genre, to suggest after this one.
  final relatedBooks = <home_model.Audiobook>[].obs;

  /// What the player is told this book is, while one of its chapters plays.
  NowPlayingContext? _playing;

  AudioBookInterface _audioBookInterface() {
    if (!Get.isRegistered<AudioBookInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<AudioBookInterface>(
        AudioBookInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<AudioBookInterface>();
  }

  PlayerController _playerController() {
    if (!Get.isRegistered<PlayerController>()) {
      Get.put(PlayerController(), permanent: true);
    }
    return Get.find<PlayerController>();
  }

  Future<void>? _loading;

  Future<void> loadDetails(String audiobookId) async {
    if (audiobookId.isEmpty || _loadedAudiobookId == audiobookId) return;

    _loadedAudiobookId = audiobookId;
    await (_loading = _fetchDetails(audiobookId));
  }

  /// Completes once the details are here: joins a load still running, and
  /// tries again if the last one failed.
  Future<void> ensureLoaded(String audiobookId) async {
    await _loading;
    if (details.value == null && audiobookId.isNotEmpty) {
      _loadedAudiobookId = audiobookId;
      await (_loading = _fetchDetails(audiobookId));
    }
  }

  Future<void> _fetchDetails(String audiobookId) async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _audioBookInterface().audiobookDetails(audiobookId);
    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) => details.value = success.data,
    );
    isLoading.value = false;

    final book = details.value?.book;
    if (book != null) {
      unawaited(_loadSeries(book));
      unawaited(_loadRelated(audiobookId));
    }

    _settleLiked(audiobookId);
  }

  /// Reads the heart off the user's liked books, which is where the backend
  /// reports the like — the details payload has no per-user flag.
  Future<void> _settleLiked(String audiobookId) async {
    final liked = LikedAudiobooksController.instance;

    // The list is shared, so a fetch is only needed when nothing has asked
    // for it yet this run.
    if (!liked.hasLoaded.value) await liked.fetch();

    isLiked.value = liked.isLiked(audiobookId);
  }

  /// Likes the book, or unlikes it when it is already liked — the endpoint
  /// toggles, so both directions are the same call.
  Future<void> toggleLike() async {
    final audiobookId = details.value?.book?.id ?? _loadedAudiobookId ?? '';

    // Cleared ahead of the guards so a tap that does nothing does not leave
    // the caller looking at the previous attempt's error.
    errorMessage.value = '';
    if (audiobookId.isEmpty || isTogglingLike.value) return;

    isTogglingLike.value = true;

    final result = await _audioBookInterface().likeAudiobook(audiobookId);

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      // A backend that only acknowledges the call reports no flag, so fall
      // back to flipping what is on screen.
      final liked = success.data?.liked ?? !isLiked.value;

      isLiked.value = liked;
      LikedAudiobooksController.syncHearts(audiobookId, liked);
      LikedAudiobooksController.instance.fetch();
    });

    isTogglingLike.value = false;
  }

  /// Looks up the books this one links to as prequel/sequel. The link only
  /// carries an id, so each book's details are read for its title and cover.
  Future<void> _loadSeries(Book book) async {
    final links = book.seriesLinks;
    if (links.isEmpty) return;
    final found = await Future.wait(
      links.map((link) async {
        final result = await _audioBookInterface().audiobookDetails(
          link.audiobookId,
        );
        final other = result.fold((_) => null, (s) => s.data?.book);
        if (other == null) return null;
        return SeriesEntry(
          id: link.audiobookId,
          title: other.title ?? '',
          subtitle: other.author ?? '',
          coverUrl: other.coverUrl ?? '',
          relation: link.isSequel
              ? SeriesRelation.sequel
              : SeriesRelation.prequel,
        );
      }),
    );
    seriesBooks.assignAll(found.nonNulls);
    _playing?.series.assignAll(seriesBooks);
  }

  Future<void> _loadRelated(String audiobookId) async {
    final result = await _audioBookInterface().relatedAudiobooks(audiobookId);
    result.fold((_) => null, (success) {
      // A sequel is already offered as such; don't repeat it below.
      final inSeries = seriesBooks.map((b) => b.id).toSet();
      relatedBooks.assignAll(
        (success.data ?? const []).where((b) => !inSeries.contains(b.id)),
      );
      _playing?.suggestions.assignAll(relatedBooks.map(_suggestion));
    });
  }

  static SeriesEntry _suggestion(home_model.Audiobook book) => SeriesEntry(
    id: book.id,
    title: book.title,
    subtitle: book.author,
    coverUrl: book.coverUrl,
    relation: SeriesRelation.related,
  );

  /// The label a chapter goes by in the player: "Chapter 3".
  static String chapterLabel(Chapter chapter, int index) =>
      'Chapter ${chapter.chapterNumber ?? index + 1}';

  /// Whether [chapter] is the one the shared player is on.
  /// Always reads the player's track, so an Obx built on it has something to
  /// follow.
  bool isPlayingChapter(Chapter chapter) {
    final playing = _playerController().trackId.value;
    return chapter.id != null && playing == chapter.id;
  }

  /// Tells the player which book this is, its chapters, its series and what
  /// to suggest after it.
  NowPlayingContext _nowPlaying() {
    final book = details.value?.book;
    final chapters = details.value?.chapters ?? const <Chapter>[];
    final playing = NowPlayingContext(
      kind: NowPlayingKind.chapter,
      collectionId: book?.id ?? _loadedAudiobookId ?? '',
      collectionTitle: book?.title ?? '',
      collectionSubtitle: book?.author ?? '',
      collectionCoverUrl: book?.coverUrl ?? '',
      entries: [
        for (var i = 0; i < chapters.length; i++)
          if (chapters[i].id != null)
            NowPlayingEntry(
              id: chapters[i].id!,
              title: _chapterTitle(chapters[i], i),
              label: chapterLabel(chapters[i], i),
              durationMs: chapters[i].durationMs ?? 0,
            ),
      ],
      playEntry: (id) async {
        final chapter = chapters.firstWhereOrNull((c) => c.id == id);
        if (chapter != null) await playChapter(chapter, openPlayer: false);
      },
      openSeries: openBook,
      playSeries: listenToBook,
    );
    playing.series.assignAll(seriesBooks);
    playing.suggestions.assignAll(relatedBooks.map(_suggestion));
    return playing;
  }

  static String _chapterTitle(Chapter chapter, int index) =>
      chapter.title?.isNotEmpty == true
      ? chapter.title!
      : chapterLabel(chapter, index);

  /// Opens the page of a book from the series or the suggestions.
  void openBook(SeriesEntry entry) {
    final book =
        relatedBooks.firstWhereOrNull((b) => b.id == entry.id) ??
        home_model.Audiobook(
          id: entry.id,
          title: entry.title,
          author: entry.subtitle,
          coverUrl: entry.coverUrl,
        );
    Get.to<void>(
      () => AudiobookDetailScreen(book: book),
      preventDuplicates: false,
    );
  }

  /// Starts another book (the sequel, usually) from its first chapter.
  static Future<void> listenToBook(SeriesEntry entry) async {
    final next = Get.isRegistered<AudioBookDetailsController>(tag: entry.id)
        ? Get.find<AudioBookDetailsController>(tag: entry.id)
        : Get.put(AudioBookDetailsController(), tag: entry.id);
    await next.loadDetails(entry.id);
    await next.ensureLoaded(entry.id);
    final first = next.firstChapter;
    if (first != null) await next.playChapter(first);
  }

  /// The chapter `Listen Now` should start from — first chapter in the list.
  Chapter? get firstChapter {
    final chapters = details.value?.chapters;
    return (chapters != null && chapters.isNotEmpty) ? chapters.first : null;
  }

  /// Fetches the stream URL for [chapter] and starts playback via the app's
  /// shared [PlayerController], then opens the full-screen player unless
  /// [openPlayer] is false (the player moving on to the next chapter).
  ///
  /// The book's chapters become the player's queue, so next/previous and the
  /// end of a chapter move through the book.
  Future<void> playChapter(Chapter chapter, {bool openPlayer = true}) async {
    if (isStreamLoading.value) return;

    final audiobookId = details.value?.book?.id ?? _loadedAudiobookId ?? '';
    final chapterId = chapter.id ?? '';
    if (audiobookId.isEmpty || chapterId.isEmpty) {
      errorMessage.value = 'This chapter is unavailable right now.';
      return;
    }

    isStreamLoading.value = true;
    errorMessage.value = '';

    // A downloaded chapter plays from the device, with or without internet.
    final saved = await AudiobookDownloadController.instance.playablePath(
      chapterId,
    );
    final Request<String> result = saved != null
        ? Right(saved)
        : (await _audioBookInterface().audiobookStreamUrl(
            audiobookId,
            chapterId,
          )).map((success) => success.data?.streamUrl ?? '');

    result.fold((failure) => errorMessage.value = failure.uiMessage, (
      streamUrl,
    ) {
      if (streamUrl.isEmpty) {
        errorMessage.value = 'Stream URL is unavailable right now.';
        return;
      }

      final book = details.value?.book;
      final chapters = details.value?.chapters ?? const <Chapter>[];
      final player = _playerController();
      // Before play(), so it sees the chapter as part of the queue and of
      // the book.
      player.setQueue(
        [for (final c in chapters) c.id ?? ''],
        current: chapterId,
        start: (id) async {
          final next = chapters.firstWhereOrNull((c) => c.id == id);
          if (next != null) await playChapter(next, openPlayer: false);
        },
      );
      attachNowPlaying(_playing ??= _nowPlaying());

      player.play(
        title: _chapterTitle(chapter, chapters.indexOf(chapter)),
        artist: book?.author ?? '',
        imageAsset: book?.coverUrl ?? '',
        audioAsset: streamUrl,
        trackId: chapterId,
      );

      // The like belongs to the book, not the chapter — the player screen
      // reads it off this controller.
      AudiobookLikeController.instance.load(
        audiobookId: audiobookId,
        isLiked: isLiked.value,
      );

      if (!openPlayer) return;
      Get.to(
        () => const PlayerScreen(),
        transition: Transition.downToUp,
        preventDuplicates: true,
      );
    });

    isStreamLoading.value = false;
  }
}
