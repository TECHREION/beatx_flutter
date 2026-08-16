import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../app/app_manager.dart';
import '../../../core/helpers/auth_role.dart';
import '../model/recently_played_model.dart';
import '../services/linter_interface_impl.dart';
import '../services/listen_interface.dart';
import 'home_controller.dart';
import 'liked_songs_controller.dart';
import 'song_like_controller.dart';

/// The user's listening history, behind `GET /songs/recently-played`.
///
/// The backend pages the history, so the list holds what has been fetched so
/// far and [loadMore] asks for the next page as the screen is scrolled.
class RecentlyPlayedController extends GetxController {
  /// The shared instance, registered on first use.
  static RecentlyPlayedController get instance {
    if (!Get.isRegistered<RecentlyPlayedController>()) {
      Get.put(RecentlyPlayedController(), permanent: true);
    }
    return Get.find<RecentlyPlayedController>();
  }

  /// Entries per request — the backend's own default.
  static const pageSize = 20;

  final entries = <RecentlyPlayedModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;

  /// False until a fetch has come back, so the count can be held back rather
  /// than shown as a zero that only means "not asked yet".
  final hasLoaded = false.obs;

  /// How many entries the backend holds, which is what says whether there is
  /// another page to ask for.
  final total = 0.obs;

  /// Liked songs, tracked here rather than on the entries themselves: the
  /// payload's `isLiked` seeds it and a tap on a heart moves it, without the
  /// whole list having to be rebuilt from the API.
  final likedIds = <String>{}.obs;

  /// Songs with a like toggle in flight, kept out of the way of a second tap.
  final togglingLikes = <String>{}.obs;

  int _page = 1;

  /// Whether the backend holds entries past the ones already fetched.
  bool get hasMore => entries.length < total.value;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  ListenInterface _listenInterface() {
    if (!Get.isRegistered<ListenInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<ListenInterface>(
        ListenInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ListenInterface>();
  }

  HomeController _homeController() {
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
    return Get.find<HomeController>();
  }

  /// The signed-in user's id. The endpoint reads the history off the bearer
  /// token, so an empty id — which is what a session saved without one leaves
  /// behind — still fetches the right history.
  String get _userId {
    if (!Get.isRegistered<AppManager>()) return '';

    final status = Get.find<AppManager>().currentAuthStatus;
    return status is Authenticated ? status.auth.userId : '';
  }

  /// Reloads the history from the first page, replacing what is on screen.
  Future<void> fetch() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = '';

    final result = await _listenInterface().recentlyPlayed(
      _userId,
      page: 1,
      limit: pageSize,
    );

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      final page = success.data ?? const RecentlyPlayedPage();

      _page = 1;
      total.value = page.total;
      entries.assignAll(page.items);
      likedIds
        ..clear()
        ..addAll(
          page.items.where((e) => e.song.isLiked).map((e) => e.song.id),
        );
    });

    hasLoaded.value = true;
    isLoading.value = false;
  }

  /// Appends the next page. Does nothing once everything has been fetched.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;

    isLoadingMore.value = true;

    final result = await _listenInterface().recentlyPlayed(
      _userId,
      page: _page + 1,
      limit: pageSize,
    );

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      final page = success.data ?? const RecentlyPlayedPage();

      _page += 1;
      total.value = page.total;

      // Playing a song while paging shifts the history, so the same entry can
      // come back on two pages — keep the one already on screen.
      final seen = entries.map((entry) => entry.song.id).toSet();
      final fresh = page.items.where((entry) => !seen.contains(entry.song.id));

      entries.addAll(fresh);
      likedIds.addAll(
        fresh.where((e) => e.song.isLiked).map((e) => e.song.id),
      );
    });

    isLoadingMore.value = false;
  }

  /// Plays [entry] and opens the player, through the same path the home
  /// screen uses.
  Future<void> play(RecentlyPlayedModel entry) =>
      _homeController().playSong(entry.song.id);

  /// Likes the song, or unlikes it when it is already liked — the endpoint
  /// toggles, so both directions are the same call.
  Future<void> toggleLike(RecentlyPlayedModel entry) async {
    final id = entry.song.id;
    if (id.isEmpty || togglingLikes.contains(id)) return;

    togglingLikes.add(id);
    errorMessage.value = '';

    final result = await _listenInterface().likesong(id);

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      // A backend that only acknowledges the call reports no flag, so fall
      // back to flipping what is on screen.
      final liked = success.data?.liked ?? !likedIds.contains(id);

      if (liked) {
        likedIds.add(id);
      } else {
        likedIds.remove(id);
      }

      // Keep the heart on the player screen honest when the song toggled here
      // is the one playing, and the liked-songs list in step with it.
      final playing = SongLikeController.instance;
      if (playing.songId.value == id) playing.isLiked.value = liked;

      if (Get.isRegistered<LikedSongsController>()) {
        LikedSongsController.instance.fetch();
      }
    });

    togglingLikes.remove(id);
  }

  /// A short "when" for the row: `Just now`, `20m ago`, `3d ago`, or the date
  /// once the entry is older than a week.
  static String formatLastPlayed(DateTime? at) {
    if (at == null) return '';

    final elapsed = DateTime.now().difference(at.toLocal());
    if (elapsed.isNegative || elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';

    final local = at.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}
