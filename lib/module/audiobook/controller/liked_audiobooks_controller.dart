import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/base/paged_list.dart';
import 'package:get/get.dart';

import '../model/audiobook_model.dart';
import '../services/audio_book_interface.dart';
import '../services/audio_book_interface_impl.dart';
import 'audio_book_details_controller.dart';
import 'audiobook_like_controller.dart';

/// The audiobooks the signed-in user has liked, behind `GET /audiobooks/liked`.
///
/// Shared rather than screen-scoped so the audiobook screen's button can show
/// the count without the liked screen being open, and so anything that needs
/// to know whether a book is liked can ask [isLiked] instead of fetching.
class LikedAudiobooksController extends GetxController {
  /// The shared instance, registered on first use.
  static LikedAudiobooksController get instance {
    if (!Get.isRegistered<LikedAudiobooksController>()) {
      Get.put(LikedAudiobooksController(), permanent: true);
    }
    return Get.find<LikedAudiobooksController>();
  }

  /// Loaded a page at a time as the liked screen scrolls, so a long list
  /// is never fetched (or laid out) all at once.
  late final _pages = PagedList<Audiobook>(
    fetch: (page, limit) =>
        _audioBookInterface().likedAudiobooksPage(page: page, limit: limit),
    idOf: (item) => item.id,
  );

  /// The pages loaded so far.
  RxList<Audiobook> get books => _pages.items;
  RxBool get isLoading => _pages.isLoading;
  RxString get errorMessage => _pages.errorMessage;

  /// False until a fetch has come back, so the count can be held back rather
  /// than shown as a zero that only means "not asked yet".
  RxBool get hasLoaded => _pages.hasLoaded;

  /// How many are liked in all — more than [books] until every
  /// page has loaded.
  RxInt get total => _pages.total;
  RxBool get isLoadingMore => _pages.isLoadingMore;
  bool get hasMore => _pages.hasMore;

  /// Appends the next page; called as the liked screen nears its end.
  Future<void> loadMore() => _pages.loadMore();

  /// Books with an unlike in flight, kept out of the way of a second tap.
  final unliking = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  AudioBookInterface _audioBookInterface() {
    if (!Get.isRegistered<AudioBookInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<AudioBookInterface>(
        AudioBookInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<AudioBookInterface>();
  }

  /// Whether [audiobookId] is on the fetched list. Reactive, so an `Obx`
  /// around it repaints when a like lands anywhere in the app.
  bool isLiked(String audiobookId) =>
      books.any((book) => book.id == audiobookId);

  Future<void>? _inFlight;

  /// Reloads the list.
  ///
  /// A second caller joins the fetch already running rather than returning to
  /// an empty list — the detail screen asks for the likes at the same moment
  /// this controller's own first fetch is still in flight.
  Future<void> fetch() =>
      _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<void> _fetch() => _pages.refresh();

  /// Removes [book] from the user's likes and drops it from the list.
  Future<void> unlike(Audiobook book) async {
    if (unliking.contains(book.id)) return;

    unliking.add(book.id);
    errorMessage.value = '';

    final result = await _audioBookInterface().likeAudiobook(book.id);

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      // The endpoint toggles, so a `liked: true` answer means the book was
      // not liked to begin with and is now — leave it on the list.
      if (success.data?.liked == true) return;

      _pages.remove((item) => item.id == book.id);
      syncHearts(book.id, false);
    });

    unliking.remove(book.id);
  }

  /// Points every heart for [audiobookId] at [liked] — the player screen's
  /// when that book is playing, and the detail screen's when it is open.
  ///
  /// Called by whichever controller landed the toggle, so a like made on one
  /// screen is not left stale on another.
  static void syncHearts(String audiobookId, bool liked) {
    if (Get.isRegistered<AudiobookLikeController>()) {
      final playing = AudiobookLikeController.instance;
      if (playing.audiobookId.value == audiobookId) {
        playing.isLiked.value = liked;
      }
    }

    if (Get.isRegistered<AudioBookDetailsController>(tag: audiobookId)) {
      Get.find<AudioBookDetailsController>(tag: audiobookId).isLiked.value =
          liked;
    }
  }
}
