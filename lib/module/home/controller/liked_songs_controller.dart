import 'dart:math';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/listem_miusic_detalis_model.dart';
import '../services/linter_interface_impl.dart';
import '../services/listen_interface.dart';
import 'home_controller.dart';
import 'song_like_controller.dart';

/// The songs the signed-in user has liked, behind `GET /songs/liked`.
///
/// Shared rather than screen-scoped so the home tile can show the count
/// without the liked screen being open.
class LikedSongsController extends GetxController {
  /// The shared instance, registered on first use.
  static LikedSongsController get instance {
    if (!Get.isRegistered<LikedSongsController>()) {
      Get.put(LikedSongsController(), permanent: true);
    }
    return Get.find<LikedSongsController>();
  }

  final songs = <ListenMusicDetailsModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// False until a fetch has come back, so the count can be held back rather
  /// than shown as a zero that only means "not asked yet".
  final hasLoaded = false.obs;

  /// Songs with an unlike in flight, kept out of the way of a second tap.
  final unliking = <String>{}.obs;

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

  /// Reloads the list.
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

    final result = await _listenInterface().getLikedSong();

    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) => songs.assignAll(success.data ?? const []),
    );

    hasLoaded.value = true;
    isLoading.value = false;
  }

  /// Plays [song] and opens the player, through the same path the home
  /// screen uses.
  Future<void> play(ListenMusicDetailsModel song) =>
      _homeController().playSong(song.id);

  /// Plays a song picked at random. The player holds one track at a time, so
  /// this shuffles the pick rather than queueing the whole list.
  Future<void> shuffle() async {
    if (songs.isEmpty) return;
    await play(songs[Random().nextInt(songs.length)]);
  }

  /// Removes [song] from the user's likes and drops it from the list.
  Future<void> unlike(ListenMusicDetailsModel song) async {
    if (unliking.contains(song.id)) return;

    unliking.add(song.id);
    errorMessage.value = '';

    final result = await _listenInterface().likesong(song.id);

    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) {
        // The endpoint toggles, so a `liked: true` answer means the song was
        // not liked to begin with and is now — leave it on the list.
        if (success.data?.liked == true) return;

        songs.removeWhere((item) => item.id == song.id);

        // Keep the heart on the player screen honest when the song unliked
        // here is the one playing.
        final playing = SongLikeController.instance;
        if (playing.songId.value == song.id) playing.isLiked.value = false;
      },
    );

    unliking.remove(song.id);
  }
}
