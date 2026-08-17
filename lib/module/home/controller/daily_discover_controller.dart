import 'dart:math';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/listem_miusic_detalis_model.dart';
import '../services/linter_interface_impl.dart';
import '../services/listen_interface.dart';
import 'home_controller.dart';
import 'liked_songs_controller.dart';
import 'song_like_controller.dart';

/// The day's picks for the user, behind `GET /songs/daily-discovery`.
///
/// The endpoint answers with one unpaged list, so the whole selection arrives
/// in a single call and there is nothing to page through here.
class DailyDiscoverController extends GetxController {
  /// The shared instance, registered on first use.
  static DailyDiscoverController get instance {
    if (!Get.isRegistered<DailyDiscoverController>()) {
      Get.put(DailyDiscoverController(), permanent: true);
    }
    return Get.find<DailyDiscoverController>();
  }

  /// How many picks to ask for — the backend's own default.
  static const limit = 20;

  final songs = <ListenMusicDetailsModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// False until a fetch has come back, so the count can be held back rather
  /// than shown as a zero that only means "not asked yet".
  final hasLoaded = false.obs;

  /// Liked songs, tracked here rather than on the entries themselves: the
  /// payload's `isLiked` seeds it and a tap on a heart moves it, without the
  /// list having to be fetched again.
  final likedIds = <String>{}.obs;

  /// Songs with a like toggle in flight, kept out of the way of a second tap.
  final togglingLikes = <String>{}.obs;

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

  Future<void>? _inFlight;

  /// Reloads the picks.
  ///
  /// A second caller joins the fetch already running rather than being turned
  /// away — the screen asks on open at the same moment this controller's own
  /// first fetch is still in flight, and a dropped call would leave the screen
  /// waiting on a future that never ran.
  Future<void> fetch() =>
      _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<void> _fetch() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _listenInterface().dailyDiscover(limit: limit);

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      final picks = success.data ?? const <ListenMusicDetailsModel>[];

      songs.assignAll(picks);
      likedIds
        ..clear()
        ..addAll(picks.where((song) => song.isLiked).map((song) => song.id));
    });

    hasLoaded.value = true;
    isLoading.value = false;
  }

  /// Plays [song] and opens the player, through the same path the home screen
  /// uses.
  Future<void> play(ListenMusicDetailsModel song) =>
      _homeController().playSong(song.id);

  /// Plays a pick at random. The player holds one track at a time, so this
  /// shuffles the pick rather than queueing the whole list.
  Future<void> shuffle() async {
    if (songs.isEmpty) return;
    await play(songs[Random().nextInt(songs.length)]);
  }

  /// Likes the song, or unlikes it when it is already liked — the endpoint
  /// toggles, so both directions are the same call.
  Future<void> toggleLike(ListenMusicDetailsModel song) async {
    final id = song.id;
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
}
